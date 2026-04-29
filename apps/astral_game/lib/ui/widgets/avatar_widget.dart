import 'dart:typed_data';

import 'package:flutter/material.dart';

class AvatarWidget extends StatelessWidget {
  final Uint8List? avatar;
  final double size;
  final VoidCallback? onTap;

  const AvatarWidget({
    super.key,
    this.avatar,
    this.size = 40,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.primaryContainer,
          border: Border.all(color: colorScheme.outline, width: 1),
        ),
        child: avatar != null
            ? ClipOval(
                child: Image.memory(
                  avatar!,
                  fit: BoxFit.cover,
                  width: size,
                  height: size,
                  gaplessPlayback: true,
                ),
              )
            : Icon(
                Icons.person,
                size: size * 0.5,
                color: colorScheme.onPrimaryContainer,
              ),
      ),
    );
  }
}
