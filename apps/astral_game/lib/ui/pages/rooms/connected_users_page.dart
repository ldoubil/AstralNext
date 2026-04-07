import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:signals/signals_flutter.dart';
import 'package:astral_game/di.dart';
import 'package:astral_game/data/services/global_p2p_store.dart';
import 'package:astral_rust_core/src/rust/api/p2p.dart';

class ConnectedUsersPage extends StatefulWidget {
  const ConnectedUsersPage({super.key});

  @override
  State<ConnectedUsersPage> createState() => _ConnectedUsersPageState();
}

class _ConnectedUsersPageState extends State<ConnectedUsersPage> {
  bool _showSimpleList = false;
  bool _showTopology = false;
  late final GlobalP2PStore _p2pStore;

  @override
  void initState() {
    super.initState();
    _p2pStore = getIt<GlobalP2PStore>();
  }

  /// 从 KVNodeInfo 的 connType 和 cost 推断中文连接类型
  String _getConnectionType(KVNodeInfo node) {
    if (node.cost == 0) return '本机';
    if (node.cost <= 1 || node.hops.length <= 1) return '直链';
    return '中转';
  }

  /// 从 KVNodeInfo.connections 聚合 txPackets / rxPackets
  int _sumTxPackets(KVNodeInfo node) {
    int total = 0;
    for (final conn in node.connections) {
      total += conn.txPackets.toInt();
    }
    return total;
  }

  int _sumRxPackets(KVNodeInfo node) {
    int total = 0;
    for (final conn in node.connections) {
      total += conn.rxPackets.toInt();
    }
    return total;
  }

  int _getColumnCount(double width) {
    if (width >= 1200) return 3;
    if (width >= 900) return 2;
    return 1;
  }

  Color _getLatencyColor(double latency) {
    if (latency < 50) return Colors.green;
    if (latency < 100) return Colors.orange;
    return Colors.red;
  }

  Color _getPacketLossColor(double lossRate) {
    if (lossRate < 1.0) return Colors.green;
    if (lossRate < 5.0) return Colors.orange;
    return Colors.red;
  }

  Color _getConnectionTypeColor(String type, ColorScheme colorScheme) {
    switch (type) {
      case '中转':
        return Colors.orange;
      case '直链':
        return Colors.green;
      case '本机':
        return colorScheme.primary;
      default:
        return Colors.grey;
    }
  }

  IconData _getConnectionIcon(String type) {
    switch (type) {
      case '中转':
        return Icons.swap_horiz;
      case '直链':
        return Icons.link;
      case '本机':
        return Icons.computer;
      default:
        return Icons.device_unknown;
    }
  }

  Color _getNatTypeColor(String natType) {
    if (natType.contains('开放') ||
        natType.contains('全锥形') ||
        natType.contains('无PAT')) {
      return Colors.green;
    } else if (natType.contains('受限') || natType.contains('端口受限')) {
      return Colors.orange;
    } else if (natType.contains('对称') || natType.contains('防火墙')) {
      return Colors.red;
    }
    return Colors.grey;
  }

  IconData _getNatTypeIcon(String natType) {
    if (natType.contains('开放') || natType.contains('全锥形')) {
      return Icons.public;
    } else if (natType.contains('无PAT')) {
      return Icons.router;
    } else if (natType.contains('受限')) {
      return Icons.shield;
    } else if (natType.contains('端口受限')) {
      return Icons.security;
    } else if (natType.contains('对称')) {
      return Icons.sync_alt;
    } else if (natType.contains('防火墙')) {
      return Icons.fireplace;
    }
    return Icons.help_outline;
  }

  String _formatSpeed(BigInt bytes) {
    final value = bytes.toInt();
    if (value < 1024) return '$value B';
    if (value < 1024 * 1024) return '${(value / 1024).toStringAsFixed(1)} KB';
    if (value < 1024 * 1024 * 1024) {
      return '${(value / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(value / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatTunnelProto(String proto) {
    if (proto == 'tcp') return 'tcp4';
    if (proto == 'udp') return 'udp4';
    return proto;
  }

  /// 详细用户卡片
  Widget _buildDetailedUserCard(KVNodeInfo node, ColorScheme colorScheme) {
    final connType = _getConnectionType(node);
    final latencyColor = _getLatencyColor(node.latencyMs);
    final connTypeColor = _getConnectionTypeColor(connType, colorScheme);
    final connIcon = _getConnectionIcon(connType);
    final natColor = _getNatTypeColor(node.nat);
    final natIcon = _getNatTypeIcon(node.nat);
    final txBytes = node.txBytes;
    final rxBytes = node.rxBytes;
    final txPackets = _sumTxPackets(node);
    final rxPackets = _sumRxPackets(node);
    final displayName = node.hostname.isNotEmpty ? node.hostname : 'Node #${node.peerId}';

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(
          color: Colors.transparent,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          if (node.ipv4.isNotEmpty && node.ipv4 != '0.0.0.0') {
            Clipboard.setData(ClipboardData(text: node.ipv4));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('已复制IP: ${node.ipv4}'),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        splashColor: colorScheme.primary.withValues(alpha: 0.3),
        highlightColor: colorScheme.primary.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.all(12),
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: 名称 + 连接类型 + 延迟 + 丢包
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.person, color: colorScheme.primary, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Tooltip(
                            message: displayName,
                            child: Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Wrap(
                    spacing: 12.0,
                    runSpacing: 4.0,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.end,
                    children: [
                      // 连接类型标签
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: connTypeColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(connIcon, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              connType,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 非本机时显示延迟和丢包
                      if (connType != '本机') ...[
                        Tooltip(
                          message: '延迟',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.timer_outlined, size: 18, color: latencyColor),
                              const SizedBox(width: 4),
                              Text(
                                '${node.latencyMs.toStringAsFixed(0)} ms',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: latencyColor,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Tooltip(
                          message: '丢包率',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline, size: 18, color: _getPacketLossColor(node.lossRate)),
                              const SizedBox(width: 4),
                              Text(
                                '${node.lossRate.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _getPacketLossColor(node.lossRate),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 12),

              // 网络数据
              if (txBytes > BigInt.zero || rxBytes > BigInt.zero)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.wifi, size: 20, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          '网络数据:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 90,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildStatItem(
                                  Icons.upload_rounded,
                                  '累计上传',
                                  _formatSpeed(txBytes),
                                  colorScheme.primary,
                                  colorScheme,
                                ),
                                const SizedBox(height: 10),
                                _buildStatItem(
                                  Icons.arrow_upward_rounded,
                                  '累计发送包',
                                  '$txPackets',
                                  colorScheme.primary,
                                  colorScheme,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildStatItem(
                                  Icons.download_rounded,
                                  '累计下载',
                                  _formatSpeed(rxBytes),
                                  colorScheme.secondary,
                                  colorScheme,
                                ),
                                const SizedBox(height: 10),
                                _buildStatItem(
                                  Icons.arrow_downward_rounded,
                                  '累计接收包',
                                  '$rxPackets',
                                  colorScheme.secondary,
                                  colorScheme,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),

              // IP 地址
              if (node.ipv4.isNotEmpty && node.ipv4 != '0.0.0.0')
                _buildInfoRow(
                  Icons.lan_outlined,
                  'IP地址',
                  node.ipv4,
                  colorScheme,
                  showCopyButton: true,
                ),

              // 版本
              if (node.version.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.info_outline,
                  '版本',
                  node.version,
                  colorScheme,
                ),
              ],

              // NAT 类型
              if (node.nat.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  natIcon,
                  'NAT类型',
                  node.nat,
                  colorScheme,
                  valueColor: natColor,
                ),
              ],

              // 隧道类型
              if (node.tunnelProto.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.router,
                  '隧道类型',
                  _formatTunnelProto(node.tunnelProto),
                  colorScheme,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String label,
    String value,
    Color color,
    ColorScheme colorScheme,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 简洁用户卡片
  Widget _buildSimpleUserCard(KVNodeInfo node, ColorScheme colorScheme) {
    final connType = _getConnectionType(node);
    final latencyColor = _getLatencyColor(node.latencyMs);
    final connTypeColor = _getConnectionTypeColor(connType, colorScheme);
    final displayName = node.hostname.isNotEmpty ? node.hostname : 'Node #${node.peerId}';

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(
          color: Colors.transparent,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          if (node.ipv4.isNotEmpty && node.ipv4 != '0.0.0.0') {
            Clipboard.setData(ClipboardData(text: node.ipv4));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('已复制IP地址: ${node.ipv4}'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 第一行：名称 类型 延迟 丢包
              Row(
                children: [
                  Icon(Icons.person, color: colorScheme.primary, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Tooltip(
                      message: displayName,
                      child: Text(
                        displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 连接类型标签
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: connTypeColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getConnectionIcon(connType), size: 12, color: Colors.white),
                        const SizedBox(width: 3),
                        Text(
                          connType,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 非本机时显示延迟和丢包
                  if (connType != '本机') ...[
                    const SizedBox(width: 10),
                    Icon(Icons.timer_outlined, size: 16, color: latencyColor),
                    Text(
                      '${node.latencyMs.toStringAsFixed(0)}ms',
                      style: TextStyle(
                        color: latencyColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.error_outline, size: 16, color: _getPacketLossColor(node.lossRate)),
                    Text(
                      '${node.lossRate.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: _getPacketLossColor(node.lossRate),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              // 第二行：IP + 版本 + 隧道
              Row(
                children: [
                  if (node.ipv4.isNotEmpty && node.ipv4 != '0.0.0.0') ...[
                    Icon(Icons.lan_outlined, size: 16, color: colorScheme.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Tooltip(
                        message: node.ipv4,
                        child: Text(
                          node.ipv4,
                          style: TextStyle(
                            color: colorScheme.secondary,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ] else
                    const Spacer(),
                  if (node.version.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Icon(Icons.info_outline, size: 16, color: colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      node.version,
                      style: TextStyle(
                        color: colorScheme.secondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  if (node.tunnelProto.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Icon(Icons.router, size: 16, color: colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      _formatTunnelProto(node.tunnelProto),
                      style: TextStyle(
                        color: colorScheme.secondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    ColorScheme colorScheme, {
    Color? valueColor,
    bool showCopyButton = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 12),
        Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        if (showCopyButton)
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: '复制$label',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('已复制IP地址: $value'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? colorScheme.secondary,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'topology_toggle',
            onPressed: () {
              setState(() {
                _showTopology = !_showTopology;
              });
            },
            tooltip: _showTopology ? '列表视图' : '拓扑图',
            child: Icon(_showTopology ? Icons.list : Icons.hub),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'view_toggle',
            onPressed: () {
              setState(() {
                _showSimpleList = !_showSimpleList;
              });
            },
            tooltip: _showSimpleList ? '详细视图' : '简洁视图',
            child: Icon(_showSimpleList ? Icons.view_agenda_outlined : Icons.view_list_outlined),
          ),
        ],
      ),
      body: Watch((context) {
        final status = _p2pStore.networkStatus.value;
        final nodes = status?.nodes ?? [];

        if (nodes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: colorScheme.primary.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 16),
                Text(
                  '房间内暂无成员',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '当前没有其他玩家连接到房间',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          );
        }

        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverMasonryGrid(
                gridDelegate:
                    SliverSimpleGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _getColumnCount(
                    MediaQuery.of(context).size.width,
                  ),
                ),
                mainAxisSpacing: 8.0,
                crossAxisSpacing: 8.0,
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final node = nodes[index];
                    return _showSimpleList
                        ? _buildSimpleUserCard(node, colorScheme)
                        : _buildDetailedUserCard(node, colorScheme);
                  },
                  childCount: nodes.length,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
