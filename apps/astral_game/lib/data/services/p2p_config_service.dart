import 'dart:math';

import 'package:get_it/get_it.dart';
import 'package:astral_game/data/services/app_settings_service.dart';
import 'package:astral_game/data/services/node_net/node_net_server.dart';
import 'package:astral_game/data/state/server_state.dart';

class P2PConfigService {
  final AppSettingsService _appSettings;
  final ServerState _serverState;

  P2PConfigService(this._appSettings, this._serverState);

  /// 生成 UUID v4
  String generateUuid() {
    final random = Random();
    final values = List<int>.generate(16, (_) => random.nextInt(256));
    values[6] = (values[6] & 0x0F) | 0x40;
    values[8] = (values[8] & 0x3F) | 0x80;
    
    const hex = '0123456789abcdef';
    final buffer = StringBuffer();
    for (int i = 0; i < 16; i++) {
      if (i == 4 || i == 6 || i == 8 || i == 10) {
        buffer.write('-');
      }
      buffer.write(hex[values[i] >> 4]);
      buffer.write(hex[values[i] & 0x0F]);
    }
    return buffer.toString();
  }

  /// 构建 TOML 配置文件
  String buildTomlConfig(String roomName, String roomPassword) {
    final disableP2p = _appSettings.isDisableP2p();
    final enabledServers = _serverState.getEnabledServers();
    
    final nodeNetServer = GetIt.I<NodeNetServer>();
    final apiPort = nodeNetServer.port;
    
    String peerBlock = '';
    if (enabledServers.isNotEmpty) {
      peerBlock = enabledServers.map((server) {
        final protocol = server.udp ? 'udp' : server.tcp ? 'tcp' : 'tcp';
        return '[[peer]]\nuri = "${_escapeString("$protocol://${server.url}")}"';
      }).join('\n\n');
    }
    
    return '''
instance_name = "AstralGame"
hostname = "$apiPort"
dhcp = true
listeners = [
    "tcp://0.0.0.0:11010",
    "udp://0.0.0.0:11010",
] 

[network_identity]
network_name = "${_escapeString(roomName)}" 
network_secret = "${_escapeString(roomPassword)}" 

${peerBlock.isNotEmpty ? '$peerBlock\n\n' : ''}[flags]
disable-p2p = $disableP2p
''';
  }

  /// 转义字符串中的特殊字符
  String _escapeString(String s) => s.replaceAll('\\', r'\\').replaceAll('"', r'\"');
}
