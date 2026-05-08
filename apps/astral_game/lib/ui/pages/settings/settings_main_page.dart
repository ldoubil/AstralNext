import 'package:astral_game/di.dart';
import 'package:astral_game/ui/shell/shell_content_controller.dart';
import 'package:flutter/material.dart';
import 'package:astral_game/config/constants.dart';
import 'general_settings_page.dart';
import 'network_settings_page.dart';
import 'cloud_backup_settings_page.dart';
import 'about_page.dart';

class SettingsMainPage extends StatelessWidget {
  const SettingsMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final contentController = getIt<ShellContentController>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader(context, '通用设置'),
        const SizedBox(height: 8),
        _buildSettingsCard(
          context,
          icon: Icons.settings,
          title: '软件设置',
          subtitle: '权限和界面设置',
          onTap: () => contentController.showOverlay(
            title: '软件设置',
            contentBuilder: (_) => const GeneralSettingsPage(),
          ),
        ),
        _buildSectionHeader(context, '网络设置'),
        const SizedBox(height: 8),
        _buildSettingsCard(
          context,
          icon: Icons.network_wifi,
          title: '网络配置',
          subtitle: 'IP 地址和 P2P 设置',
          onTap: () => contentController.showOverlay(
            title: '网络配置',
            contentBuilder: (_) => const NetworkSettingsPage(),
          ),
        ),
        _buildSectionHeader(context, '数据管理'),
        const SizedBox(height: 8),
        _buildSettingsCard(
          context,
          icon: Icons.cloud_upload_outlined,
          title: '云备份',
          subtitle: 'WebDAV 备份与恢复房间数据',
          onTap: () => contentController.showOverlay(
            title: '云备份',
            contentBuilder: (_) => const CloudBackupSettingsPage(),
          ),
        ),
        _buildSectionHeader(context, '其他'),
        const SizedBox(height: 8),
        _buildSettingsCard(
          context,
          icon: Icons.info_outline,
          title: '关于',
          subtitle: '版本信息和相关链接',
          onTap: () => contentController.showOverlay(
            title: '关于',
            contentBuilder: (_) => const AboutPage(),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brMedium,
        side: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
      ),
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
