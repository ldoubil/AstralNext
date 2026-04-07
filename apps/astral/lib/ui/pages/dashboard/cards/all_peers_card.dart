part of 'package:astral/ui/pages/dashboard_page.dart';

class _AllPeersCard extends StatelessWidget {
  final GlobalP2PStore p2pStore;
  final String? selectedInstancePath;
  final void Function(String path, String name)? onInstanceTap;

  const _AllPeersCard({
    super.key,
    required this.p2pStore,
    this.selectedInstancePath,
    this.onInstanceTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Watch((context) {
      final instanceIds = p2pStore.instanceIdByPath.value;
      final networkStatusMap = p2pStore.networkStatusByPath.value;

      final isRunning = selectedInstancePath != null &&
          instanceIds.containsKey(selectedInstancePath);

      List<_NodeItem> allNodes = [];
      if (selectedInstancePath != null) {
        final status = networkStatusMap[selectedInstancePath];
        if (status != null) {
          for (final node in status.nodes) {
            allNodes.add(_NodeItem(
              hostname: node.hostname,
              ipv4: node.ipv4,
              latencyMs: node.latencyMs,
            ));
          }
        }
      }

      return _DashboardCard(
        title: '全部节点',
        subtitle: isRunning ? '当前实例' : '未运行',
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: allNodes.isNotEmpty
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${allNodes.length} 个节点',
            style: TextStyle(
              color: allNodes.isNotEmpty
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical:0),
        child: allNodes.isEmpty
            ? _buildEmptyState(context)
            : _buildNodeList(context, allNodes),
      );
    });
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.devices_other_outlined,
              size: 28,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              '暂无节点',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNodeList(BuildContext context, List<_NodeItem> nodes) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 280),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: nodes.length,
        itemBuilder: (context, index) => _NodeRow(node: nodes[index]),
      ),
    );
  }
}

class _NodeItem {
  final String hostname;
  final String ipv4;
  final double latencyMs;

  const _NodeItem({
    required this.hostname,
    required this.ipv4,
    required this.latencyMs,
  });
}

class _NodeRow extends StatelessWidget {
  final _NodeItem node;

  const _NodeRow({required this.node});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Clipboard.setData(ClipboardData(text: node.ipv4));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已复制: ${node.ipv4}'),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  node.hostname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                node.ipv4,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 48,
                child: Text(
                  node.latencyMs > 0 ? '${node.latencyMs.toStringAsFixed(0)} ms' : '-',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
