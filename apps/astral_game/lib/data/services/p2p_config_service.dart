import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';

import 'package:get_it/get_it.dart';
import 'package:astral_game/data/services/app_settings_service.dart';
import 'package:astral_game/data/services/node_net/node_net_server.dart';
import 'package:astral_game/data/services/public_server_service.dart';
import 'package:astral_game/data/state/server_state.dart';
import 'package:astral_game/data/state/vpn_state.dart';
import 'package:astral_game/utils/logger.dart';
import 'package:pointycastle/export.dart';

class RoomShareCodeParts {
  final String serverFingerprint;
  final String token;
  final String roomName;

  const RoomShareCodeParts({
    required this.serverFingerprint,
    required this.token,
    required this.roomName,
  });
}

class P2PConfigService {
  final AppSettingsService _appSettings;
  final ServerState _serverState;
  final VpnState _vpnState;

  P2PConfigService(this._appSettings, this._serverState, this._vpnState);

  /// 生成“房间码”（更短，适合作为分享码/房间密钥）
  ///
  /// 注意：这里用 `Random.secure()`，用于“当密码用”的场景。
  String generateRoomCode({int length = 10}) {
    const alphabet = '23456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz';
    final random = Random.secure();
    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      buffer.write(alphabet[random.nextInt(alphabet.length)]);
    }
    return buffer.toString();
  }

  /// 启用服务器列表“指纹”（顺序无关）
  ///
  /// 用于：快速判断双方启用服务器是否一致（不是机密信息）。
  /// 规则：
  /// - 只取启用服务器的“完整 URI”
  /// - 去空格、做基础规范化
  /// - 排序后拼接，再计算 MD5，最后截断为短串
  String enabledServersFingerprint({int length = 8}) {
    final enabledServers = _serverState.getEnabledServers();
    final normalizedUris =
        enabledServers
            .map((server) {
              final url = server.encrypted
                  ? _decryptUrl(server.url) ?? server.url
                  : server.url;
              return _normalizeFullUri(url);
            })
            .whereType<String>()
            .where((u) => u.isNotEmpty)
            .toList()
          ..sort();

    final joined = normalizedUris.join('\n');
    final digestBytes = _md5(utf8.encode(joined));
    final hex = _toHex(digestBytes);
    if (length <= 0) return '';
    return hex.substring(0, length.clamp(1, hex.length));
  }

  /// 获取“可用于分享码”的服务器指纹
  ///
  /// - 当本地没有启用服务器，返回占位值（避免分享码结构不一致）
  String shareFingerprint({int length = 8}) {
    final fp = enabledServersFingerprint(length: length);
    if (fp.isEmpty) return '00000000'.substring(0, length.clamp(1, 8));
    return fp;
  }

  /// 构建房间分享码：`服务器哈希-token-房间名`
  ///
  /// - 兼容：历史上 `服务器哈希-token`（无房间名）与 `token`（无服务器哈希）
  String buildRoomShareCode({
    required String roomName,
    required String token,
    String? serverFingerprint,
  }) {
    final fp = (serverFingerprint == null || serverFingerprint.trim().isEmpty)
        ? shareFingerprint()
        : serverFingerprint.trim();
    final safeToken = token.trim();
    final safeRoomName = roomName.trim();
    return '$fp-$safeToken-$safeRoomName';
  }

  /// 解析房间分享码
  ///
  /// 支持：
  /// - `fp-token-roomName`
  /// - `fp-token`（旧格式）
  /// - `token`（旧格式）
  RoomShareCodeParts? parseRoomShareCode(String shareCode) {
    final trimmed = shareCode.trim();
    if (trimmed.isEmpty) return null;

    final firstDash = trimmed.indexOf('-');
    if (firstDash <= 0 || firstDash >= trimmed.length - 1) {
      // token only
      final token = trimmed;
      final prefix = token.substring(0, token.length < 6 ? token.length : 6);
      return RoomShareCodeParts(
        serverFingerprint: '00000000',
        token: token,
        roomName: 'Room_$prefix',
      );
    }

    final secondDash = trimmed.indexOf('-', firstDash + 1);
    final fp = trimmed.substring(0, firstDash);
    if (secondDash == -1) {
      // old: fp-token
      final token = trimmed.substring(firstDash + 1);
      final prefix = token.substring(0, token.length < 6 ? token.length : 6);
      return RoomShareCodeParts(
        serverFingerprint: fp,
        token: token,
        roomName: 'Room_$prefix',
      );
    }

    // new: fp-token-roomName (roomName may contain '-')
    final token = trimmed.substring(firstDash + 1, secondDash);
    final roomName = trimmed.substring(secondDash + 1).trim();
    final prefix = token.substring(0, token.length < 6 ? token.length : 6);
    return RoomShareCodeParts(
      serverFingerprint: fp,
      token: token,
      roomName: roomName.isEmpty ? 'Room_$prefix' : roomName,
    );
  }

  /// 构建 TOML 配置文件
  String buildTomlConfig(String roomName, String roomPassword) {
    final disableP2p = _appSettings.isDisableP2p();
    final enabledServers = _serverState.getEnabledServers();

    final nodeNetServer = GetIt.I<NodeNetServer>();
    final apiPort = nodeNetServer.port;

    String peerBlock = '';
    if (enabledServers.isNotEmpty) {
      peerBlock = enabledServers
          .map((server) {
            final url = server.encrypted
                ? _decryptUrl(server.url) ?? server.url
                : server.url;

            // 服务器地址现在支持“完整 URI”（例如 tcp://host:port、udp://host:port、ws://...）
            // 如果已经带 scheme，则不要再拼装协议前缀，避免出现 tcp://tcp//... 这类错误。
            final trimmed = url.trim();
            final hasScheme = RegExp(
              r'^[a-zA-Z][a-zA-Z0-9+.-]*://',
            ).hasMatch(trimmed);
            if (hasScheme) {
              return '[[peer]]\nuri = "${_escapeString(trimmed)}"';
            }
            appLogger.w('[P2PConfigService] 跳过无效服务器地址（必须是完整 URI）: $trimmed');
            return '';
          })
          .where((s) => s.isNotEmpty)
          .join('\n\n');
    }

    final proxyBlock = _vpnState.customRoutes.value
        .map((route) => route.trim())
        .where(_isValidCidrLike)
        .map((route) => '[[proxy_network]]\ncidr = "${_escapeString(route)}"')
        .join('\n\n');

    return '''
instance_name = "AstralGame_$apiPort"
hostname = "$apiPort"
dhcp = true
listeners = [
    "tcp://0.0.0.0:0",
    "udp://0.0.0.0:0",
] 

[network_identity]
network_name = "${_escapeString(roomName)}" 
network_secret = "${_escapeString(roomPassword)}" 

${peerBlock.isNotEmpty ? '$peerBlock\n\n' : ''}${proxyBlock.isNotEmpty ? '$proxyBlock\n\n' : ''}[flags]
disable-p2p = $disableP2p
''';
  }

  /// 转义字符串中的特殊字符
  String _escapeString(String s) =>
      s.replaceAll('\\', r'\\').replaceAll('"', r'\"');

  /// 解密加密的服务器 URL
  String? _decryptUrl(String encryptedUrl) {
    return PublicServerService().decryptUrl(encryptedUrl);
  }

  String? _normalizeFullUri(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final hasScheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(trimmed);
    if (!hasScheme) return null;

    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.scheme.isEmpty || uri.host.isEmpty) return null;

    final scheme = uri.scheme.toLowerCase();
    final host = uri.host.toLowerCase();
    final portPart = uri.hasPort ? ':${uri.port}' : '';
    final path = (uri.path.isEmpty || uri.path == '/') ? '' : uri.path;
    final query = uri.hasQuery ? '?${uri.query}' : '';
    final fragment = uri.hasFragment ? '#${uri.fragment}' : '';
    return '$scheme://$host$portPart$path$query$fragment';
  }

  Uint8List _md5(List<int> bytes) {
    final d = Digest('MD5');
    return d.process(Uint8List.fromList(bytes));
  }

  String _toHex(Uint8List bytes) {
    const hex = '0123456789abcdef';
    final buffer = StringBuffer();
    for (final b in bytes) {
      buffer.write(hex[b >> 4]);
      buffer.write(hex[b & 0x0F]);
    }
    return buffer.toString();
  }

  bool _isValidCidrLike(String route) {
    final parts = route.split('/');
    if (parts.length != 2) return false;
    final prefix = int.tryParse(parts[1]);
    if (prefix == null || prefix < 0 || prefix > 32) return false;
    return RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(parts[0]);
  }
}
