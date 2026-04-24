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

