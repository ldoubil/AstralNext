import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:astral_game/di.dart';
import 'package:astral_game/data/services/app_settings_service.dart';
import 'package:astral_game/data/state/settings_state.dart';
import 'package:astral_game/utils/input_validator.dart';
import 'package:astral_game/utils/runtime_platform.dart';

class NetworkSettingsPage extends StatefulWidget {
  const NetworkSettingsPage({super.key});

  @override
  State<NetworkSettingsPage> createState() => _NetworkSettingsPageState();
}

class _NetworkSettingsPageState extends State<NetworkSettingsPage> {
  late TextEditingController _virtualIpController;
  late bool _isDhcp;
  bool _isValidIP = true;

  @override
  void initState() {
    super.initState();
    final appSettings = getIt<AppSettingsService>();
    _isDhcp = appSettings.getIsDhcp();
    _virtualIpController = TextEditingController(text: appSettings.getVirtualIp());
  }

  @override
  void dispose() {
    _virtualIpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final settingsState = getIt<SettingsState>();

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('网络配置'),
                  subtitle: Text('IP 地址和 P2P 设置'),
                  leading: Icon(Icons.network_check),
                ),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _virtualIpController,
                        enabled: !_isDhcp,
                        onChanged: (value) {
                          if (!_isDhcp) {
                            setState(() {
                              _isValidIP = InputValidator.validateIPv4(value) == null;
                            });
                            if (_isValidIP) {
                              getIt<AppSettingsService>().setVirtualIp(value);
                            }
                          }
                        },
                        decoration: InputDecoration(
                          labelText: '虚拟网络 IP',
                          hintText: '10.147.xxx.xxx',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: Icon(Icons.lan_outlined, color: colorScheme.primary),
                          errorText: (!_isDhcp && !_isValidIP) ? '无效的 IPv4 地址' : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      children: [
                        Switch(
                          value: _isDhcp,
                          onChanged: (value) {
                            setState(() {
                              _isDhcp = value;
                            });
                            getIt<AppSettingsService>().setIsDhcp(value);
                          },
                        ),
                        Text(
                          _isDhcp ? '自动' : '手动',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_isDhcp)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'IP 地址将由服务器自动分配',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                Watch((context) {
                  return SwitchListTile(
                    title: const Text('禁用 P2P'),
                    subtitle: const Text('禁用点对点直连，仅通过中继服务器通信'),
                    value: settingsState.disableP2p.value,
                    onChanged: (value) {
                      settingsState.disableP2p.value = value;
                      settingsState.saveToPersistence();
                    },
                  );
                }),
                if (RuntimePlatform.operatingSystem == 'windows')
                  Watch((context) {
                    return SwitchListTile(
                      title: const Text('UDP 广播转发'),
                      subtitle: const Text(
                        '广播转发到虚拟网（局域网游戏发现房间等）；'
                        '通常需管理员权限，重新连接房间后生效。',
                      ),
                      value: settingsState.enableUdpBroadcastRelay.value,
                      onChanged: (value) {
                        settingsState.enableUdpBroadcastRelay.value = value;
                        settingsState.saveToPersistence();
                      },
                    );
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
