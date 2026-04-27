import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:astral_game/data/services/app_settings_service.dart';

class ClientApiService {
  static const int _minPort = 4924;
  static const int _maxPort = 4944;
  
  HttpServer? _server;
  int _port = 0;
  Uint8List? _customAvatar;
  late SharedPreferences _prefs;
  late AppSettingsService _appSettings;

  int get port => _port;
  bool get isRunning => _server != null;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _appSettings = GetIt.I<AppSettingsService>();
    final avatarBase64 = _prefs.getString('avatar');
    if (avatarBase64 != null) {
      _customAvatar = base64Decode(avatarBase64);
    }
  }

  Future<void> start() async {
    if (_server != null) return;

    await init();
    
    // 在 4924-4944 范围内寻找可用端口
    _port = await _findAvailablePort();
    _server = await HttpServer.bind(InternetAddress.anyIPv4, _port);

    _server!.listen((request) async {
      try {
        await _handleRequest(request);
      } catch (e) {
        print('[ClientApi] Request error: $e');
      }
    });

    print('[ClientApi] Server started on port $_port');
  }

  /// 在指定范围内寻找可用端口
  Future<int> _findAvailablePort() async {
    for (int port = _minPort; port <= _maxPort; port++) {
      try {
        // 尝试绑定端口
        final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
        await server.close(); // 立即关闭，只是测试
        return port; // 端口可用
      } catch (e) {
        // 端口被占用，尝试下一个
        continue;
      }
    }
    
    // 如果所有端口都被占用，抛出异常
    throw Exception('No available port in range $_minPort-$_maxPort');
  }

  Future<void> stop() async {
    if (_server != null) {
      await _server!.close();
      _server = null;
      print('[ClientApi] Server stopped');
    }
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final path = request.uri.path;
    final response = request.response;

    if (path == '/api/avatar') {
      response.statusCode = HttpStatus.ok;
      response.headers.contentType = ContentType('image', 'png');
      
      if (_customAvatar != null) {
        response.add(_customAvatar!);
      } else {
        response.add(_generateDefaultAvatar());
      }
      
      await response.close();
    } else if (path == '/api/user') {
      response.statusCode = HttpStatus.ok;
      response.headers.contentType = ContentType('application', 'json', charset: 'utf-8');
      
      final username = _appSettings.getUsername();
      final responseData = json.encode({
        'name': username,
      });
      
      response.add(utf8.encode(responseData));
      await response.close();
    } else {
      response.statusCode = HttpStatus.notFound;
      await response.close();
    }
  }

  Future<void> setAvatar(Uint8List avatarData) async {
    _customAvatar = avatarData;
    final base64 = base64Encode(avatarData);
    await _prefs.setString('avatar', base64);
  }

  Uint8List getAvatar() {
    return _customAvatar ?? _generateDefaultAvatar();
  }

  Uint8List _generateDefaultAvatar() {
    return Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
      0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
      0x00, 0x00, 0x00, 0x20, 0x00, 0x00, 0x00, 0x20,
      0x08, 0x06, 0x00, 0x00, 0x00, 0x73, 0x7A, 0x7A,
      0xF4, 0x00, 0x00, 0x00, 0x01, 0x73, 0x52, 0x47,
      0x42, 0x00, 0xAE, 0xCE, 0x1C, 0xE9, 0x00, 0x00,
      0x00, 0x36, 0x49, 0x44, 0x41, 0x54, 0x38, 0x8D,
      0x63, 0x60, 0x18, 0x05, 0xA3, 0x60, 0x14, 0x8C,
      0x02, 0x08, 0x00, 0x00, 0xFF, 0xFF, 0x03, 0x00,
      0x01, 0x00, 0x01, 0x5D, 0xF6, 0xF6, 0xF6, 0xF6,
      0x10, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E,
      0x44, 0xAE, 0x42, 0x60, 0x82,
    ]);
  }
}
