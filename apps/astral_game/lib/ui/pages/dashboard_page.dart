import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:get_it/get_it.dart';
import 'package:signals/signals_flutter.dart';
import 'package:astral_game/di.dart';
import 'package:astral_game/data/services/node_management_service.dart';
import 'package:astral_game/data/services/connection_service.dart';
import 'package:astral_game/data/services/screen_state_service.dart';
import 'package:astral_game/data/state/room_state.dart';
import 'package:astral_game/data/models/room_mod.dart';
import 'package:astral_game/ui/pages/dashboard_wide_layout.dart';
import 'package:astral_game/ui/pages/dashboard_narrow_layout.dart';
import 'package:astral_game/ui/widgets/avatar_widget.dart';
import 'package:astral_game/utils/image_picker_helper.dart';

/// 仪表盘页面
///
/// 显示网络状态、在线用户和房间历史
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final NodeManagementService _nodeManagement = GetIt.I<NodeManagementService>();
  final ConnectionService _connectionService = GetIt.I<ConnectionService>();
  final ScreenStateService _screenStateService = GetIt.I<ScreenStateService>();
  final RoomState _roomState = getIt<RoomState>();
  
  String? _currentRoomShareCode;

  Future<bool> _confirmMismatchIfNeeded(String shareCode) async {
    final mismatch = _connectionService.serverFingerprintMismatchMessage(shareCode);
    if (mismatch == null || mismatch.isEmpty || !mounted) return true;

    final shouldContinue = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('服务器配置不一致'),
        content: Text(
          '$mismatch\n\n继续加入可能导致无法连接或延迟异常。是否仍要继续加入？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('继续加入'),
          ),
        ],
      ),
    );
    return shouldContinue == true;
  }

  /// 处理设置按钮点击
  void _handleSettings() {
    _showEditProfileDialog();
  }

  Future<void> _showEditProfileDialog() async {
    if (!mounted) return;

    final nameController = TextEditingController(
      text: _nodeManagement.currentUsername.value,
    );
    var avatar = _nodeManagement.currentUserAvatar.value;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('编辑资料'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final bytes = await ImagePickerHelper.pickImageFromGallery();
                      if (bytes == null) return;
                      setState(() => avatar = bytes);
                    },
                    child: AvatarWidget(
                      avatar: avatar,
                      size: 72,
                      shape: AvatarShape.circle,
                      borderWidth: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: '昵称',
                      hintText: '请输入昵称',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () async {
                    // 清空头像：长按头像更直观，这里先给个入口
                    await _nodeManagement.updateCurrentUserAvatar(null);
                    if (mounted) Navigator.pop(context, true);
                  },
                  child: const Text('清除头像'),
                ),
                FilledButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isNotEmpty) {
                      await _nodeManagement.updateCurrentUsername(name);
                    }
                    await _nodeManagement.updateCurrentUserAvatar(avatar);
                    if (mounted) Navigator.pop(context, true);
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('资料已更新')),
      );
    }
  }

  /// 处理分享房间
  Future<void> _handleShareRoom() async {
    if (_currentRoomShareCode != null) {
      await Clipboard.setData(ClipboardData(text: _currentRoomShareCode!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('房间号已复制到剪贴板')),
        );
      }
    }
  }

  /// 处理断开连接
  Future<void> _handleDisconnect() async {
    await _connectionService.disconnect();
    setState(() {
      _currentRoomShareCode = null;
    });
  }

  /// 处理创建房间
  Future<void> _handleCreateRoom() async {
    if (_connectionService.isConnecting) return;

    final TextEditingController nameController = TextEditingController();

    final roomName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建房间'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: '房间名（必填）',
            hintText: '例如：周五开黑 / 1号桌',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final v = nameController.text.trim();
              if (v.isNotEmpty) Navigator.pop(context, v);
            },
            child: const Text('创建并连接'),
          ),
        ],
      ),
    );

    if (roomName == null || roomName.trim().isEmpty) return;

    final room = await _connectionService.createRoom(roomName: roomName.trim());
    setState(() {
      _currentRoomShareCode = room.shareCode;
    });

    final success = await _connectionService.connectToRoom(room.roomName, room.password);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('连接失败，请重试')),
      );
    }
  }

  /// 处理加入房间
  Future<void> _handleJoinRoom() async {
    if (_connectionService.isConnecting) return;

    final TextEditingController uuidController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('加入房间'),
        content: TextField(
          controller: uuidController,
          decoration: const InputDecoration(
            labelText: '房间分享码',
            hintText: '例如：8位指纹-10位token-房间名（也兼容旧格式）',
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
      final ok = await _confirmMismatchIfNeeded(result);
      if (!ok) return;

      final room = await _connectionService.joinRoom(result);
      setState(() {
        _currentRoomShareCode = room.shareCode;
      });

      final success = await _connectionService.connectToRoom(room.roomName, room.password);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('连接失败，请重试')),
        );
      }
    }
  }

  /// 处理从历史记录加入房间
  void _handleJoinHistory(String shareCode) async {
    if (shareCode.isEmpty || _connectionService.isConnecting) return;
    
    final index = _roomState.rooms.indexWhere((r) => r.shareCode == shareCode);
    if (index != -1) {
      final room = _roomState.rooms[index];
      final ok = await _confirmMismatchIfNeeded(shareCode);
      if (!ok) return;

      setState(() {
        _currentRoomShareCode = shareCode;
      });
      
      final success = await _connectionService.connectToRoom(room.roomName, room.password);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('连接失败，请重试')),
        );
      }
    }
  }

  /// 处理移除房间
  void _handleRemoveRoom(RoomMod room) {
    _connectionService.removeRoom(room.id);
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final isNarrow = _screenStateService.isNarrow;

      return Scaffold(
        body: isNarrow
            ? DashboardNarrowLayout(
                nodeManagement: _nodeManagement,
                connectionService: _connectionService,
                currentRoomShareCode: _currentRoomShareCode,
                onSettings: _handleSettings,
                onCreateRoom: _handleCreateRoom,
                onJoinRoom: _handleJoinRoom,
                onShareRoom: _handleShareRoom,
                onDisconnect: _handleDisconnect,
                onRemoveRoom: _handleRemoveRoom,
                onJoinHistory: _handleJoinHistory,
              )
            : Padding(
                padding: const EdgeInsets.all(16),
                child: DashboardWideLayout(
                  nodeManagement: _nodeManagement,
                  connectionService: _connectionService,
                  screenStateService: _screenStateService,
                  currentRoomShareCode: _currentRoomShareCode,
                  onSettings: _handleSettings,
                  onCreateRoom: _handleCreateRoom,
                  onJoinRoom: _handleJoinRoom,
                  onShareRoom: _handleShareRoom,
                  onDisconnect: _handleDisconnect,
                  onJoinHistory: _handleJoinHistory,
                ),
              ),
      );
    });
  }
}
