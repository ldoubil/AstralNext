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

  /// 默认超时时间
  static const Duration defaultTimeout = Duration(seconds: 5);

  /// 调用方法（等待响应）
  ///
  /// [ip] 目标节点 IP
  /// [port] 目标节点端口
  /// [method] 方法名
  /// [params] 参数
  /// [timeout] 超时时间
  Future<dynamic> call(
    String ip,
    int port,
    String method, {
    dynamic params,
    Duration timeout = defaultTimeout,
  }) async {
    final id = ++_requestId;
    final request = {
      'jsonrpc': '2.0',
      'method': method,
      'params': params,
      'id': id,
    };

    try {
      final response = await _httpClient
          .post(
            Uri.http('$ip:$port', '/rpc'),
            headers: {'Content-Type': 'application/json'},
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
  Future<void> notify(
    String ip,
    int port,
    String method, {
    dynamic params,
    Duration timeout = defaultTimeout,
  }) async {
    final request = {
      'jsonrpc': '2.0',
      'method': method,
      'params': params,
    };

    try {
      await _httpClient
          .post(
            Uri.http('$ip:$port', '/rpc'),
            headers: {'Content-Type': 'application/json'},
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
