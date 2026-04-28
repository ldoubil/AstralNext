import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:astral_game/data/services/node_management_service.dart';
import 'package:astral_game/data/models/enhanced_node_info.dart';

class UserAvatarWidget extends StatefulWidget {
  final EnhancedNodeInfo nodeInfo;
  final double size;

  const UserAvatarWidget({super.key, required this.nodeInfo, this.size = 40});

  @override
  State<UserAvatarWidget> createState() => _UserAvatarWidgetState();
}

// 静态缓存，用于存储已经获取过的头像，使用节点 ID 作为键
class _AvatarCache {
  static final Map<int, Uint8List> _cache = {};

  static Uint8List? get(int peerId) {
    return _cache[peerId];
  }

  static void set(int peerId, Uint8List avatar) {
    _cache[peerId] = avatar;
  }

  static bool contains(int peerId) {
    return _cache.containsKey(peerId) &&
        _cache[peerId] != null &&
        _cache[peerId]!.isNotEmpty;
  }
}

class _UserAvatarWidgetState extends State<UserAvatarWidget> {
  Uint8List? _avatar;
  bool _isFetching = false;
  late NodeManagementService _p2pStore;

  @override
  void initState() {
    super.initState();
    _p2pStore = GetIt.I<NodeManagementService>();

    // 检查缓存中是否已经有该节点的头像
    if (_AvatarCache.contains(widget.nodeInfo.peerId)) {
      setState(() {
        _avatar = _AvatarCache.get(widget.nodeInfo.peerId);
      });
    } else {
      _fetchAvatar();
    }
  }

  @override
  void didUpdateWidget(covariant UserAvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nodeInfo.peerId != widget.nodeInfo.peerId) {
      // 检查缓存中是否已经有新节点的头像
      if (_AvatarCache.contains(widget.nodeInfo.peerId)) {
        setState(() {
          _avatar = _AvatarCache.get(widget.nodeInfo.peerId);
        });
      } else {
        _avatar = null;
        _fetchAvatar();
      }
    }
  }

  Future<void> _fetchAvatar() async {
    final ip = widget.nodeInfo.ipv4;
    final hostname = widget.nodeInfo.hostname;

    // 检查是否为有效用户节点（不是服务器节点且IP有效）
    if (!_p2pStore.isValidUserNode(ip, hostname)) {
      setState(() {
        _isFetching = false;
        _avatar = null;
      });
      return;
    }

    // 如果已经有有效的头像数据，不再获取
    if (_avatar != null && _avatar!.isNotEmpty) {
      setState(() {
        _isFetching = false;
      });
      return;
    }

    // 如果正在获取中，不再重复获取
    if (_isFetching) {
      return;
    }

    setState(() {
      _isFetching = true;
    });

    try {
      int port = int.tryParse(hostname) ?? 4924;

      final url = Uri.parse('http://$ip:$port/api/avatar');
      // 增加超时时间，因为图片可能很大
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // 检查响应体大小，避免过大的图片
        final contentLength = response.bodyBytes.length;
        if (contentLength > 0 && contentLength < 5 * 1024 * 1024) {
          // 限制为 5MB
          final avatarBytes = response.bodyBytes;
          // 保存到缓存
          _AvatarCache.set(widget.nodeInfo.peerId, avatarBytes);
          setState(() {
            _avatar = avatarBytes;
            _isFetching = false;
          });
        } else {
          // 图片过大或为空，不保存
          setState(() {
            _isFetching = false;
          });
        }
      } else {
        setState(() {
          _isFetching = false;
        });
      }
    } catch (e) {
      // [UserAvatarWidget] Failed to fetch avatar from ${widget.nodeInfo.hostname}: $e
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
        border: Border.all(color: colorScheme.outline, width: 1),
      ),
      child: _avatar != null
          ? ClipOval(
              child: Image.memory(
                _avatar!,
                fit: BoxFit.cover,
                width: widget.size,
                height: widget.size,
                gaplessPlayback: true, // 避免 GIF 播放时闪烁
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
