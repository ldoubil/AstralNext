import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class UserInfo {
  final String name;

  UserInfo({
    required this.name,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      name: json['name'] ?? 'Unknown',
    );
  }
}

class UserInfoService {
  static const int _defaultPort = 4924;

  Future<UserInfo?> fetchUserInfo(String ip, {int port = _defaultPort}) async {
    try {
      final url = Uri.http('$ip:$port', '/api/user');
      final response = await http.get(url).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserInfo.fromJson(data);
      }
    } catch (e) {
      debugPrint('[UserInfoService] Failed to fetch user info from $ip:$port: $e');
    }
    return null;
  }
}