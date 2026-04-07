
import 'package:flutter/material.dart';
import 'dashboard_card.dart';
import 'canvas_jump.dart';
import '../pages/rooms/room_state.dart';

class UserInfoCard extends StatefulWidget {
  const UserInfoCard({super.key});

  @override
  State<UserInfoCard> createState() => _UserInfoCardState();
}

class _UserInfoCardState extends State<UserInfoCard> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _virtualIPController = TextEditingController();
  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _virtualIPFocusNode = FocusNode();

  bool _isDhcp = true;
  bool _isValidIP = true;
  late final dynamic _disposeSelectedRoom;
  late final dynamic _disposeIsConnected;

  bool get _isConnected => roomState.isConnected.value;

  @override
  void initState() {
    super.initState();
    _disposeSelectedRoom = roomState.selectedRoom.subscribe((_) {
      if (mounted) setState(() {});
    });
    _disposeIsConnected = roomState.isConnected.subscribe((_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _usernameController.text = '玩家';
      _virtualIPController.text = '10.147.18.24';
      _isValidIP = _isValidIPv4(_virtualIPController.text);
    });
  }

  @override
  void dispose() {
    _disposeSelectedRoom();
    _disposeIsConnected();
    _usernameController.dispose();
    _virtualIPController.dispose();
    _usernameFocusNode.dispose();
    _virtualIPFocusNode.dispose();
    super.dispose();
  }

  bool _isValidIPv4(String ip) {
    final parts = ip.split('/');
    if (parts.length > 2) return false;

    final ipPart = parts[0];
    if (ipPart.isEmpty) return false;

    final octets = ipPart.split('.');
    if (octets.length != 4) return false;

    for (final octet in octets) {
      try {
        final value = int.parse(octet);
        if (value < 0 || value > 255) return false;
      } catch (e) {
        return false;
      }
    }

    if (parts.length == 2) {
      final maskPart = parts[1];
      if (maskPart.isEmpty) return false;
      try {
        final mask = int.parse(maskPart);
        if (mask < 0 || mask > 32) return false;
      } catch (e) {
        return false;
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DashboardCard(
      widthSpan: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: colorScheme.primary, size: 22),
              const SizedBox(width: 8),
              const Text(
                '用户信息',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
              ),
              const Spacer(),
              if (_isConnected)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '已锁定',
                    style: TextStyle(
                      color: colorScheme.onSecondaryContainer,
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _usernameController,
            focusNode: _usernameFocusNode,
            enabled: !_isConnected,
            onChanged: (value) {},
            decoration: InputDecoration(
              labelText: '用户名',
              hintText: '请输入您的用户名',
              border: const OutlineInputBorder(),
              prefixIcon: Icon(Icons.person, color: colorScheme.primary),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 12,
              ),
            ),
          ),

          const SizedBox(height: 14),

          InkWell(
            onTap: !_isConnected
                ? () => CanvasJump.show(
                      context,
                      onSelect: (room) {
                        roomState.selectRoom(room);
                      },
                    )
                : null,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: '选择房间',
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 12,
                ),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                enabled: !_isConnected,
                border: const OutlineInputBorder(),
                prefixIcon: Icon(Icons.apartment, color: colorScheme.primary),
                suffixIcon: roomState.selectedRoom.value != null
                    ? Icon(Icons.check_circle, color: colorScheme.primary)
                    : Icon(Icons.menu, color: colorScheme.primary),
              ),
              child: IgnorePointer(
                ignoring: _isConnected,
                child: Text(
                  roomState.selectedRoom.value?.name ?? '请选择房间',
                  style: TextStyle(
                    color: !_isConnected
                        ? Theme.of(context).textTheme.bodyLarge?.color
                        : Theme.of(context).disabledColor,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 9),

          SizedBox(
            height: 60,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _virtualIPController,
                    focusNode: _virtualIPFocusNode,
                    enabled: !_isDhcp && !_isConnected,
                    onChanged: (value) {
                      if (!_isDhcp) {
                        setState(() {
                          _isValidIP = _isValidIPv4(value);
                        });
                      }
                    },
                    decoration: InputDecoration(
                      labelText: '虚拟网络 IP',
                      hintText: '10.147.xxx.xxx',
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lan, color: colorScheme.primary),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                      errorText:
                          (!_isDhcp && !_isValidIP) ? '无效的 IPv4 地址' : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Switch(
                      value: _isDhcp,
                      onChanged: (value) {
                        if (!_isConnected) {
                          setState(() {
                            _isDhcp = value;
                          });
                        }
                      },
                    ),
                    Text(
                      _isDhcp ? '自动' : '手动',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (_isDhcp)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'IP 地址将由服务器自动分配',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            const SizedBox(height: 12),
        ],
      ),
    );
  }
}

