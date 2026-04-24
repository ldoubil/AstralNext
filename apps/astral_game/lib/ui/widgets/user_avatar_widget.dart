import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:astral_game/data/services/avatar_service.dart';

class UserAvatarWidget extends StatefulWidget {
  final String ip;
  final int port;
  final double size;

  const UserAvatarWidget({
    super.key,
    required this.ip,
    this.port = 4924,
    this.size = 40,
  });

  @override
  State<UserAvatarWidget> createState() => _UserAvatarWidgetState();
}

class _UserAvatarWidgetState extends State<UserAvatarWidget> {
  Uint8List? _avatar;

  @override
  void initState() {
    super.initState();
    _fetchAvatar();
  }

  @override
  void didUpdateWidget(covariant UserAvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ip != widget.ip || oldWidget.port != widget.port) {
      _avatar = null;
      _fetchAvatar();
    }
  }

  Future<void> _fetchAvatar() async {
    try {
      final avatar = await AvatarService().fetchAvatar(widget.ip, port: widget.port);
      if (avatar != null) {
        setState(() {
          _avatar = avatar;
        });
      }
    } catch (e) {
      print('[UserAvatarWidget] Failed to fetch avatar from ${widget.ip}: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.primaryContainer,
        border: Border.all(
          color: colorScheme.outline,
          width: 1,
        ),
      ),
      child: _avatar != null
          ? ClipOval(
              child: Image.memory(
                _avatar!,
                fit: BoxFit.cover,
                width: widget.size,
                height: widget.size,
              ),
            )
          : Icon(
              Icons.person,
              size: widget.size * 0.5,
              color: colorScheme.onPrimaryContainer,
            ),
    );
  }
}
