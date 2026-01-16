import 'dart:ui';

import 'package:flutter/material.dart';

class LogsPage extends StatelessWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final logs = const [
      _LogLine(level: 'INFO', time: '10:12:04', message: '实例-1 心跳成功，延迟 24 ms'),
      _LogLine(level: 'WARN', time: '10:11:50', message: '实例-3 未连接，已进入待命'),
      _LogLine(level: 'INFO', time: '10:11:42', message: '同步路由表完成，共 256 条'),
      _LogLine(level: 'ERROR', time: '10:11:03', message: '节点-广州-03 超时，等待重试'),
      _LogLine(level: 'INFO', time: '10:10:55', message: '配置下发完成，版本 v1.4.3'),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        Text(
          '运行日志',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '纯色块结构的日志列表，避免阴影和描边。',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              for (final log in logs) ...[
                _LogRow(line: log),
                if (log != logs.last) const Divider(height: 1),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LogRow extends StatelessWidget {
  final _LogLine line;

  const _LogRow({required this.line});

  Color _badgeColor(ColorScheme scheme) {
    switch (line.level) {
      case 'ERROR':
        return scheme.error;
      case 'WARN':
        return scheme.tertiary;
      default:
        return scheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final badgeColor = _badgeColor(colorScheme);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 56,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              line.level,
              style: TextStyle(
                color: badgeColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            line.time,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              line.message,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogLine {
  final String level;
  final String time;
  final String message;

  const _LogLine({
    required this.level,
    required this.time,
    required this.message,
  });
}
