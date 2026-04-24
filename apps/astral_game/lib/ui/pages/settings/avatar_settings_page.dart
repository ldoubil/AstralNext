import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';

import 'package:astral_game/data/services/client_api_service.dart';

class AvatarSettingsPage extends StatefulWidget {
  const AvatarSettingsPage({super.key});

  @override
  State<AvatarSettingsPage> createState() => _AvatarSettingsPageState();
}

class _AvatarSettingsPageState extends State<AvatarSettingsPage> {
  final ClientApiService _apiService = GetIt.I<ClientApiService>();
  Uint8List? _currentAvatar;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    await _apiService.init();
    setState(() {
      _currentAvatar = _apiService.getAvatar();
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 256,
      maxHeight: 256,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      
      await _apiService.setAvatar(bytes);
      
      setState(() {
        _currentAvatar = bytes;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('头像已更新')),
      );
    }
  }

  Future<void> _removeAvatar() async {
    await _apiService.setAvatar(Uint8List(0));
    
    setState(() {
      _currentAvatar = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已恢复默认头像')),
    );
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
                      Container(
                        width: 128,
                        height: 128,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.primaryContainer,
                          border: Border.all(
                            color: colorScheme.outline,
                            width: 2,
                          ),
                        ),
                        child: _currentAvatar != null
                            ? ClipOval(
                                child: Image.memory(
                                  _currentAvatar!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                size: 64,
                                color: Colors.grey,
                              ),
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
                    '头像将通过端口 4924 暴露给其他玩家',
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
