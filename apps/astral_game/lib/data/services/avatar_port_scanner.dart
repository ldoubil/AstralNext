import 'dart:io';

class AvatarPortScanner {
  static const int _minPort = 4924;
  static const int _maxPort = 4944;
  static const Duration _timeout = Duration(milliseconds: 500);

  /// 扫描并返回第一个可用的头像服务端口
  /// 返回 null 表示未找到
  Future<int?> scanPort(String ip) async {
    for (int port = _minPort; port <= _maxPort; port++) {
      final isAvailable = await _checkPort(ip, port);
      if (isAvailable) {
        print('[AvatarPortScanner] Found avatar service at $ip:$port');
        return port;
      }
    }
    print('[AvatarPortScanner] No avatar service found at $ip');
    return null;
  }

  /// 检查指定端口是否有头像服务
  Future<bool> _checkPort(String ip, int port) async {
    try {
      final socket = await Socket.connect(ip, port, timeout: _timeout).timeout(_timeout);
      await socket.close();
      return true;
    } catch (e) {
      return false;
    }
  }
}
