import 'package:flutter/material.dart';
import 'settings_state.dart';

class NetworkSettingsPage extends StatefulWidget {
  const NetworkSettingsPage({super.key});

  @override
  State<NetworkSettingsPage> createState() => _NetworkSettingsPageState();
}

class _NetworkSettingsPageState extends State<NetworkSettingsPage> {
  final TextEditingController _virtualIpController = TextEditingController(text: '10.147.18.24');
  bool _isDhcp = true;
  bool _isValidIP = true;

  bool _isValidIPv4(String ip) {
    final parts = ip.split('/');
    if (parts.length > 2) return false;

    final ipPart = parts[0];
    if (ipPart.isEmpty) return false;

    final octets = ipPart.split('.');
    if (octets.length != 4) return false;

    for (final octet in octets) {
      try {
        final value = int.parse(octet);
        if (value < 0 || value > 255) return false;
      } catch (e) {
        return false;
      }
    }

    if (parts.length == 2) {
      final maskPart = parts[1];
      if (maskPart.isEmpty) return false;
      try {
        final mask = int.parse(maskPart);
        if (mask < 0 || mask > 32) return false;
      } catch (e) {
        return false;
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
                              _isValidIP = _isValidIPv4(value);
                            });
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
                SwitchListTile(
                  title: const Text('禁用 P2P'),
                  subtitle: const Text('禁用点对点直连，仅通过中继服务器通信'),
                  value: settingsState.disableP2p.value,
                  onChanged: (value) {
                    settingsState.disableP2p.value = value;
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
