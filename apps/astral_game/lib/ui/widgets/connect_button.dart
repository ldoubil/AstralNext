import 'dart:math';
import 'package:flutter/material.dart';
import 'package:astral_game/di.dart';
import 'package:astral_game/data/services/global_p2p_store.dart';
import 'package:astral_game/data/services/app_settings_service.dart';
import 'package:astral_rust_core/p2p_service.dart';
import '../pages/rooms/room_state.dart';

enum AppConnectionState {
  idle,
  connecting,
  connected,
}

class ConnectButton extends StatefulWidget {
  const ConnectButton({super.key});

  @override
  State<ConnectButton> createState() => _ConnectButtonState();
}

class _ConnectButtonState extends State<ConnectButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  AppConnectionState _connectionState = AppConnectionState.idle;
  late final dynamic _disposeSelectedRoom;
  late final P2PService _p2pService;
  late final GlobalP2PStore _p2pStore;

  @override
  void initState() {
    super.initState();
    _p2pService = getIt<P2PService>();
    _p2pStore = getIt<GlobalP2PStore>();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _disposeSelectedRoom = roomState.selectedRoom.subscribe((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _disposeSelectedRoom();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleConnection() async {
    final room = roomState.selectedRoom.value;
    if (_connectionState == AppConnectionState.idle) {
      if (room == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('请先在首页选择一个房间'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      setState(() {
        _connectionState = AppConnectionState.connecting;
      });
      await _startConnecting(room);
    } else if (_connectionState == AppConnectionState.connected) {
      await _disconnect();
    }
  }

  String _escapeString(String s) => s.replaceAll('"', r'\"');

  String _buildTomlConfig(dynamic room, String username) {
    final appSettings = getIt<AppSettingsService>();
    final disableP2p = appSettings.isDisableP2p();

    return '''instance_name = "${_escapeString(room.name)}"
hostname = "${_escapeString(username)}"
dhcp = true
listeners = [
    "tcp://0.0.0.0:11010",
    "udp://0.0.0.0:11010",
    "ws://0.0.0.0:11011",
    "wss://0.0.0.0:11012",
]

[network_identity]
network_name = "${_escapeString(room.roomName)}"
network_secret = "${_escapeString(room.password)}"

[[peer]]
#uri = "" #公共节点或自建节点

[flags]
default_protocol = "tcp"
dev_name = "astral"
enable-lan = false
${disableP2p ? 'disable-p2p = true #禁用P2P直连，所有流量经中转' : '#disable-p2p = false'}''';
  }

  Future<void> _startConnecting(dynamic room) async {
    try {
      final username = 'Player'; // TODO: 从用户信息卡片获取
      final configToml = _buildTomlConfig(room, username);

      debugPrint('连接房间: ${room.name}, roomName: ${room.roomName}');

      final instanceId = await _p2pService.createServer(
        configToml: configToml,
        watchEvent: true,
      );

      final isRunning = await _p2pService.isEasytierRunning(instanceId);
      if (isRunning) {
        _p2pStore.setRunning(instanceId);
        roomState.setConnected(true);
        if (mounted) {
          setState(() {
            _connectionState = AppConnectionState.connected;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _connectionState = AppConnectionState.idle;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('连接失败：实例启动异常'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _connectionState = AppConnectionState.idle;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('连接失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _disconnect() async {
    final instanceId = _p2pStore.instanceId;
    if (instanceId != null) {
      try {
        await _p2pService.closeServer(instanceId);
      } catch (_) {}
    }
    _p2pStore.setStopped();
    roomState.setConnected(false);
    setState(() {
      _connectionState = AppConnectionState.idle;
    });
  }

  Widget _getButtonIcon(AppConnectionState state) {
    switch (state) {
      case AppConnectionState.idle:
        return Icon(
          Icons.power_settings_new_rounded,
          key: const ValueKey('idle_icon'),
        );
      case AppConnectionState.connecting:
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _animationController.value * 2 * pi,
              child: const Icon(
                Icons.sync_rounded,
                key: ValueKey('connecting_icon'),
              ),
            );
          },
        );
      case AppConnectionState.connected:
        return Icon(Icons.link_rounded, key: const ValueKey('connected_icon'));
    }
  }

  Widget _getButtonLabel(AppConnectionState state) {
    final String text;
    switch (state) {
      case AppConnectionState.idle:
        text = '连接';
      case AppConnectionState.connecting:
        text = '连接中...';
      case AppConnectionState.connected:
        text = '已连接';
    }

    return Text(
      text,
      key: ValueKey('label_$state'),
      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
    );
  }

  Color _getButtonColor(AppConnectionState state, ColorScheme colorScheme) {
    switch (state) {
      case AppConnectionState.idle:
        return colorScheme.primary;
      case AppConnectionState.connecting:
        return colorScheme.surfaceContainerHighest;
      case AppConnectionState.connected:
        return colorScheme.tertiary;
    }
  }

  Color _getButtonForegroundColor(AppConnectionState state, ColorScheme colorScheme) {
    switch (state) {
      case AppConnectionState.idle:
        return colorScheme.onPrimary;
      case AppConnectionState.connecting:
        return colorScheme.onSurfaceVariant;
      case AppConnectionState.connected:
        return colorScheme.onTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            height: 14,
            width: 180,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 300),
              offset:
                  _connectionState == AppConnectionState.connecting
                      ? Offset.zero
                      : const Offset(0, 1.0),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _connectionState == AppConnectionState.connecting ? 1.0 : 0.0,
                child: Container(
                  width: 180,
                  height: 6,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey(
                      'progress_${_connectionState == AppConnectionState.connecting}',
                    ),
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(seconds: 15),
                    curve: Curves.easeInOut,
                    builder: (context, value, _) {
                      return FractionallySizedBox(
                        widthFactor: value,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.tertiary,
                                colorScheme.primary,
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: _connectionState != AppConnectionState.idle ? 180 : 100,
              height: 60,
              child: FloatingActionButton.extended(
                onPressed:
                    _connectionState == AppConnectionState.connecting
                        ? null
                        : _toggleConnection,
                heroTag: "connect_button",
                extendedPadding: const EdgeInsets.symmetric(horizontal: 2),
                splashColor:
                    _connectionState != AppConnectionState.idle
                        ? colorScheme.onTertiary.withAlpha(51)
                        : colorScheme.onPrimary.withAlpha(51),
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  switchInCurve: Curves.easeInOut,
                  switchOutCurve: Curves.easeInOut,
                  transitionBuilder: (
                    Widget child,
                    Animation<double> animation,
                  ) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: animation,
                        child: child,
                      ),
                    );
                  },
                  child: _getButtonIcon(_connectionState),
                ),
                label: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  switchInCurve: Curves.easeOutQuad,
                  switchOutCurve: Curves.easeInQuad,
                  child: _getButtonLabel(_connectionState),
                ),
                backgroundColor: _getButtonColor(
                  _connectionState,
                  colorScheme,
                ),
                foregroundColor: _getButtonForegroundColor(
                  _connectionState,
                  colorScheme,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
