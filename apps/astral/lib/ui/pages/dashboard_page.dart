import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:astral/data/services/dashboard_layout_service.dart';
import 'package:astral/data/services/instance_catalog_service.dart';
import 'package:astral/data/services/platform_path_service.dart';
import 'package:astral/data/services/toml_config_service.dart';
import 'package:astral/di.dart';
import 'package:astral/stores/global/global_p2p_store.dart';
import 'package:astral/ui/pages/config_editor_page.dart';
import 'package:astral/ui/pages/dashboard/models/dashboard_layout.dart';
import 'package:astral/ui/pages/instance_peers_page.dart';
import 'package:astral/ui/shell/shell_content_controller.dart';
import 'package:astral/ui/widgets/dashboard_grid.dart';
import 'package:astral_rust_core/p2p_service.dart';
import 'package:astral_rust_core/src/rust/api/p2p.dart' show easytierVersion;
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:signals/signals_flutter.dart';

part 'dashboard/cards/instance_control_card.dart';
part 'dashboard/cards/node_topology_card.dart';
part 'dashboard/cards/connection_stats_card.dart';
part 'dashboard/cards/quote_card.dart';
part 'dashboard/cards/traffic_card.dart';
part 'dashboard/cards/all_peers_card.dart';
part 'dashboard/models/instance_snapshot.dart';
part 'dashboard/widgets/dashboard_card.dart';
part 'dashboard/widgets/page_header.dart';
part 'dashboard/widgets/pill.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _random = Random();
  late final ValueNotifier<int> _chartTick;
  late final InstanceCatalogService _catalogService;
  late final GlobalP2PStore _p2pStore;
  late final P2PService _p2pService;
  late final DashboardLayoutService _layoutService;
  Future<InstanceCatalogSnapshot>? _snapshotFuture;
  InstanceCatalogSnapshot? _cachedSnapshot;
  String? _selectedInstancePath;
  bool _isEditingLayout = false;
  DashboardLayout? _layout;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _chartTick = ValueNotifier<int>(0);
    _catalogService = InstanceCatalogService(
      getIt<PlatformPathService>(),
      getIt<TomlConfigService>(),
    );
    _p2pStore = getIt<GlobalP2PStore>();
    _p2pService = getIt<P2PService>();
    _layoutService = DashboardLayoutService();
    _loadLayout();
    _loadSnapshot();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _chartTick.value++;
    });
  }

  Future<void> _loadLayout() async {
    final layout = await _layoutService.load();
    if (mounted) {
      setState(() => _layout = layout);
    }
  }

  void _saveLayout() async {
    if (_layout == null) return;
    await _layoutService.save(_layout!);
  }

  void _saveLayoutOrder(List<String> orderedIds) async {
    if (_layout == null) return;
    final newWidgets = <DashboardWidgetConfig>[];
    for (int i = 0; i < orderedIds.length; i++) {
      final id = orderedIds[i];
      final existing = _layout!.widgets.where((w) => w.id == id).firstOrNull;
      if (existing != null) {
        newWidgets.add(existing.copyWith(order: i));
      } else {
        newWidgets.add(DashboardWidgetConfig(
          id: id,
          type: id,
          widthSpan: id == 'traffic' ? 4 : 2,
          heightSpan: 1,
          order: i,
        ));
      }
    }
    final newLayout = _layout!.copyWith(widgets: newWidgets);
    await _layoutService.save(newLayout);
    if (mounted) {
      setState(() => _layout = newLayout);
    }
  }

  void _loadSnapshot() {
    setState(() {
      _snapshotFuture = _catalogService.loadSnapshot();
    });
  }

  List<double> _seedTraffic() =>
      List<double>.generate(60, (_) => 20 + _random.nextDouble() * 40);

  List<_NodeSnapshot> _seedNodes(String region, int count) {
    return List<_NodeSnapshot>.generate(count, (index) {
      final isRelay = index.isEven;
      final latency = 18 + _random.nextInt(40);
      final loss = 0.2 + _random.nextDouble() * 1.6;
      return _NodeSnapshot(
        name: '$region-节点${index + 1}',
        ip: '10.${_random.nextInt(200) + 1}.${index + 10}.${20 + index}',
        route: isRelay ? _NodeRouteMode.relay : _NodeRouteMode.punch,
        latencyMs: latency,
        packetLoss: double.parse(loss.toStringAsFixed(2)),
      );
    });
  }

  _InstanceSnapshot _createMockSnapshot(InstanceCatalogItem item, bool isRunning) {
    return _InstanceSnapshot(
      name: item.name,
      isConnected: isRunning,
      virtualIp: '',
      nodeCount: isRunning ? 3 + _random.nextInt(5) : 0,
      nodes: isRunning ? _seedNodes('区域', 3 + _random.nextInt(3)) : [],
      latencyMs: isRunning ? 18 + _random.nextInt(30) : 0,
      stability: isRunning ? 99.0 + _random.nextDouble() * 0.99 : 0,
      throughputGbps: isRunning ? 10 + _random.nextDouble() * 20 : 0,
      uptime: isRunning ? Duration(minutes: _random.nextInt(3600)) : Duration.zero,
      dailyTrafficTb: isRunning ? _random.nextDouble() * 5 : 0,
      trafficData: _seedTraffic(),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
          _showMessage('已停止: ${item.name}');
          return;
        }
      } catch (e) {
        _showMessage('停止失败: $e');
        return;
      }
    }

    _p2pStore.setStarting(item.path, true);

    try {
      final file = File(item.path);
      if (!await file.exists()) {
        _showMessage('配置文件不存在');
        return;
      }

      final configToml = await file.readAsString();

      final instanceId = await _p2pService.createServer(
        configToml: configToml,
        watchEvent: true,
      );

      final isRunning = await _p2pService.isEasytierRunning(instanceId);
      if (isRunning) {
        _p2pStore.setRunning(item.path, instanceId);
        debugPrint('实例已启动: ${item.name}');
        _showMessage('已启动: ${item.name}');
      } else {
        _showMessage('启动失败: 实例未运行');
      }
    } catch (e) {
      print(e);
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
          _loadSnapshot();
        }
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _chartTick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<InstanceCatalogSnapshot>(
      future: _snapshotFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            _cachedSnapshot == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData) {
          _cachedSnapshot = snapshot.data;
        }

        final data = _cachedSnapshot;
        if (data == null || data.items.isEmpty) {
          return _buildEmptyState(context);
        }

        final selectedPath = _selectedInstancePath ?? data.items.first.path;
        final selectedItem = data.items.firstWhere(
          (item) => item.path == selectedPath,
          orElse: () => data.items.first,
        );
        final isRunning = _p2pStore.isRunning(selectedPath);
        final active = _createMockSnapshot(selectedItem, isRunning);
        final instanceMenuItems = data.items.map((item) {
          return _InstanceMenuItem(
            path: item.path,
            name: item.name,
            isRunning: _p2pStore.isRunning(item.path),
          );
        }).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          children: [
            _PageHeader(
              instanceName: selectedItem.name,
              isInstanceRunning: isRunning,
              isEditingLayout: _isEditingLayout,
              instances: instanceMenuItems,
              selectedPath: selectedPath,
              onInstanceSelected: (path) {
                setState(() => _selectedInstancePath = path);
              },
              onEditLayout: () {
                setState(() => _isEditingLayout = !_isEditingLayout);
              },
            ),
            const SizedBox(height: 16),
            DashboardGrid(
              unitWidth: 120,
              unitHeight: 200,
              spacing: 16,
              isEditing: _isEditingLayout,
              onReorder: (orderedIds) {
                _saveLayoutOrder(orderedIds);
              },
              items: [
                DashboardGridItem(
                  id: 'traffic',
                  widthSpan: 4,
                  child: _TrafficCard(
                    key: ValueKey(active.name),
                    instancePath: selectedItem.path,
                    p2pStore: _p2pStore,
                  ),
                ),
                DashboardGridItem(
                  id: 'stats',
                  widthSpan: 2,
                  child: _ConnectionStatsCard(
                    key: ValueKey('${active.name}-stats'),
                    instancePath: selectedItem.path,
                    p2pStore: _p2pStore,
                  ),
                ),
                DashboardGridItem(
                  id: 'all_peers',
                  widthSpan: 2,
                  child: _AllPeersCard(
                    key: ValueKey('peers-$selectedPath'),
                    p2pStore: _p2pStore,
                    selectedInstancePath: selectedPath,
                    onInstanceTap: (path, name) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => InstancePeersPage(
                            instancePath: path,
                            instanceName: name,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                DashboardGridItem(
                  id: 'quote',
                  widthSpan: 2,
                  child: const _QuoteCard(),
                ),
                DashboardGridItem(
                  id: 'control',
                  widthSpan: 2,
                  child: _InstanceControlCard(
                    key: ValueKey('${active.name}-control'),
                    item: selectedItem,
                    p2pStore: _p2pStore,
                    onToggle: () => _toggleRun(selectedItem),
                    onConfig: () => _openConfig(selectedItem),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.dashboard_customize_outlined,
            size: 48,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            '没有可用的实例',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请先在实例页面添加配置',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

