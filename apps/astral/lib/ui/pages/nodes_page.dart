import 'package:flutter/material.dart';

class NodesPage extends StatelessWidget {
  const NodesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final nodes = const [
      _NodeInfo(name: '节点-北京-01', status: '运行中', latencyMs: 18, load: 0.32),
      _NodeInfo(name: '节点-上海-02', status: '运行中', latencyMs: 26, load: 0.48),
      _NodeInfo(name: '节点-广州-03', status: '维护中', latencyMs: 0, load: 0),
      _NodeInfo(name: '节点-新加坡-04', status: '运行中', latencyMs: 34, load: 0.57),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        Text(
          '节点拓扑',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '使用色块分隔节点状态，无阴影、无描边。',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),
        ...nodes.map((node) => _NodeCard(info: node)).toList(),
      ],
    );
  }
}

class _NodeCard extends StatelessWidget {
  final _NodeInfo info;

  const _NodeCard({required this.info});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isOnline = info.status == '运行中';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 48,
            decoration: BoxDecoration(
              color: isOnline ? colorScheme.primary : colorScheme.error,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.name,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  info.status,
                  style: TextStyle(
                    color: isOnline
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '延迟 ${info.latencyMs} ms',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              _LoadBar(
                value: info.load,
                color: colorScheme.secondary,
                background: colorScheme.secondaryContainer,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadBar extends StatelessWidget {
  final double value;
  final Color color;
  final Color background;

  const _LoadBar({
    required this.value,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 10,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

class _NodeInfo {
  final String name;
  final String status;
  final int latencyMs;
  final double load;

  const _NodeInfo({
    required this.name,
    required this.status,
    required this.latencyMs,
    required this.load,
  });
}
