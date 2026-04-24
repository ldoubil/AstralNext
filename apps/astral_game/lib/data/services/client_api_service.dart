import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

class ClientApiService {
  HttpServer? _server;
  int _port = 4924;
  Uint8List? _customAvatar;
  late SharedPreferences _prefs;

  int get port => _port;
  bool get isRunning => _server != null;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadAvatar();
  }

  Future<void> start({int port = 4924}) async {
    if (_server != null) return;

    await init();

    _port = port;
    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);

    _server!.listen((request) async {
      try {
        await _handleRequest(request);
      } catch (e) {
        print('[ClientApi] Request error: $e');
      }
    });

    print('[ClientApi] Server started on port $port');
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
    final method = request.method;
    final response = request.response;

    if (path == '/api/avatar') {
      if (method == 'GET') {
        await _handleGetAvatar(response);
      } else if (method == 'POST') {
        await _handleSetAvatar(request, response);
      } else {
        response.statusCode = HttpStatus.methodNotAllowed;
        await response.close();
      }
    } else {
      response.statusCode = HttpStatus.notFound;
      await response.close();
    }
  }

  Future<void> _handleGetAvatar(HttpResponse response) async {
    response.statusCode = HttpStatus.ok;
    response.headers.contentType = ContentType('image', 'png');
    
    if (_customAvatar != null) {
      response.add(_customAvatar!);
    } else {
      response.add(_generateDefaultAvatar());
    }
    
    await response.close();
  }

  Future<void> _handleSetAvatar(HttpRequest request, HttpResponse response) async {
    try {
      final bytes = await request.first;
      
      if (bytes.length > 1024 * 1024) {
        response.statusCode = HttpStatus.badRequest;
        response.write('Avatar too large (max 1MB)');
        await response.close();
        return;
      }

      _customAvatar = bytes;
      await _saveAvatar();

      response.statusCode = HttpStatus.ok;
      response.write('Avatar saved');
    } catch (e) {
      response.statusCode = HttpStatus.internalServerError;
      response.write('Failed to save avatar: $e');
    } finally {
      await response.close();
    }
  }

  void _loadAvatar() {
    final avatarBase64 = _prefs.getString('avatar');
    if (avatarBase64 != null) {
      _customAvatar = base64Decode(avatarBase64);
    }
  }

  Future<void> _saveAvatar() async {
    if (_customAvatar != null) {
      final base64 = base64Encode(_customAvatar!);
      await _prefs.setString('avatar', base64);
    }
  }

  Future<void> setAvatar(Uint8List avatarData) async {
    _customAvatar = avatarData;
    await _saveAvatar();
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
