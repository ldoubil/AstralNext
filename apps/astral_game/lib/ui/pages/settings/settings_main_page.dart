import 'package:astral_game/di.dart';
import 'package:astral_game/ui/shell/shell_content_controller.dart';
import 'package:flutter/material.dart';
import 'general_settings_page.dart';
import 'avatar_settings_page.dart';
import 'network_settings_page.dart';
import 'listen_list_page.dart';
import 'cloud_backup_settings_page.dart';
import 'about_page.dart';

class SettingsMainPage extends StatefulWidget {
  const SettingsMainPage({super.key});

  @override
  State<SettingsMainPage> createState() => _SettingsMainPageState();
}

class _SettingsMainPageState extends State<SettingsMainPage> {
  final TextEditingController _usernameController = TextEditingController(text: '玩家');
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

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('设置已保存'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contentController = getIt<ShellContentController>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.person_outline,
                        color: colorScheme.onPrimaryContainer,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '用户信息',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '管理您的游戏身份',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: '用户名',
                    hintText: '请输入您的用户名',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.person_outline, color: colorScheme.primary),
                  ),
                ),
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
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: FilledButton(
                    onPressed: _saveSettings,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('保存'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader(context, '通用设置'),
        const SizedBox(height: 8),
        _buildSettingsCard(
          context,
          icon: Icons.person_outline,
          title: '头像设置',
          subtitle: '设置您的个人头像',
          onTap: () => contentController.showOverlay(
            title: '头像设置',
            content: const AvatarSettingsPage(),
          ),
        ),
        _buildSettingsCard(
          context,
          icon: Icons.settings,
          title: '软件设置',
          subtitle: '权限和界面设置',
          onTap: () => contentController.showOverlay(
            title: '软件设置',
            content: const GeneralSettingsPage(),
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader(context, '网络设置'),
        const SizedBox(height: 8),
        _buildSettingsCard(
          context,
          icon: Icons.network_wifi,
          title: '网络配置',
          subtitle: '协议、加密等高级选项',
          onTap: () => contentController.showOverlay(
            title: '网络配置',
            content: const NetworkSettingsPage(),
          ),
        ),
        _buildSettingsCard(
          context,
          icon: Icons.list_alt,
          title: '监听列表',
          subtitle: '管理网络监听地址',
          onTap: () => contentController.showOverlay(
            title: '监听列表',
            content: const ListenListPage(),
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader(context, '数据管理'),
        const SizedBox(height: 8),
        _buildSettingsCard(
          context,
          icon: Icons.cloud_upload_outlined,
          title: '云备份',
          subtitle: 'WebDAV 备份与恢复房间数据',
          onTap: () => contentController.showOverlay(
            title: '云备份',
            content: const CloudBackupSettingsPage(),
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader(context, '其他'),
        const SizedBox(height: 8),
        _buildSettingsCard(
          context,
          icon: Icons.info_outline,
          title: '关于',
          subtitle: '版本信息和相关链接',
          onTap: () => contentController.showOverlay(
            title: '关于',
            content: const AboutPage(),
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
        borderRadius: BorderRadius.circular(12),
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
