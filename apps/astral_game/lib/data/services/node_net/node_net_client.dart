import 'dart:async';
import 'dart:convert';

import 'package:astral_game/utils/logger.dart';
import 'package:http/http.dart' as http;

import 'node_net_server.dart';

/// 节点网客户端
///
/// 用于向其他节点发送 JSON-RPC 请求
class NodeNetClient {
  final http.Client _httpClient = http.Client();
  int _requestId = 0;
  String? _authToken;

  /// 默认超时时间
  static const Duration defaultTimeout = Duration(seconds: 5);

  /// 设置/清除鉴权 token（建议在连接建立/断开时调用）
  void setAuthToken(String? token) {
    final trimmed = token?.trim();
    _authToken = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  /// 调用方法（等待响应）
  ///
  /// [ip] 目标节点 IP
  /// [port] 目标节点端口
  /// [method] 方法名
  /// [params] 参数
  /// [timeout] 超时时间
  /// [authToken] 会话鉴权 token（不传则使用已设置的默认 token）
  Future<dynamic> call(
    String ip,
    int port,
    String method, {
    dynamic params,
    Duration timeout = defaultTimeout,
    String? authToken,
  }) async {
    final id = ++_requestId;
    final request = {
      'jsonrpc': '2.0',
      'method': method,
      'params': params,
      'id': id,
    };

    try {
      final token = (authToken ?? _authToken)?.trim();
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['x-astral-token'] = token;
      }

      final response = await _httpClient
          .post(
            Uri.http('$ip:$port', '/rpc'),
            headers: headers,
            body: jsonEncode(request),
          )
          .timeout(timeout);

      if (response.statusCode == 204) {
        throw RpcException(0, 'Server returned no content');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['error'] != null) {
        final error = json['error'] as Map<String, dynamic>;
        throw RpcException(
          error['code'] as int,
          error['message'] as String,
          data: error['data'],
        );
      }

      return json['result'];
    } on TimeoutException {
      throw RpcException(-32000, 'Request timeout');
    } on RpcException {
      rethrow;
    } catch (e) {
      throw RpcException(-32603, 'Internal error: $e');
    }
  }

  /// 发送通知（不等待响应）
  ///
  /// [ip] 目标节点 IP
  /// [port] 目标节点端口
  /// [method] 方法名
  /// [params] 参数
  /// [authToken] 会话鉴权 token（不传则使用已设置的默认 token）
  Future<void> notify(
    String ip,
    int port,
    String method, {
    dynamic params,
    Duration timeout = defaultTimeout,
    String? authToken,
  }) async {
    final request = {
      'jsonrpc': '2.0',
      'method': method,
      'params': params,
    };

    try {
      final token = (authToken ?? _authToken)?.trim();
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['x-astral-token'] = token;
      }

      await _httpClient
          .post(
            Uri.http('$ip:$port', '/rpc'),
            headers: headers,
            body: jsonEncode(request),
          )
          .timeout(timeout);
     } on TimeoutException {
      appLogger.w('[NodeNetClient] 通知超时: $method -> $ip:$port');
    } catch (e) {
      appLogger.e('[NodeNetClient] 发送通知失败: $method -> $ip:$port, 错误: $e');
    }
  }

  /// 释放资源
  void dispose() {
    _httpClient.close();
  }
}
