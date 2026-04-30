import 'package:flutter/material.dart';
import 'package:astral_game/di.dart';
import 'package:astral_game/data/state/settings_state.dart';

class GeneralSettingsPage extends StatelessWidget {
  const GeneralSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                value: getIt<SettingsState>().closeMinimize.value,
                onChanged: (value) {
                  getIt<SettingsState>().closeMinimize.value = value;
                },
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
