import 'dart:math';

import 'package:astral/di.dart';
import 'package:astral/stores/global/global_p2p_store.dart';
import 'package:astral_rust_core/src/rust/api/p2p.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:signals/signals_flutter.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

enum _ViewMode { list, topology }

class _NodeData {
  final KVNodeInfo info;
  final bool isDirect;
  final String viaNode;

  _NodeData({
    required this.info,
    required this.isDirect,
    required this.viaNode,
  });
}

class InstancePeersPage extends StatefulWidget {
  final String instancePath;
  final String instanceName;

  const InstancePeersPage({
    super.key,
    required this.instancePath,
    required this.instanceName,
  });

  @override
  State<InstancePeersPage> createState() => _InstancePeersPageState();
}

class _InstancePeersPageState extends State<InstancePeersPage> {
  late final GlobalP2PStore _p2pStore;
  _ViewMode _viewMode = _ViewMode.list;

  @override
  void initState() {
    super.initState();
    _p2pStore = getIt<GlobalP2PStore>();
  }

  String _formatBytes(BigInt bytes) {
    final value = bytes.toInt();
    if (value < 1024) return '$value B';
    if (value < 1024 * 1024) return '${(value / 1024).toStringAsFixed(1)} KB';
    if (value < 1024 * 1024 * 1024) {
      return '${(value / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(value / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  bool _isDirectConnection(KVNodeInfo node) {
    return node.cost <= 1 || node.hops.length <= 1;
  }

  String _getViaNode(KVNodeInfo node) {
    if (_isDirectConnection(node)) return '';
    if (node.hops.isEmpty) return '';
    final viaHop = node.hops.first;
    return viaHop.nodeName.isNotEmpty ? viaHop.nodeName : viaHop.targetIp;
  }

  int _resolveColumns(double width) {
    if (width >= 1600) {
      return 4;
    }
    if (width >= 1200) {
      return 3;
    }
    if (width >= 700) {
      return 2;
    }
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Watch((context) {
      final status = _p2pStore.networkStatusByPath.value[widget.instancePath];
      final nodes = status?.nodes ?? [];

      if (nodes.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.devices_other_outlined,
                size: 48,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                '暂无节点信息',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '实例可能未运行或未连接到网络',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '节点信息',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${nodes.length} 个节点',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                SegmentedButton<_ViewMode>(
                  segments: const [
                    ButtonSegment(
                      value: _ViewMode.list,
                      icon: Icon(Icons.list, size: 18),
                      label: Text('列表'),
                    ),
                    ButtonSegment(
                      value: _ViewMode.topology,
                      icon: Icon(Icons.account_tree_outlined, size: 18),
                      label: Text('拓扑'),
                    ),
                  ],
                  selected: {_viewMode},
                  onSelectionChanged: (mode) {
                    setState(() => _viewMode = mode.first);
                  },
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    textStyle: const WidgetStatePropertyAll(
                      TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _viewMode == _ViewMode.list
                ? _buildGridView(context, nodes)
                : _TopologyView(
                    key: ValueKey(nodes.map((n) => n.peerId).join(',')),
                    nodes: nodes,
                  ),
          ),
        ],
      );
    });
  }

  Widget _buildGridView(BuildContext context, List<KVNodeInfo> nodes) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final columns = _resolveColumns(constraints.maxWidth);

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              sliver: SliverMasonryGrid(
                gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                ),
                mainAxisSpacing: spacing,
                crossAxisSpacing: spacing,
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildNodeCard(context, nodes[index]),
                  childCount: nodes.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNodeCard(BuildContext context, KVNodeInfo node) {
    final colorScheme = Theme.of(context).colorScheme;
    final isConnected = node.latencyMs > 0;
    final isDirect = _isDirectConnection(node);
    final viaNode = _getViaNode(node);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: isConnected
                        ? (isDirect ? colorScheme.primary : Colors.orange)
                        : colorScheme.outline,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    node.hostname.isNotEmpty ? node.hostname : node.ipv4,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDirect
                        ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                        : Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isDirect ? '直连' : '中转',
                    style: TextStyle(
                      color: isDirect
                          ? colorScheme.onPrimaryContainer
                          : Colors.orange.shade800,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.language, size: 12, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  node.ipv4,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (viaNode.isNotEmpty) ...[
              const SizedBox(height: 5),
              Row(
                children: [
                  Icon(
                    Icons.alt_route,
                    size: 12,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '通过 $viaNode 中转',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _buildInfoChip(
                  context,
                  icon: Icons.timer_outlined,
                  value: '${node.latencyMs.toStringAsFixed(1)}ms',
                ),
                _buildInfoChip(
                  context,
                  icon: Icons.warning_amber_outlined,
                  value: '${node.lossRate.toStringAsFixed(2)}%',
                ),
                _buildInfoChip(
                  context,
                  icon: Icons.router_outlined,
                  value: node.nat,
                ),
                _buildInfoChip(
                  context,
                  icon: Icons.cable_outlined,
                  value: node.connType,
                ),
                _buildInfoChip(
                  context,
                  icon: Icons.download_outlined,
                  value: _formatBytes(node.rxBytes),
                ),
                _buildInfoChip(
                  context,
                  icon: Icons.upload_outlined,
                  value: _formatBytes(node.txBytes),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 3),
          Text(
            value,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopologyView extends StatefulWidget {
  final List<KVNodeInfo> nodes;

  const _TopologyView({super.key, required this.nodes});

  @override
  State<_TopologyView> createState() => _TopologyViewState();
}

class _TopologyViewState extends State<_TopologyView> {
  late NodeFlowController<_NodeData, dynamic> _controller;

  @override
  void initState() {
    super.initState();
    _controller = _buildController(widget.nodes);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  NodeFlowController<_NodeData, dynamic> _buildController(List<KVNodeInfo> nodes) {
    final flowNodes = <Node<_NodeData>>[];
    final connections = <Connection>[];
    final peerIdToId = <int, String>{};
    final nodePositions = <int, Offset>{};
    final parentChildIndexMap = <int, int>{};

    final localNode = nodes.firstWhere(
      (n) => n.cost == 0,
      orElse: () => nodes.first,
    );

    final layers = <int, List<KVNodeInfo>>{};
    for (final node in nodes) {
      final layer = node.cost.clamp(0, 5);
      layers.putIfAbsent(layer, () => []).add(node);
    }

    final sortedLayers = layers.keys.toList()..sort();
    const layerWidth = 350.0;
    const nodeVerticalSpacing = 180.0;
    const centerY = 500.0;
    const startX = 100.0;

    final parentMap = <int, int>{};
    for (final node in nodes) {
      if (node.hops.isNotEmpty) {
        parentMap[node.peerId] = node.hops.first.peerId;
      }
    }

    for (final layer in sortedLayers) {
      final nodesInLayer = layers[layer]!;
      final layerX = startX + layer * layerWidth;

      nodesInLayer.sort((a, b) {
        final aParentId = parentMap[a.peerId];
        final bParentId = parentMap[b.peerId];
        
        if (aParentId != null && bParentId != null) {
          final parentCompare = aParentId.compareTo(bParentId);
          if (parentCompare != 0) return parentCompare;
        }
        
        if (aParentId != null && bParentId == null) return -1;
        if (aParentId == null && bParentId != null) return 1;
        
        return a.peerId.compareTo(b.peerId);
      });

      final noParentNodes = nodesInLayer.where((n) => !parentMap.containsKey(n.peerId)).toList();
      final withParentNodes = nodesInLayer.where((n) => parentMap.containsKey(n.peerId)).toList();

      final noParentCount = noParentNodes.length;
      final noParentTotalHeight = noParentCount > 0 ? (noParentCount - 1) * nodeVerticalSpacing : 0;
      final noParentStartY = centerY - noParentTotalHeight / 2;

      for (var i = 0; i < noParentNodes.length; i++) {
        final node = noParentNodes[i];
        final nodeId = 'node_${node.peerId}';
        peerIdToId[node.peerId] = nodeId;

        final isDirect = node.cost <= 1 || node.hops.length <= 1;
        final viaHop = !isDirect && node.hops.isNotEmpty
            ? (node.hops.first.nodeName.isNotEmpty
                ? node.hops.first.nodeName
                : node.hops.first.targetIp)
            : '';
        final nodeData = _NodeData(
          info: node,
          isDirect: isDirect,
          viaNode: viaHop,
        );

        final position = Offset(layerX, noParentStartY + i * nodeVerticalSpacing);
        nodePositions[node.peerId] = position;

        flowNodes.add(Node<_NodeData>(
          id: nodeId,
          type: isDirect ? 'direct' : 'relay',
          position: position,
          data: nodeData,
          ports: [
            Port(
              id: 'in',
              name: 'In',
              position: PortPosition.left,
              type: PortType.input,
              offset: const Offset(0, 40),
            ),
            Port(
              id: 'out',
              name: 'Out',
              position: PortPosition.right,
              type: PortType.output,
              offset: const Offset(0, 40),
            ),
          ],
        ));
      }

      for (final node in withParentNodes) {
        final nodeId = 'node_${node.peerId}';
        peerIdToId[node.peerId] = nodeId;

        final isDirect = node.cost <= 1 || node.hops.length <= 1;
        final viaHop = !isDirect && node.hops.isNotEmpty
            ? (node.hops.first.nodeName.isNotEmpty
                ? node.hops.first.nodeName
                : node.hops.first.targetIp)
            : '';
        final nodeData = _NodeData(
          info: node,
          isDirect: isDirect,
          viaNode: viaHop,
        );

        double y;
        final parentId = parentMap[node.peerId];
        if (parentId != null && nodePositions.containsKey(parentId)) {
          final parentPos = nodePositions[parentId]!;
          final childIndex = parentChildIndexMap[parentId] ?? 0;
          y = parentPos.dy + (childIndex % 2 == 0 ? -1 : 1) * nodeVerticalSpacing * 0.8 * ((childIndex / 2).ceil() + 1);
          parentChildIndexMap[parentId] = childIndex + 1;
        } else {
          y = centerY;
        }

        final position = Offset(layerX, y);
        nodePositions[node.peerId] = position;

        flowNodes.add(Node<_NodeData>(
          id: nodeId,
          type: isDirect ? 'direct' : 'relay',
          position: position,
          data: nodeData,
          ports: [
            Port(
              id: 'in',
              name: 'In',
              position: PortPosition.left,
              type: PortType.input,
              offset: const Offset(0, 40),
            ),
            Port(
              id: 'out',
              name: 'Out',
              position: PortPosition.right,
              type: PortType.output,
              offset: const Offset(0, 40),
            ),
          ],
        ));
      }
    }

    final addedEdges = <String>{};
    for (final node in nodes) {
      final hops = node.hops;
      if (hops.isEmpty) continue;

      int? previousPeerId;
      for (final hop in hops) {
        if (previousPeerId != null && previousPeerId != hop.peerId) {
          final fromId = peerIdToId[previousPeerId];
          final toId = peerIdToId[hop.peerId];
          if (fromId != null && toId != null && fromId != toId) {
            final edgeKey = '${fromId}_$toId';
            final reverseKey = '${toId}_$fromId';
            if (!addedEdges.contains(edgeKey) && !addedEdges.contains(reverseKey)) {
              connections.add(Connection(
                id: 'conn_${connections.length}',
                sourceNodeId: fromId,
                sourcePortId: 'out',
                targetNodeId: toId,
                targetPortId: 'in',
              ));
              addedEdges.add(edgeKey);
            }
          }
        }
        previousPeerId = hop.peerId;
      }

      if (hops.isNotEmpty) {
        final lastHopPeerId = hops.last.peerId;
        final lastHopId = peerIdToId[lastHopPeerId];
        final targetId = peerIdToId[node.peerId];
        if (lastHopId != null && targetId != null && lastHopId != targetId) {
          final edgeKey = '${lastHopId}_$targetId';
          final reverseKey = '${targetId}_$lastHopId';
          if (!addedEdges.contains(edgeKey) && !addedEdges.contains(reverseKey)) {
            connections.add(Connection(
              id: 'conn_${connections.length}',
              sourceNodeId: lastHopId,
              sourcePortId: 'out',
              targetNodeId: targetId,
              targetPortId: 'in',
            ));
            addedEdges.add(edgeKey);
          }
        }
      }
    }

    return NodeFlowController<_NodeData, dynamic>(
      nodes: flowNodes,
      connections: connections,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return NodeFlowEditor<_NodeData, dynamic>(
      controller: _controller,
      theme: isDark ? NodeFlowTheme.dark : NodeFlowTheme.light,
      nodeBuilder: (context, node) => _buildFlowNode(context, node.data, colorScheme),
    );
  }

  Widget _buildFlowNode(BuildContext context, _NodeData data, ColorScheme colorScheme) {
    final node = data.info;
    final isConnected = node.latencyMs > 0;
    final isDirect = data.isDirect;
    final isLocal = node.cost == 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isLocal
            ? colorScheme.primaryContainer
            : (isConnected
                ? (isDirect ? colorScheme.secondaryContainer : Colors.orange.withValues(alpha: 0.1))
                : colorScheme.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLocal
              ? colorScheme.primary
              : (isConnected
                  ? (isDirect
                      ? colorScheme.secondary.withValues(alpha: 0.5)
                      : Colors.orange.withValues(alpha: 0.4))
                  : colorScheme.outlineVariant),
          width: isLocal ? 2.5 : 1.5,
        ),
        boxShadow: isLocal
            ? [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            isLocal ? Icons.computer : (isDirect ? Icons.devices : Icons.alt_route),
            size: 24,
            color: isLocal
                ? colorScheme.onPrimaryContainer
                : (isConnected
                    ? (isDirect
                        ? colorScheme.onSecondaryContainer
                        : Colors.orange.shade700)
                    : colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          Text(
            node.hostname.isNotEmpty
                ? (node.hostname.length > 10 ? '${node.hostname.substring(0, 10)}...' : node.hostname)
                : 'Node',
            style: TextStyle(
              color: isLocal
                  ? colorScheme.onPrimaryContainer
                  : (isConnected
                      ? (isDirect
                          ? colorScheme.onSecondaryContainer
                          : Colors.orange.shade800)
                      : colorScheme.onSurface),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            node.ipv4,
            style: TextStyle(
              color: isLocal
                  ? colorScheme.onPrimaryContainer.withValues(alpha: 0.8)
                  : (isConnected
                      ? (isDirect
                          ? colorScheme.onSecondaryContainer.withValues(alpha: 0.7)
                          : Colors.orange.shade600)
                      : colorScheme.onSurfaceVariant),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (isConnected) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (isLocal
                        ? colorScheme.primary
                        : (isDirect ? colorScheme.secondary : Colors.orange))
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${node.latencyMs.toStringAsFixed(0)}ms',
                style: TextStyle(
                  color: isLocal
                      ? colorScheme.primary
                      : (isDirect ? colorScheme.secondary : Colors.orange.shade700),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
