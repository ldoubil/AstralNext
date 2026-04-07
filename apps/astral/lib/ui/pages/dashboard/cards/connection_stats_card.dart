part of 'package:astral/ui/pages/dashboard_page.dart';

class _ConnectionStatsCard extends StatelessWidget {
  final String instancePath;
  final GlobalP2PStore p2pStore;

  const _ConnectionStatsCard({
    super.key,
    required this.instancePath,
    required this.p2pStore,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Watch((context) {
      final traffic = p2pStore.trafficByPath.value[instancePath];
      final nodeCount = traffic?.nodeCount ?? 0;
      final avgLatencyMs = traffic?.avgLatencyMs ?? 0;
      final avgLossRate = traffic?.avgLossRate ?? 0;

      final isRunning = p2pStore.isRunning(instancePath);

      return _DashboardCard(
        title: '节点统计',
        subtitle: isRunning ? '已连接' : '未连接',
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isRunning
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            isRunning ? '运行中' : '未连接',
            style: TextStyle(
              color: isRunning
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        contentPadding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('节点数', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                Text(
                  nodeCount.toString(),
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('平均延迟', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                Text(
                  '${avgLatencyMs.toStringAsFixed(1)} ms',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('平均丢包', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                Text(
                  '${avgLossRate.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}
