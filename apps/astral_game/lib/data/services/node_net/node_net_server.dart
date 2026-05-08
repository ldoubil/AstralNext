import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:astral_game/utils/logger.dart';

/// 方法处理器类型（使用动态参数）
typedef MethodHandler = FutureOr<dynamic> Function(dynamic params);

class _TokenBucket {
  double tokens;
  DateTime lastRefill;

  _TokenBucket({required this.tokens, required this.lastRefill});
}

/// JSON-RPC 异常
class RpcException implements Exception {
  final int code;
  final String message;
  final dynamic data;

  RpcException(this.code, this.message, {this.data});

  @override
  String toString() => 'RpcException($code): $message';
}

/// 节点网服务端
///
/// 提供 JSON-RPC 2.0 服务，监听其他节点的请求
class NodeNetServer {
  HttpServer? _httpServer;
  final Map<String, MethodHandler> _methods = {};
  final List<void Function(String method, dynamic params)> _notificationListeners = [];

  /// JSON-RPC 日志开关：`true` 会输出每次请求的概览（可能较频繁）
  static const bool _rpcAccessLog = true;

  /// 会话鉴权 token（为空表示不校验）
  String? _authToken;

  /// 最大请求体大小（字节）
  static const int maxBodyBytes = 1024 * 1024; // 1MB

  /// 简单限流：每个 IP 每秒允许的请求数（突发容量为 2 倍）
  static const double _rateLimitPerSecond = 30;
  static const double _rateLimitBurst = 60;
  final Map<String, _TokenBucket> _bucketsByIp = {};

  /// 获取监听端口
  int get port => _httpServer?.port ?? 0;

  /// 是否正在运行
  bool get isRunning => _httpServer != null;

  /// 设置/清除鉴权 token（建议在连接建立/断开时调用）
  void setAuthToken(String? token) {
    final trimmed = token?.trim();
    _authToken = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  /// 注册方法
  void register(String method, MethodHandler handler) {
    _methods[method] = handler;
    appLogger.i('[NodeNetServer] 注册方法: $method');
  }

  /// 批量注册方法
  void registerAll(Map<String, MethodHandler> methods) {
    _methods.addAll(methods);
    appLogger.i('[NodeNetServer] 批量注册 ${methods.length} 个方法');
  }

  /// 启动服务
  Future<void> start() async {
    if (_httpServer != null) {
      appLogger.w('[NodeNetServer] 服务已在运行');
      return;
    }

    try {
      _httpServer = await HttpServer.bind(InternetAddress.anyIPv4, 0);
      appLogger.i('[NodeNetServer] 服务已启动，端口: ${_httpServer!.port}');

      _httpServer!.listen(_handleRequest);
    } catch (e, stackTrace) {
      appLogger.e('[NodeNetServer] 启动失败: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 停止服务
  Future<void> stop() async {
    if (_httpServer == null) return;

    await _httpServer!.close();
    _httpServer = null;
    appLogger.i('[NodeNetServer] 服务已停止');
  }

  /// 处理 HTTP 请求
  Future<void> _handleRequest(HttpRequest request) async {
    final sw = Stopwatch()..start();
    try {
      if (request.method.toUpperCase() != 'POST') {
        request.response.statusCode = HttpStatus.methodNotAllowed;
        return;
      }

      if (request.uri.path != '/rpc') {
        request.response.statusCode = HttpStatus.notFound;
        return;
      }

      final contentType = request.headers.contentType;
      final mime = contentType?.mimeType.toLowerCase();
      if (mime != 'application/json') {
        request.response.statusCode = HttpStatus.unsupportedMediaType;
        if (_rpcAccessLog) {
          final remoteIp = request.connectionInfo?.remoteAddress.address ?? 'unknown';
          appLogger.w(
            '[NodeNetServer] 非 JSON 请求被拒绝: $remoteIp ${request.method} ${request.uri} mime=${mime ?? "null"}',
          );
        }
        return;
      }

      final remoteIp = request.connectionInfo?.remoteAddress.address ?? 'unknown';
      if (!_allowRequest(remoteIp)) {
        request.response.statusCode = HttpStatus.tooManyRequests;
        if (_rpcAccessLog) {
          appLogger.w('[NodeNetServer] 限流: ip=$remoteIp');
        }
        _sendResponse(
          request,
          _buildError(-32029, 'Rate limit exceeded', {'ip': remoteIp}, null),
        );
        return;
      }

      final expectedToken = _authToken;
      if (expectedToken != null) {
        final got = request.headers.value('x-astral-token')?.trim();
        if (got == null || got.isEmpty || got != expectedToken) {
          request.response.statusCode = HttpStatus.unauthorized;
          if (_rpcAccessLog) {
            appLogger.w('[NodeNetServer] 鉴权失败: ip=$remoteIp');
          }
          _sendResponse(
            request,
            _buildError(-32001, 'Unauthorized', null, null),
          );
          return;
        }
      }

      String body;
      try {
        body = await _readBodyWithLimit(request, maxBodyBytes);
      } on RpcException catch (e) {
        if (_rpcAccessLog) {
          appLogger.w(
            '[NodeNetServer] 请求体读取失败: ip=$remoteIp code=${e.code} msg=${e.message}',
          );
        }
        _sendResponse(request, _buildError(e.code, e.message, e.data, null));
        return;
      }

      dynamic json;
      try {
        json = jsonDecode(body);
      } catch (e) {
        if (_rpcAccessLog) {
          appLogger.w('[NodeNetServer] JSON 解析失败: ip=$remoteIp err=$e');
        }
        _sendResponse(request, _buildError(-32700, 'Parse error', null));
        return;
      }

      request.response.headers.contentType = ContentType.json;

      if (json is List) {
        if (_rpcAccessLog) {
          appLogger.d('[NodeNetServer] batch 请求: ip=$remoteIp count=${json.length}');
        }
        final results = await Future.wait(json.map((r) async {
          if (r is! Map) {
            return _buildError(-32600, 'Invalid Request', null, null);
          }
          return _processRequest(Map<String, dynamic>.from(r));
        }));
        final responses = results.where((r) => r != null).toList();
        if (responses.isNotEmpty) {
          request.response.write(jsonEncode(responses));
        } else {
          request.response.statusCode = HttpStatus.noContent;
        }
      } else if (json is Map) {
        final response = await _processRequest(Map<String, dynamic>.from(json));
        if (response != null) {
          request.response.write(jsonEncode(response));
        } else {
          request.response.statusCode = HttpStatus.noContent;
        }
      } else {
        _sendResponse(request, _buildError(-32600, 'Invalid Request', null));
      }
    } catch (e, stackTrace) {
      appLogger.e('[NodeNetServer] 处理请求失败: $e', error: e, stackTrace: stackTrace);
      _sendResponse(request, _buildError(-32603, 'Internal error', e.toString()));
    } finally {
      if (_rpcAccessLog) {
        final remoteIp = request.connectionInfo?.remoteAddress.address ?? 'unknown';
        appLogger.d(
          '[NodeNetServer] done ip=$remoteIp status=${request.response.statusCode} costMs=${sw.elapsedMilliseconds}',
        );
      }
      await request.response.close();
    }
  }

  bool _allowRequest(String ip) {
    final now = DateTime.now();
    final bucket = _bucketsByIp[ip] ?? _TokenBucket(tokens: _rateLimitBurst, lastRefill: now);

    final elapsedMs = now.difference(bucket.lastRefill).inMilliseconds;
    if (elapsedMs > 0) {
      final refill = (elapsedMs / 1000.0) * _rateLimitPerSecond;
      bucket.tokens = (bucket.tokens + refill).clamp(0, _rateLimitBurst);
      bucket.lastRefill = now;
    }

    if (bucket.tokens < 1) {
      _bucketsByIp[ip] = bucket;
      return false;
    }

    bucket.tokens -= 1;
    _bucketsByIp[ip] = bucket;
    return true;
  }

  Future<String> _readBodyWithLimit(HttpRequest request, int maxBytes) async {
    final contentLength = request.contentLength;
    if (contentLength > maxBytes) {
      request.response.statusCode = HttpStatus.requestEntityTooLarge;
      throw RpcException(-32020, 'Request body too large', data: {'maxBytes': maxBytes});
    }

    final bytes = <int>[];
    await for (final chunk in request) {
      bytes.addAll(chunk);
      if (bytes.length > maxBytes) {
        request.response.statusCode = HttpStatus.requestEntityTooLarge;
        throw RpcException(-32020, 'Request body too large', data: {'maxBytes': maxBytes});
      }
    }
    return utf8.decode(bytes);
  }

  /// 处理单个 JSON-RPC 请求
  Future<Map<String, dynamic>?> _processRequest(Map<String, dynamic> json) async {
    final sw = Stopwatch()..start();
    final id = json['id'];
    final method = json['method'] as String?;
    final params = json['params'];

    if (method == null) {
      if (_rpcAccessLog) {
        appLogger.w('[NodeNetServer] invalid request: missing method');
      }
      return _buildError(-32600, 'Invalid Request', null, id);
    }

    if (json['jsonrpc'] != '2.0') {
      if (_rpcAccessLog) {
        appLogger.w('[NodeNetServer] invalid request: bad jsonrpc version method=$method');
      }
      return _buildError(-32600, 'Invalid jsonrpc version', null, id);
    }

    final handler = _methods[method];
    if (handler == null) {
      if (_rpcAccessLog) {
        appLogger.w('[NodeNetServer] method not found: $method');
      }
      return _buildError(-32601, 'Method not found', method, id);
    }

    try {
      if (_rpcAccessLog) {
        appLogger.d(
          '[NodeNetServer] <- ${id == null ? "notify" : "call"} method=$method',
        );
      }
      final result = await handler(params);

      if (id == null) {
        for (final listener in _notificationListeners) {
          listener(method, params);
        }
        if (_rpcAccessLog) {
          appLogger.d('[NodeNetServer] -> notify ok method=$method costMs=${sw.elapsedMilliseconds}');
        }
        return null;
      }

      if (_rpcAccessLog) {
        appLogger.d('[NodeNetServer] -> ok method=$method costMs=${sw.elapsedMilliseconds}');
      }
      return {
        'jsonrpc': '2.0',
        'result': result,
        'id': id,
      };
    } catch (e, stackTrace) {
      appLogger.e('[NodeNetServer] 方法执行失败: $method, 错误: $e', error: e, stackTrace: stackTrace);
      if (e is RpcException) {
        return _buildError(e.code, e.message, e.data, id);
      }
      return _buildError(-32603, 'Internal error', e.toString(), id);
    }
  }

  /// 构建错误响应
  Map<String, dynamic> _buildError(int code, String message, dynamic data, [dynamic id]) {
    final error = <String, dynamic>{
      'code': code,
      'message': message,
    };
    if (data != null) {
      error['data'] = data;
    }
    return {
      'jsonrpc': '2.0',
      'error': error,
      'id': id,
    };
  }

  /// 发送响应
  void _sendResponse(HttpRequest request, Map<String, dynamic> response) {
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode(response));
  }
}
