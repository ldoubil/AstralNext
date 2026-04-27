import 'dart:typed_data';
import 'package:http/http.dart' as http;

class AvatarService {
  static const int _defaultPort = 4924;

  Future<Uint8List?> fetchAvatar(String ip, {int port = _defaultPort}) async {
    try {
      final url = Uri.http('$ip:$port', '/api/avatar');
      final response = await http.get(url).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      // [AvatarService] Failed to fetch avatar from $ip:$port: $e
    }
    return null;
  }
}
