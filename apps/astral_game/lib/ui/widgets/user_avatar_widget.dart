import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:astral_game/data/services/global_p2p_store.dart';
import 'package:astral_game/data/services/avatar_port_scanner.dart';
import 'package:astral_game/data/models/enhanced_node_info.dart';

class UserAvatarWidget extends StatefulWidget {
  final EnhancedNodeInfo nodeInfo;
  final double size;

  const UserAvatarWidget({
    super.key,
    required this.nodeInfo,
    this.size = 40,
  });

  @override
  State<UserAvatarWidget> createState() => _UserAvatarWidgetState();
}

class _UserAvatarWidgetState extends State<UserAvatarWidget> {
  Uint8List? _avatar;
  bool _isFetching = false;
  late GlobalP2PStore _p2pStore;
  late AvatarPortScanner _portScanner;

  @override
  void initState() {
    super.initState();
    _p2pStore = GetIt.I<GlobalP2PStore>();
    _portScanner = GetIt.I<AvatarPortScanner>();
    _fetchAvatar();
  }

  @override
  void didUpdateWidget(covariant UserAvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当 IP 变化时，重新获取头像
    if (oldWidget.nodeInfo.ipv4 != widget.nodeInfo.ipv4) {
      _avatar = null;
      _fetchAvatar();
    }
  }

  Future<void> _fetchAvatar() async {
    final ip = widget.nodeInfo.ipv4;
    final peerId = widget.nodeInfo.peerId;
    
    // 检查 IP 是否有效
    if (!_p2pStore.isValidIp(ip)) {
      setState(() {
        _isFetching = true;
        _avatar = null;
      });
      return;
    }

    setState(() {
      _isFetching = true;
    });

    try {
      // 从增强节点信息中获取已缓存的端口
      int? port = widget.nodeInfo.avatarPort;
      
      if (port == null) {
        // 扫描端口
        port = await _portScanner.scanPort(ip);
        if (port != null) {
          // 更新到 GlobalP2PStore
          _p2pStore.updateNodeAvatarPort(peerId, port);
        } else {
          setState(() {
            _isFetching = false;
          });
          return;
        }
      }

      // 获取头像
      final url = Uri.parse('http://$ip:$port/api/avatar');
      final response = await http.get(url).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        setState(() {
          _avatar = response.bodyBytes;
          _isFetching = false;
        });
      } else {
        // 如果端口失效，清除缓存
        if (response.statusCode == 404 || response.statusCode == 503) {
          _p2pStore.updateNodeAvatarPort(peerId, 0); // 设置为无效
        }
        setState(() {
          _isFetching = false;
        });
      }
    } catch (e) {
      print('[UserAvatarWidget] Failed to fetch avatar from ${widget.nodeInfo.hostname}: $e');
      setState(() {
        _isFetching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.primaryContainer,
        border: Border.all(
          color: colorScheme.outline,
          width: 1,
        ),
      ),
      child: _avatar != null
          ? ClipOval(
              child: Image.memory(
                _avatar!,
                fit: BoxFit.cover,
                width: widget.size,
                height: widget.size,
              ),
            )
          : _isFetching
              ? SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.onPrimaryContainer,
                    ),
                  ),
                )
              : Icon(
                  Icons.person,
                  size: widget.size * 0.5,
                  color: colorScheme.onPrimaryContainer,
                ),
    );
  }
}
