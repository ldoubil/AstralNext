import 'dart:async';
import 'dart:io';

import 'package:astral/data/services/instance_catalog_service.dart';
import 'package:astral/data/services/log_service.dart';
import 'package:astral/data/services/platform_path_service.dart';
import 'package:astral/data/services/toml_config_service.dart';
import 'package:astral/di.dart';
import 'package:astral/stores/global/global_p2p_store.dart';
import 'package:astral/ui/pages/config_editor_page.dart';
import 'package:astral/ui/pages/instance_logs_page.dart';
import 'package:astral/ui/pages/instance_peers_page.dart';
import 'package:astral/ui/shell/shell_content_controller.dart';
import 'package:astral/ui/shell/shell_navigation_controller.dart';
import 'package:astral_rust_core/p2p_service.dart';
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

class InstancesPage extends StatefulWidget {
  const InstancesPage({super.key});

  @override
  State<InstancesPage> createState() => _InstancesPageState();
}

class _InstancesPageState extends State<InstancesPage> {
  static const _module = 'InstancesPage';

  late final InstanceCatalogService _catalogService;
  late final P2PService _p2pService;
  late final GlobalP2PStore _p2pStore;
  late final LogService _log;
  Future<InstanceCatalogSnapshot>? _snapshotFuture;
  InstanceCatalogSnapshot? _cachedSnapshot;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _catalogService = InstanceCatalogService(
      getIt<PlatformPathService>(),
      getIt<TomlConfigService>(),
    );
    _p2pService = getIt<P2PService>();
    _p2pStore = getIt<GlobalP2PStore>();
    _log = getIt<LogService>();
    _reload();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _snapshotFuture = _catalogService.loadSnapshot();
    });
  }

  Future<void> _refresh() async {
    final future = _catalogService.loadSnapshot();
    setState(() {
      _snapshotFuture = future;
    });
    await future;
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggleRun(InstanceCatalogItem item) async {
    if (_p2pStore.startingPaths.value.contains(item.path)) return;

    final existingId = _p2pStore.instanceIdByPath.value[item.path];
    if (existingId != null) {
      try {
        final isRunning = await _p2pService.isEasytierRunning(existingId);
        if (isRunning) {
          await _p2pService.closeServer(existingId);
          _p2pStore.setStopped(item.path);
          _log.info(_module, '实例已停止: ${item.name}', instancePath: item.path);
          _showMessage('已停止: ${item.name}');
          return;
        }
      } catch (e) {
        _log.error(_module, '停止实例失败: $e', instancePath: item.path);
        _showMessage('停止失败: $e');
        return;
      }
    }

    _p2pStore.setStarting(item.path, true);
    _log.info(_module, '正在启动实例: ${item.name}', instancePath: item.path);

    try {
      final file = File(item.path);
      if (!await file.exists()) {
        _log.error(_module, '配置文件不存在', instancePath: item.path);
        _showMessage('配置文件不存在');
        return;
      }

      final configToml = await file.readAsString();

      final instanceId = await _p2pService.createServer(
        configToml: configToml,
        watchEvent: false,
      );

      final isRunning = await _p2pService.isEasytierRunning(instanceId);
      if (isRunning) {
        _p2pStore.setRunning(item.path, instanceId);
        _log.info(_module, '实例启动成功: ${item.name} (ID: $instanceId)', instancePath: item.path);
        _showMessage('已启动: ${item.name}');
      } else {
        _log.error(_module, '实例启动失败: 未运行', instancePath: item.path);
        _showMessage('启动失败: 实例未运行');
      }
    } catch (e, s) {
      _log.error(_module, '启动异常: $e', instancePath: item.path);
      print('堆栈: $s');
      _showMessage('启动失败: $e');
    } finally {
      _p2pStore.setStarting(item.path, false);
    }
  }

  Future<void> _openConfig(InstanceCatalogItem item) async {
    final controller = getIt<ShellContentController>();
    controller.showOverlay(
      content: ConfigEditorPage(path: item.path),
      title: item.fileName,
      onClose: () {
        if (mounted) {
          _reload();
        }
      },
    );
  }

  void _openLogs(InstanceCatalogItem item) {
    final controller = getIt<ShellContentController>();
    controller.showOverlay(
      content: InstanceLogsPage(
        instancePath: item.path,
        instanceName: item.name,
      ),
      title: '${item.name} - 运行日志',
    );
  }

  String _formatUptime(DateTime startedAt) {
    final duration = DateTime.now().difference(startedAt);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    }
    return '${minutes}m ${seconds}s';
  }

  int _resolveColumns(double width) {
    if (width >= 1400) {
      return 4;
    }
    if (width >= 1000) {
      return 3;
    }
    if (width >= 680) {
      return 2;
    }
    return 1;
  }

  Widget _buildCard(BuildContext context, InstanceCatalogItem item) {
    return Watch((context) {
      final startedAt = _p2pStore.startTimeByPath.value[item.path];
      final isRunning = startedAt != null;
      final isStarting = _p2pStore.startingPaths.value.contains(item.path);

      return _InstanceCard(
        item: item,
        isRunning: isRunning,
        isStarting: isStarting,
        runningTime: isRunning ? _formatUptime(startedAt) : null,
        onToggleRun: () => _toggleRun(item),
        onOpenConfig: () => _openConfig(item),
        onOpenLogs: () => _openLogs(item),
        onOpenPeers: isRunning
            ? () {
                final controller = getIt<ShellContentController>();
                controller.showOverlay(
                  content: InstancePeersPage(
                    instancePath: item.path,
                    instanceName: item.name,
                  ),
                  title: '${item.name} - 节点信息',
                );
              }
            : null,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<InstanceCatalogSnapshot>(
      future: _snapshotFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            _cachedSnapshot == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError && _cachedSnapshot == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '加载失败: ${snapshot.error}',
                  style: TextStyle(color: colorScheme.error),
                ),
                const SizedBox(height: 12),
                FilledButton(onPressed: _reload, child: const Text('重试')),
              ],
            ),
          );
        }

        if (snapshot.hasData) {
          _cachedSnapshot = snapshot.data;
        }
        final data = snapshot.data ?? _cachedSnapshot;
        if (data == null) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '实例',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${data.items.length} 个实例',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: '刷新',
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: data.items.isEmpty
                      ? ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            const SizedBox(height: 140),
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 36,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                '还没有实例配置。',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: FilledButton.icon(
                                onPressed: () {
                                  getIt<ShellNavigationController>().navigateTo(2);
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('前往配置页面添加'),
                              ),
                            ),
                          ],
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            const spacing = 10.0;
                            final columns = _resolveColumns(
                              constraints.maxWidth,
                            );
                            final tileWidth =
                                (constraints.maxWidth -
                                    (columns - 1) * spacing) /
                                columns;
                            final ratio = (tileWidth / 120).clamp(2.1, 6.0);

                            return GridView.builder(
                              padding: EdgeInsets.zero,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    mainAxisSpacing: spacing,
                                    crossAxisSpacing: spacing,
                                    childAspectRatio: ratio,
                                  ),
                              itemCount: data.items.length,
                              itemBuilder: (context, index) {
                                return _buildCard(context, data.items[index]);
                              },
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InstanceCard extends StatefulWidget {
  final InstanceCatalogItem item;
  final VoidCallback? onToggleRun;
  final VoidCallback? onOpenConfig;
  final VoidCallback? onOpenLogs;
  final VoidCallback? onOpenPeers;
  final bool isRunning;
  final bool isStarting;
  final String? runningTime;

  const _InstanceCard({
    required this.item,
    this.onToggleRun,
    this.onOpenConfig,
    this.onOpenLogs,
    this.onOpenPeers,
    this.isRunning = false,
    this.isStarting = false,
    this.runningTime,
  });

  @override
  State<_InstanceCard> createState() => _InstanceCardState();
}

class _InstanceCardState extends State<_InstanceCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = widget.isRunning
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isRunning && widget.onOpenPeers != null
              ? widget.onOpenPeers
              : null,
          borderRadius: BorderRadius.circular(20),
          child: Card(
            margin: EdgeInsets.zero,
            elevation: widget.isRunning ? 1 : 0,
            color: widget.isRunning
                ? colorScheme.primaryContainer.withValues(alpha: 0.30)
                : colorScheme.surfaceContainerLow,
            surfaceTintColor: colorScheme.surfaceTint,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: (_isHovered || widget.isRunning)
                    ? colorScheme.primary.withValues(alpha: 0.45)
                    : colorScheme.outlineVariant.withValues(alpha: 0),
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.developer_board_rounded,
                        color: colorScheme.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                      if (widget.isRunning)
                        Icon(
                          Icons.chevron_right,
                          color: colorScheme.onSurfaceVariant,
                          size: 18,
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.item.relativePath,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.circle, size: 8, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        widget.isRunning ? '运行中' : '未运行',
                        style: TextStyle(color: statusColor, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.isStarting
                              ? '正在启动...'
                              : widget.isRunning
                                  ? '运行时长 ${widget.runningTime ?? ''}'
                                  : '可直接启动',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: widget.onOpenConfig,
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        icon: const Icon(Icons.tune, size: 18),
                        label: const Text('配置'),
                      ),
                      const SizedBox(width: 6),
                      OutlinedButton.icon(
                        onPressed: widget.onOpenLogs,
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        icon: const Icon(Icons.article_outlined, size: 18),
                        label: const Text('日志'),
                      ),
                      const SizedBox(width: 6),
                      FilledButton.tonalIcon(
                        onPressed: widget.isStarting ? null : widget.onToggleRun,
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        icon: widget.isStarting
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                widget.isRunning
                                    ? Icons.stop_circle_outlined
                                    : Icons.play_circle_outlined,
                              ),
                        label: Text(widget.isStarting
                            ? '启动中'
                            : (widget.isRunning ? '停止' : '启动')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
