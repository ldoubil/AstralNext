import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:get_it/get_it.dart';
import 'package:signals/signals_flutter.dart';
import 'package:astral_game/ui/widgets/dashboard_main_card.dart';
import 'package:astral_game/ui/widgets/user_avatar_widget.dart';
import 'package:astral_game/data/services/global_p2p_store.dart';
import 'package:astral_game/data/services/app_settings_service.dart';
import 'package:astral_game/data/services/room_persistence_service.dart';
import 'package:astral_game/ui/pages/rooms/room_mod.dart';
import 'package:astral_game/ui/pages/rooms/room_state.dart';
import 'package:astral_game/ui/pages/servers/server_state.dart';
import 'package:astral_game/utils/platform_version_parser.dart';
import 'package:astral_rust_core/p2p_service.dart';
import 'package:astral_rust_core/src/rust/api/p2p.dart' show KVNodeInfo;

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final GlobalP2PStore _p2pStore = GetIt.I<GlobalP2PStore>();
  final P2PService _p2pService = GetIt.I<P2PService>();
  final AppSettingsService _appSettings = GetIt.I<AppSettingsService>();
  final RoomPersistenceService _roomPersistence = GetIt.I<RoomPersistenceService>();
  bool _isConnecting = false;
  String? _currentRoomUuid;

  void _handleSettings() {
    Navigator.pushNamed(context, '/settings');
  }

  Future<void> _handleShareRoom() async {
    if (_currentRoomUuid != null) {
      await Clipboard.setData(ClipboardData(text: _currentRoomUuid!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('房间号已复制到剪贴板')),
      );
    }
  }

  Future<void> _handleDisconnect() async {
    final instanceId = _p2pStore.instanceId;
    if (instanceId != null) {
      try {
        await _p2pService.closeServer(instanceId);
      } catch (_) {}
    }
    _p2pStore.setStopped();
    roomState.setConnected(false);
    setState(() {
      _currentRoomUuid = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已断开连接')),
    );
  }

  String _generateUuid() {
    final random = Random();
    final values = List<int>.generate(16, (_) => random.nextInt(256));
    values[6] = (values[6] & 0x0F) | 0x40;
    values[8] = (values[8] & 0x3F) | 0x80;
    
    const hex = '0123456789abcdef';
    final buffer = StringBuffer();
    for (int i = 0; i < 16; i++) {
      if (i == 4 || i == 6 || i == 8 || i == 10) {
        buffer.write('-');
      }
      buffer.write(hex[values[i] >> 4]);
      buffer.write(hex[values[i] & 0x0F]);
    }
    return buffer.toString();
  }

  String _escapeString(String s) => s.replaceAll('\\', r'\\').replaceAll('"', r'\"');

  String _buildTomlConfig(String roomName, String roomPassword) {
    final disableP2p = _appSettings.isDisableP2p();
    final serverState = GetIt.I<ServerState>();
    final enabledServers = serverState.getEnabledServers();
    
    String peerBlock = '';
    if (enabledServers.isNotEmpty) {
      peerBlock = enabledServers.map((server) {
        final protocol = server.udp ? 'udp' : server.tcp ? 'tcp' : 'tcp';
        return '[[peer]]\nuri = "${_escapeString("$protocol://${server.url}")}"';
      }).join('\n\n');
    }
    
    return '''
instance_name = "AstralGame"
dhcp = true
listeners = [
    "tcp://0.0.0.0:11010",
    "udp://0.0.0.0:11010",
] 

[network_identity]
network_name = "${_escapeString(roomName)}" 
network_secret = "${_escapeString(roomPassword)}" 

${peerBlock.isNotEmpty ? '$peerBlock\n\n' : ''}[flags]
default_protocol = "tcp"
dev_name = "astral"
disable-p2p = $disableP2p
''';
  }

  Future<void> _connectToRoom(String roomName, String roomPassword) async {
    if (_isConnecting) return;
    
    setState(() {
      _isConnecting = true;
    });

    try {
      final configToml = _buildTomlConfig(roomName, roomPassword);
      debugPrint('连接房间: $roomName');

      final instanceId = await _p2pService.createServer(
        configToml: configToml,
        watchEvent: true,
      );

      final isRunning = await _p2pService.isEasytierRunning(instanceId);
      if (isRunning) {
        _p2pStore.setRunning(instanceId);
        roomState.setConnected(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('连接成功')),
        );
      } else {
        debugPrint('连接失败：实例启动异常');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('连接失败')),
        );
      }
    } catch (e) {
      debugPrint('连接失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('连接失败: $e')),
      );
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  Future<void> _handleCreateRoom() async {
    if (_isConnecting) return;

    final uuid = _generateUuid();
    final roomName = 'Room_${uuid.substring(0, 8)}';
    final roomPassword = uuid;

    final room = RoomMod(
      id: DateTime.now().millisecondsSinceEpoch,
      name: roomName,
      roomName: roomName,
      host: 'localhost',
      port: 11010,
      password: roomPassword,
      uuid: uuid,
      createdAt: DateTime.now(),
    );

    await _roomPersistence.saveRooms([...roomState.rooms, room]);
    await roomState.loadFromPersistence();

    setState(() {
      _currentRoomUuid = uuid;
    });

    await _connectToRoom(roomName, roomPassword);
  }

  Future<void> _handleJoinRoom() async {
    final TextEditingController uuidController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('加入房间'),
        content: TextField(
          controller: uuidController,
          decoration: const InputDecoration(
            labelText: '房间UUID',
            hintText: '请输入房间UUID',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (uuidController.text.isNotEmpty) {
                Navigator.pop(context, uuidController.text.trim());
              }
            },
            child: const Text('加入'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final roomName = 'Room_${result.substring(0, 8)}';
      final roomPassword = result;

      final room = RoomMod(
        id: DateTime.now().millisecondsSinceEpoch,
        name: roomName,
        roomName: roomName,
        host: 'localhost',
        port: 11010,
        password: roomPassword,
        uuid: result,
        createdAt: DateTime.now(),
      );

      await _roomPersistence.saveRooms([...roomState.rooms, room]);
      await roomState.loadFromPersistence();

      setState(() {
        _currentRoomUuid = result;
      });

      await _connectToRoom(roomName, roomPassword);
    }
  }

  void _handleJoinHistory(String uuid) async {
    if (uuid.isEmpty) return;
    final index = roomState.rooms.indexWhere((r) => r.uuid == uuid);
    if (index != -1) {
      final room = roomState.rooms[index];
      setState(() {
        _currentRoomUuid = uuid;
      });
      await _connectToRoom(room.roomName, room.password);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              flex: 6,
              child: _buildLeftPanel(context),
            ),
            Expanded(
              flex: 4,
              child: _buildRightPanel(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftPanel(BuildContext context) {
    return Watch((context) {
      final colorScheme = Theme.of(context).colorScheme;
      final textTheme = Theme.of(context).textTheme;
      final instanceId = _p2pStore.currentInstanceId.value;
      final isRunning = instanceId != null;

      return Container(
        height: double.infinity,
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colorScheme.outline.withAlpha(50)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isRunning ? Icons.people_outlined : Icons.history_outlined,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isRunning ? '在线用户' : '加入历史',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: isRunning ? _buildUserList(context) : _buildJoinHistory(context),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildUserList(BuildContext context) {
    return Watch((context) {
      final status = _p2pStore.networkStatus.value;
      final nodes = status?.nodes ?? [];
      // 只显示有真实 IP 的节点(排除 0.0.0.0)
      final filteredNodes = nodes.where((node) => node.ipv4 != '0.0.0.0').toList();

      debugPrint('[UI] _buildUserList - 总节点数: ${nodes.length}');
      for (var node in nodes) {
        debugPrint('[UI]   节点: ${node.hostname}, IP: ${node.ipv4}, cost: ${node.cost}');
      }
      debugPrint('[UI] _buildUserList - 过滤后节点数: ${filteredNodes.length}');

      return filteredNodes.isEmpty
          ? _buildEmptyUserState(context)
          : _buildNodeList(context, filteredNodes);
    });
  }

  Widget _buildEmptyUserState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            '暂无在线用户',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeList(BuildContext context, List<KVNodeInfo> nodes) {
    return SingleChildScrollView(
      child: Column(
        children: nodes.map((node) => _buildUserItem(node)).toList(),
      ),
    );
  }

  Widget _buildJoinHistory(BuildContext context) {
    return Watch((context) {
      final history = roomState.rooms;

      if (history.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                '暂无加入历史',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '创建或加入房间后会显示在这里',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        );
      }

      return SingleChildScrollView(
        child: Column(
          children: history
              .map((room) => _buildHistoryItem(room))
              .toList(),
        ),
      );
    });
  }

  Widget _buildRightPanel(BuildContext context) {
    return Watch((context) {
      final isConnected = _p2pStore.isRunning;
      final status = _p2pStore.networkStatus.value;
      final virtualIp = status?.nodes.firstOrNull?.ipv4 ?? '10.147.18.24';

      return Container(
        height: double.infinity,
        child: DashboardMainCard(
          isConnected: isConnected,
          username: '玩家',
          virtualIp: virtualIp,
          roomUuid: _currentRoomUuid,
          onSettingsTap: _handleSettings,
          onCreateRoomTap: _handleCreateRoom,
          onJoinRoomTap: _handleJoinRoom,
          onShareRoomTap: _handleShareRoom,
          onDisconnectTap: _handleDisconnect,
        ),
      );
    });
  }

  Widget _buildUserItem(KVNodeInfo node) {
    final colorScheme = Theme.of(context).colorScheme;
    final (platformName, platformIcon) = PlatformVersionParser.parsePlatformInfo(node.version);
    final versionNumber = PlatformVersionParser.getVersionNumber(node.version);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          UserAvatarWidget(
            ip: node.ipv4,
            port: 4924,
            size: 36,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      node.hostname,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    if (platformName.isNotEmpty)
                      Row(
                        children: [
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              platformName,
                              style: TextStyle(
                                fontSize: 10,
                                color: colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      node.ipv4,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (versionNumber.isNotEmpty)
                      Row(
                        children: [
                          const SizedBox(width: 8),
                          Text(
                            versionNumber,
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant.withAlpha(128),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'ID: ${node.peerId}',
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        node.tunnelProto.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${node.latencyMs.round()}ms',
                      style: TextStyle(
                        fontSize: 11,
                        color: node.latencyMs < 100 
                            ? Colors.green[600] 
                            : node.latencyMs < 300 
                                ? Colors.yellow[600] 
                                : Colors.red[600],
                      ),
                    ),
                    if (node.lossRate > 0)
                      Row(
                        children: [
                          const SizedBox(width: 8),
                          Text(
                            '丢包: ${node.lossRate.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.red[600],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(RoomMod room) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    bool isHovered = false;

    return AnimatedBuilder(
      animation: const AlwaysStoppedAnimation(true),
      builder: (context, child) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: room.uuid.isNotEmpty ? () => _handleJoinHistory(room.uuid) : null,
                  onHover: (hovering) {
                    setState(() => isHovered = hovering);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isHovered 
                          ? colorScheme.primaryContainer.withAlpha(20)
                          : Colors.transparent,
                    ),
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
                            Icons.meeting_room_outlined,
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
                                room.name,
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                room.uuid.isNotEmpty 
                                    ? room.uuid.substring(0, 8) + '...' 
                                    : '本地房间',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedOpacity(
                          opacity: isHovered ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.copy_outlined,
                                  size: 18,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                onPressed: room.uuid.isNotEmpty 
                                    ? () async {
                                        await Clipboard.setData(ClipboardData(text: room.uuid));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('房间号已复制')),
                                        );
                                      }
                                    : null,
                                padding: const EdgeInsets.all(6),
                                constraints: const BoxConstraints(),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outlined,
                                  size: 18,
                                  color: colorScheme.error,
                                ),
                                onPressed: () async {
                                  final updatedRooms = roomState.rooms
                                      .where((r) => r.id != room.id)
                                      .toList();
                                  await _roomPersistence.saveRooms(updatedRooms);
                                  await roomState.loadFromPersistence();
                                  if (mounted) {
                                    setState(() {});
                                  }
                                },
                                padding: const EdgeInsets.all(6),
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios_outlined,
                          size: 16,
                          color: colorScheme.onSurfaceVariant.withAlpha(128),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}