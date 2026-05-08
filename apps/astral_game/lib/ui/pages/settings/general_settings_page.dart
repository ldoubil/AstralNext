import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:astral_game/di.dart';
import 'package:astral_game/data/state/settings_state.dart';
import 'package:astral_game/data/state/update_state.dart';

class GeneralSettingsPage extends StatelessWidget {
  const GeneralSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsState = getIt<SettingsState>();
    final updateState = getIt<UpdateState>();

    return ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSettingsCard(
            context,
            children: [
              const ListTile(
                title: Text('界面设置'),
                subtitle: Text('控制应用的界面行为'),
                leading: Icon(Icons.settings),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('关闭时最小化到托盘'),
                subtitle: const Text('点击关闭按钮时最小化而不是退出'),
                value: settingsState.closeMinimize.value,
                onChanged: (value) {
                  settingsState.closeMinimize.value = value;
                  settingsState.saveToPersistence();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSettingsCard(
            context,
            children: [
              const ListTile(
                title: Text('更新设置'),
                subtitle: Text('配置应用更新行为'),
                leading: Icon(Icons.system_update),
              ),
              const Divider(height: 1),
              Watch((context) {
                return SwitchListTile(
                  title: const Text('自动检查更新'),
                  subtitle: const Text('启动时自动检查是否有新版本'),
                  value: updateState.autoCheckUpdate.value,
                  onChanged: (value) {
                    updateState.setAutoCheckUpdate(value);
                  },
                );
              }),
              const Divider(height: 1),
              Watch((context) {
                return SwitchListTile(
                  title: const Text('测试版频道'),
                  subtitle: const Text('接收测试版和预发布版本的更新'),
                  value: updateState.beta.value,
                  onChanged: (value) {
                    updateState.setBeta(value);
                  },
                );
              }),
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
