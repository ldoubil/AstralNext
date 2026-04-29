import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// 方法处理器类型（使用动态参数）
typedef MethodHandler = FutureOr<dynamic> Function(dynamic params);

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

  /// 获取监听端口
  int get port => _httpServer?.port ?? 0;

  /// 是否正在运行
  bool get isRunning => _httpServer != null;

  /// 注册方法
  void register(String method, MethodHandler handler) {
    _methods[method] = handler;
    debugPrint('[NodeNetServer] 注册方法: $method');
  }

  /// 批量注册方法
  void registerAll(Map<String, MethodHandler> methods) {
    _methods.addAll(methods);
    debugPrint('[NodeNetServer] 批量注册 ${methods.length} 个方法');
  }

  /// 监听通知
  void onNotification(void Function(String method, dynamic params) listener) {
    _notificationListeners.add(listener);
  }

  /// 移除通知监听
  void removeNotification(void Function(String method, dynamic params) listener) {
    _notificationListeners.remove(listener);
  }

  /// 启动服务
  Future<void> start() async {
    if (_httpServer != null) {
      debugPrint('[NodeNetServer] 服务已在运行');
      return;
    }

    try {
      _httpServer = await HttpServer.bind(InternetAddress.anyIPv4, 0);
      debugPrint('[NodeNetServer] 服务已启动，端口: ${_httpServer!.port}');

      _httpServer!.listen(_handleRequest);
    } catch (e, stackTrace) {
      debugPrint('[NodeNetServer] 启动失败: $e\n$stackTrace');
      rethrow;
    }
  }

  /// 停止服务
  Future<void> stop() async {
    if (_httpServer == null) return;

    await _httpServer!.close();
    _httpServer = null;
    debugPrint('[NodeNetServer] 服务已停止');
  }

  /// 处理 HTTP 请求
  Future<void> _handleRequest(HttpRequest request) async {
    try {
      final body = await utf8.decoder.bind(request).join();

      dynamic json;
      try {
        json = jsonDecode(body);
      } catch (e) {
        _sendResponse(request, _buildError(-32700, 'Parse error', null));
        return;
      }

      request.response.headers.contentType = ContentType.json;

      if (json is List) {
        final results = await Future.wait(
          json.map((r) => _processRequest(r as Map<String, dynamic>)),
        );
        final responses = results.where((r) => r != null).toList();
        if (responses.isNotEmpty) {
          request.response.write(jsonEncode(responses));
        } else {
          request.response.statusCode = HttpStatus.noContent;
        }
      } else if (json is Map) {
        final response = await _processRequest(json as Map<String, dynamic>);
        if (response != null) {
          request.response.write(jsonEncode(response));
        } else {
          request.response.statusCode = HttpStatus.noContent;
        }
      } else {
        _sendResponse(request, _buildError(-32600, 'Invalid Request', null));
      }
    } catch (e, stackTrace) {
      debugPrint('[NodeNetServer] 处理请求失败: $e\n$stackTrace');
      _sendResponse(request, _buildError(-32603, 'Internal error', e.toString()));
    } finally {
      await request.response.close();
    }
  }

  /// 处理单个 JSON-RPC 请求
  Future<Map<String, dynamic>?> _processRequest(Map<String, dynamic> json) async {
    final id = json['id'];
    final method = json['method'] as String?;
    final params = json['params'];

    if (method == null) {
      return _buildError(-32600, 'Invalid Request', null, id);
    }

    if (json['jsonrpc'] != '2.0') {
      return _buildError(-32600, 'Invalid jsonrpc version', null, id);
    }

    final handler = _methods[method];
    if (handler == null) {
      return _buildError(-32601, 'Method not found', method, id);
    }

    try {
      final result = await handler(params);

      if (id == null) {
        for (final listener in _notificationListeners) {
          listener(method, params);
        }
        return null;
      }

      return {
        'jsonrpc': '2.0',
        'result': result,
        'id': id,
      };
    } catch (e, stackTrace) {
      debugPrint('[NodeNetServer] 方法执行失败: $method, 错误: $e\n$stackTrace');
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
