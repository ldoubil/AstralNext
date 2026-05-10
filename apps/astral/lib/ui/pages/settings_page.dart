import 'package:astral/ui/pages/settings/appearance_settings_page.dart';
import 'package:astral/ui/pages/settings/cloud_backup_settings_page.dart';
import 'package:astral/ui/pages/settings/software_settings_page.dart';
import 'package:astral/ui/pages/settings/storage_settings_page.dart';
import 'package:astral/ui/shell/shell_content_controller.dart';
import 'package:astral/di.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final contentController = getIt<ShellContentController>();
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            '软件设置',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _buildSettingsCard(
          context,
          icon: Icons.palette,
          title: '主题设置',
          subtitle: '主题模式和主题配色',
          onTap: () => contentController.showOverlay(
            title: '主题设置',
            content: const AppearanceSettingsPage(),
          ),
        ),
        _buildSettingsCard(
          context,
          icon: Icons.settings,
          title: '软件设置',
          subtitle: '窗口行为和编辑器偏好',
          onTap: () => contentController.showOverlay(
            title: '软件设置',
            content: const SoftwareSettingsPage(),
          ),
        ),
        _buildSettingsCard(
          context,
          icon: Icons.folder,
          title: '数据存储',
          subtitle: '配置文件存储位置',
          onTap: () => contentController.showOverlay(
            title: '数据存储',
            content: const StorageSettingsPage(),
          ),
        ),
        _buildSettingsCard(
          context,
          icon: Icons.cloud_outlined,
          title: '云备份',
          subtitle: 'WebDAV 备份与恢复',
          onTap: () => contentController.showOverlay(
            title: '云备份',
            content: const CloudBackupSettingsPage(),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
