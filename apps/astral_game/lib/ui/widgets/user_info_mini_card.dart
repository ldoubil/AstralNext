import 'package:flutter/material.dart';

class UserInfoMiniCard extends StatelessWidget {
  final String username;
  final bool isConnected;
  final String virtualIp;

  const UserInfoMiniCard({
    super.key,
    this.username = 'Player',
    this.isConnected = false,
    this.virtualIp = '100.100.100.1',
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.person_outline,
              color: colorScheme.onPrimaryContainer,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isConnected ? colorScheme.primary : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isConnected ? '已连接' : '未连接',
                      style: textTheme.bodySmall?.copyWith(
                        color: isConnected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (isConnected) ...[
                      const SizedBox(width: 8),
                      Text(
                        virtualIp,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
    );
  }
}
