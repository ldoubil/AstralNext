import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:astral_game/data/services/global_p2p_store.dart';
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

  @override
  void initState() {
    super.initState();
    _p2pStore = GetIt.I<GlobalP2PStore>();
    _fetchAvatar();
  }

  @override
  void didUpdateWidget(covariant UserAvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nodeInfo.ipv4 != widget.nodeInfo.ipv4) {
      _avatar = null;
      _fetchAvatar();
    }
  }

  Future<void> _fetchAvatar() async {
    final ip = widget.nodeInfo.ipv4;
    
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
      int port = int.tryParse(widget.nodeInfo.hostname) ?? 4924;

      final url = Uri.parse('http://$ip:$port/api/avatar');
      final response = await http.get(url).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        setState(() {
          _avatar = response.bodyBytes;
          _isFetching = false;
        });
      } else {
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
