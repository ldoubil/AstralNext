import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:astral_game/data/services/node_management_service.dart';
import 'package:astral_game/ui/widgets/avatar_widget.dart';
import 'package:astral_game/utils/image_picker_helper.dart';

class AvatarSettingsPage extends StatefulWidget {
  const AvatarSettingsPage({super.key});

  @override
  State<AvatarSettingsPage> createState() => _AvatarSettingsPageState();
}

class _AvatarSettingsPageState extends State<AvatarSettingsPage> {
  final NodeManagementService _p2pStore = GetIt.I<NodeManagementService>();
  Uint8List? _currentAvatar;

  @override
  void initState() {
    super.initState();
    _currentAvatar = _p2pStore.currentUserAvatar.value;
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

  Future<void> _removeAvatar() async {
    await _p2pStore.updateCurrentUserAvatar(null);
    
    setState(() {
      _currentAvatar = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已恢复默认头像')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const ListTile(
                  title: Text('头像设置'),
                  subtitle: Text('设置您的个人头像'),
                  leading: Icon(Icons.person),
                ),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Center(
                  child: Stack(
                    children: [
                      AvatarWidget(
                        avatar: _currentAvatar,
                        size: 128,
                        shape: AvatarShape.circle,
                        borderWidth: 2,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.primary,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: Colors.white,
                            ),
                            onPressed: _pickImage,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _pickImage,
                      child: const Text('选择图片'),
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: _currentAvatar != null ? _removeAvatar : null,
                      child: const Text('恢复默认'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '头像将通过动态分配的端口暴露给其他玩家',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
