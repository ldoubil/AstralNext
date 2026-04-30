import 'dart:async';
import 'dart:typed_data';
import 'package:astral_game/di.dart';
import 'package:astral_game/ui/shell/shell_content_controller.dart';
import 'package:astral_game/ui/widgets/avatar_widget.dart';
import 'package:astral_game/utils/image_picker_helper.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../data/services/node_management_service.dart';
import 'general_settings_page.dart';
import 'network_settings_page.dart';
import 'cloud_backup_settings_page.dart';
import 'about_page.dart';

class SettingsMainPage extends StatefulWidget {
  const SettingsMainPage({super.key});

  @override
  State<SettingsMainPage> createState() => _SettingsMainPageState();
}

class _SettingsMainPageState extends State<SettingsMainPage> {
  final NodeManagementService _p2pStore = GetIt.I<NodeManagementService>();
  final TextEditingController _usernameController = TextEditingController();
  Uint8List? _currentAvatar;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _usernameController.text = _p2pStore.currentUsername.value;
    _currentAvatar = _p2pStore.currentUserAvatar.value;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final bytes = await ImagePickerHelper.pickImageFromGallery();

    if (bytes != null) {
      await _p2pStore.updateCurrentUserAvatar(bytes);
      
      setState(() {
        _currentAvatar = bytes;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('头像已更新')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final contentController = getIt<ShellContentController>();
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
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
                    GestureDetector(
                      onTap: _pickImage,
                      child: AvatarWidget(
                        avatar: _currentAvatar,
                        size: 56,
                        shape: AvatarShape.roundedSquare,
                        borderRadius: 16,
                        showBorder: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: '名字',
                          hintText: '请输入您的名字',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: Icon(Icons.person_outline, color: colorScheme.primary),
                        ),
                        onChanged: (value) {
                          // 使用防抖，避免频繁写入
                          _debounceTimer?.cancel();
                          _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                            // 即时保存用户名到 NodeManagementService（会持久化）
                            _p2pStore.updateCurrentUsername(value);
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        _buildSectionHeader(context, '通用设置'),
        const SizedBox(height: 8),
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
        _buildSectionHeader(context, '网络设置'),
        const SizedBox(height: 8),
        _buildSettingsCard(
          context,
          icon: Icons.network_wifi,
          title: '网络配置',
          subtitle: 'IP 地址和 P2P 设置',
          onTap: () => contentController.showOverlay(
            title: '网络配置',
            content: const NetworkSettingsPage(),
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
            content: const CloudBackupSettingsPage(),
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
