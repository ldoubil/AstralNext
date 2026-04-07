part of 'package:astral/ui/pages/dashboard_page.dart';

class _InstanceControlCard extends StatelessWidget {
  final InstanceCatalogItem item;
  final GlobalP2PStore p2pStore;
  final VoidCallback onToggle;
  final VoidCallback onConfig;

  const _InstanceControlCard({
    super.key,
    required this.item,
    required this.p2pStore,
    required this.onToggle,
    required this.onConfig,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Watch((context) {
      final isRunning = p2pStore.instanceIdByPath.value.containsKey(item.path);
      final isStarting = p2pStore.startingPaths.value.contains(item.path);

      return _DashboardCard(
        title: '实例控制',
        subtitle: isRunning ? '运行中' : '已停止',
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isRunning
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            isRunning ? '运行中' : '已停止',
            style: TextStyle(
              color: isRunning
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.fileName,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onConfig,
                    icon: const Icon(Icons.tune, size: 16),
                    label: const Text('配置'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isStarting ? null : onToggle,
                    icon: isStarting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            isRunning
                                ? Icons.stop_circle_outlined
                                : Icons.play_circle_outline,
                            size: 16,
                          ),
                    label: Text(isStarting
                        ? '启动中'
                        : isRunning
                            ? '停止'
                            : '启动'),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: isRunning
                          ? colorScheme.errorContainer
                          : colorScheme.primaryContainer,
                      foregroundColor: isRunning
                          ? colorScheme.onErrorContainer
                          : colorScheme.onPrimaryContainer,
                    ),
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
