import 'dart:convert';
import 'dart:typed_data';

import 'package:astral_game/config/constants.dart';
import 'package:astral_game/utils/logger.dart';
import 'package:http/http.dart' as http;
import 'package:pointycastle/export.dart';

/// 公共服务器信息（从远程获取，包含加密 URL）
class PublicServer {
  final String name;
  final String encryptedUrl;
  final String? decryptedUrl;

  PublicServer({
    required this.name,
    required this.encryptedUrl,
    this.decryptedUrl,
  });
}

/// 公共服务器服务
///
/// 从远程获取公共服务器列表，URL 使用 RSA 加密
/// 存储时保留加密 URL，仅在使用时解密
class PublicServerService {
  static const _requestTimeout = Duration(seconds: 10);

  /// 获取公共服务器列表
  Future<List<PublicServer>> fetchServers() async {
    try {
      final response = await http
          .get(Uri.parse(AppConstants.publicServerListUrl))
          .timeout(_requestTimeout);

      if (response.statusCode != 200) {
        appLogger.e('[PublicServerService] 获取公共服务器列表失败: HTTP ${response.statusCode}');
        return [];
      }

      final decoded = json.decode(response.body);
      if (decoded is! List) {
        appLogger.e('[PublicServerService] 公共服务器列表格式错误');
        return [];
      }

      final privateKey = _parsePrivateKey(AppConstants.rsaPrivateKey);
      if (privateKey == null) {
        appLogger.e('[PublicServerService] RSA 私钥解析失败');
        return [];
      }

      final servers = <PublicServer>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final encryptedUrl = item['url'] as String?;
        final name = item['name'] as String?;
        if (encryptedUrl == null || name == null) continue;

        final decryptedUrl = _decryptUrl(encryptedUrl, privateKey);
        servers.add(PublicServer(
          name: name,
          encryptedUrl: encryptedUrl,
          decryptedUrl: decryptedUrl,
        ));
      }

      appLogger.i('[PublicServerService] 获取到 ${servers.length} 个公共服务器');
      return servers;
    } catch (e) {
      appLogger.e('[PublicServerService] 获取公共服务器列表异常: $e');
      return [];
    }
  }

  /// 解密 URL（供外部调用）
  String? decryptUrl(String encryptedBase64) {
    final privateKey = _parsePrivateKey(AppConstants.rsaPrivateKey);
    if (privateKey == null) return null;
    return _decryptUrl(encryptedBase64, privateKey);
  }

  /// 解析 RSA 私钥（PKCS#8 DER 格式）
  RSAPrivateKey? _parsePrivateKey(String base64Key) {
    try {
      final keyBytes = Uint8List.fromList(base64.decode(base64Key));
      final seq = _parseASN1Sequence(keyBytes);
      if (seq.length < 3) return null;

      final privateKeyOctet = seq[2] as Uint8List;
      final pkcs1Key = _parseASN1Sequence(privateKeyOctet);

      if (pkcs1Key.length < 9) return null;

      return RSAPrivateKey(
        pkcs1Key[1] as BigInt,
        pkcs1Key[2] as BigInt,
        pkcs1Key[3] as BigInt,
        pkcs1Key[4] as BigInt,
      );
    } catch (e) {
      appLogger.e('[PublicServerService] 解析 RSA 私钥失败: $e');
      return null;
    }
  }

  /// 简易 ASN.1 DER 解析
  List<dynamic> _parseASN1Sequence(Uint8List bytes) {
    final results = <dynamic>[];
    int offset = 0;

    while (offset < bytes.length) {
      final tag = bytes[offset++];
      final lengthByte = bytes[offset++];

      int length;
      if (lengthByte < 0x80) {
        length = lengthByte;
      } else if (lengthByte == 0x81) {
        length = bytes[offset++];
      } else if (lengthByte == 0x82) {
        length = (bytes[offset] << 8) | bytes[offset + 1];
        offset += 2;
      } else {
        break;
      }

      if (offset + length > bytes.length) break;

      final value = bytes.sublist(offset, offset + length);
      offset += length;

      if (tag == 0x30 || tag == 0x31) {
        results.add(_parseASN1Sequence(value));
      } else if (tag == 0x02) {
        BigInt bigInt = BigInt.zero;
        for (final byte in value) {
          bigInt = (bigInt << 8) | BigInt.from(byte);
        }
        if (value.isNotEmpty && value[0] & 0x80 != 0) {
          final bitLength = value.length * 8;
          bigInt = bigInt - (BigInt.one << bitLength);
        }
        results.add(bigInt);
      } else {
        results.add(value);
      }
    }

    return results;
  }

  /// 使用 RSA 私钥解密 URL（PKCS1 v1.5 padding）
  String? _decryptUrl(String encryptedBase64, RSAPrivateKey privateKey) {
    try {
      final encryptedBytes = Uint8List.fromList(base64.decode(encryptedBase64));

      final modulus = privateKey.n!;
      final privateExponent = privateKey.d!;

      BigInt cipherInt = BigInt.zero;
      for (final byte in encryptedBytes) {
        cipherInt = (cipherInt << 8) | BigInt.from(byte);
      }

      final plainInt = cipherInt.modPow(privateExponent, modulus);

      final byteLen = (modulus.bitLength + 7) ~/ 8;
      final plainBytes = _bigIntToBytes(plainInt, byteLen);

      if (plainBytes.length < 11 || plainBytes[0] != 0 || plainBytes[1] != 2) {
        return null;
      }

      int dataStart = -1;
      for (int i = 2; i < plainBytes.length; i++) {
        if (plainBytes[i] == 0) {
          dataStart = i + 1;
          break;
        }
      }

      if (dataStart == -1 || dataStart >= plainBytes.length) return null;

      final data = plainBytes.sublist(dataStart);
      return utf8.decode(data);
    } catch (e) {
      appLogger.e('[PublicServerService] RSA 解密失败: $e');
      return null;
    }
  }

  Uint8List _bigIntToBytes(BigInt number, int byteLength) {
    final bytes = Uint8List(byteLength);
    var temp = number;
    for (int i = byteLength - 1; i >= 0; i--) {
      bytes[i] = (temp & BigInt.from(0xFF)).toInt();
      temp = temp >> 8;
    }
    return bytes;
  }
}
