import 'package:flutter/material.dart';
import 'settings_state.dart';

class NetworkSettingsPage extends StatelessWidget {
  const NetworkSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSettingsCard(
            context,
            children: [
              const ListTile(
                title: Text('传输设置'),
                subtitle: Text('P2P 传输协议偏好'),
                leading: Icon(Icons.swap_horiz),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('默认协议'),
                subtitle: const Text('P2P 打洞首选协议'),
                trailing: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: DropdownButton<String>(
                      value: settingsState.defaultProtocol.value,
                      items: const [
                        DropdownMenuItem(
                          value: 'tcp',
                          child: Text('TCP', style: TextStyle(fontSize: 14)),
                        ),
                        DropdownMenuItem(
                          value: 'udp',
                          child: Text('UDP', style: TextStyle(fontSize: 14)),
                        ),
                        DropdownMenuItem(
                          value: 'faketcp',
                          child: Text('FakeTCP', style: TextStyle(fontSize: 14)),
                        ),
                        DropdownMenuItem(
                          value: 'ws',
                          child: Text('WebSocket', style: TextStyle(fontSize: 14)),
                        ),
                        DropdownMenuItem(
                          value: 'wss',
                          child: Text('WSS', style: TextStyle(fontSize: 14)),
                        ),
                        DropdownMenuItem(
                          value: 'quic',
                          child: Text('QUIC', style: TextStyle(fontSize: 14)),
                        ),
                      ],
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down),
                      onChanged: (value) {
                        if (value != null) {
                          settingsState.defaultProtocol.value = value;
                        }
                      },
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('启用加密'),
                subtitle: const Text('加密所有传输数据'),
                value: settingsState.enableEncryption.value,
                onChanged: (value) {
                  settingsState.enableEncryption.value = value;
                },
              ),
              SwitchListTile(
                title: const Text('延迟优先'),
                subtitle: const Text('优先选择延迟最低的节点'),
                value: settingsState.latencyFirst.value,
                onChanged: (value) {
                  settingsState.latencyFirst.value = value;
                },
              ),
              SwitchListTile(
                title: const Text('禁用 P2P'),
                subtitle: const Text('禁用点对点直连'),
                value: settingsState.disableP2p.value,
                onChanged: (value) {
                  settingsState.disableP2p.value = value;
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingsCard(
            context,
            children: [
              const ListTile(
                title: Text('高级设置'),
                subtitle: Text('数据压缩等高级选项'),
                leading: Icon(Icons.settings_ethernet),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('压缩算法'),
                subtitle: const Text('数据传输压缩方式'),
                trailing: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: DropdownButton<int>(
                      value: settingsState.dataCompressAlgo.value,
                      items: [
                        DropdownMenuItem(
                          value: 1,
                          child: Text(
                            '不压缩',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 2,
                          child: Text(
                            '高性能压缩',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down),
                      onChanged: (value) {
                        if (value != null) {
                          settingsState.dataCompressAlgo.value = value;
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required List<Widget> children,
  }) {
    return Card(
      child: Column(children: children),
    );
  }
}
