import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:signals/signals_flutter.dart';
import 'package:astral_game/data/services/global_p2p_store.dart';
import 'package:astral_game/data/models/enhanced_node_info.dart';
import 'package:astral_game/ui/widgets/user_avatar_widget.dart';
import 'package:astral_game/utils/platform_version_parser.dart';

class DashboardUserItem extends StatefulWidget {
  final EnhancedNodeInfo node;
  final GlobalP2PStore p2pStore;

  const DashboardUserItem({
    super.key,
    required this.node,
    required this.p2pStore,
  });

  @override
  State<DashboardUserItem> createState() => _DashboardUserItemState();
}

class _DashboardUserItemState extends State<DashboardUserItem> {
  bool _isHovered = false;
  bool _isFetchingName = false;
  bool _hasFetchedName = false;

  @override
  void initState() {
    super.initState();
    print('[DashboardUserItem] Created widget for peer ${widget.node.peerId}, IP: ${widget.node.ipv4}, Hostname: ${widget.node.hostname}');
    _scheduleFetchUserName();
  }

  void _scheduleFetchUserName() {
    if (widget.p2pStore.isValidIp(widget.node.ipv4)) {
      print('[DashboardUserItem] IP is valid, fetching username immediately for peer ${widget.node.peerId}');
      _fetchUserName();
    } else {
      print('[DashboardUserItem] IP is invalid (${widget.node.ipv4}), scheduling retry for peer ${widget.node.peerId}');
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (!mounted) return;
        _scheduleFetchUserName();
      });
    }
  }

  Future<void> _fetchUserName() async {
    if (_hasFetchedName) {
      print('[DashboardUserItem] User ${widget.node.peerId} already fetched, skipping');
      return;
    }

    setState(() {
      _isFetchingName = true;
    });

    _hasFetchedName = true;

    try {
      int port = int.tryParse(widget.node.hostname) ?? 4924;
      final url = Uri.parse('http://${widget.node.ipv4}:$port/api/user');
      
      print('[DashboardUserItem] Fetching username for peer ${widget.node.peerId} from $url');

      final response = await http.get(url).timeout(const Duration(seconds: 3));

      print('[DashboardUserItem] Response status: ${response.statusCode} for peer ${widget.node.peerId}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final name = data['name'] as String?;
        print('[DashboardUserItem] Received username: "$name" for peer ${widget.node.peerId}');
        
        if (name != null && name.isNotEmpty) {
          widget.p2pStore.updateNodeCustomName(widget.node.peerId, name);
          print('[DashboardUserItem] Updated custom name for peer ${widget.node.peerId}: $name');
        } else {
          print('[DashboardUserItem] Empty or null username for peer ${widget.node.peerId}');
        }
      } else {
        print('[DashboardUserItem] API returned status ${response.statusCode} for peer ${widget.node.peerId}');
      }
    } catch (e) {
      print('[DashboardUserItem] Failed to fetch username for peer ${widget.node.peerId}: $e');
      print('[DashboardUserItem] IP: ${widget.node.ipv4}, Hostname: ${widget.node.hostname}');
    } finally {
      setState(() {
        _isFetchingName = false;
      });
      print('[DashboardUserItem] Finished fetching username for peer ${widget.node.peerId}, isFetching: $_isFetchingName');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      return Builder(builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final (platformName, platformIcon) = PlatformVersionParser.parsePlatformInfo(widget.node.baseInfo.version);
        final versionNumber = PlatformVersionParser.getVersionNumber(widget.node.baseInfo.version);
        
        final shouldFetchAvatar = widget.p2pStore.isValidIp(widget.node.ipv4);
        final ipDisplayText = widget.p2pStore.getNodeIpDisplayText(widget.node.ipv4);

        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: _isHovered 
                  ? colorScheme.surfaceContainerHighest.withAlpha(128)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isHovered 
                    ? colorScheme.outline.withAlpha(50)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                UserAvatarWidget(
                  nodeInfo: widget.node,
                  size: 36,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          widget.node.customName != null
                              ? Text(
                                  widget.node.customName!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSurface,
                                  ),
                                )
                              : _isFetchingName
                                  ? SizedBox(
                                      width: 60,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      '...',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: colorScheme.onSurfaceVariant.withAlpha(128),
                                      ),
                                    ),
                          if (platformName.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  platformName,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            ipDisplayText,
                            style: TextStyle(
                              fontSize: 12,
                              color: shouldFetchAvatar 
                                  ? colorScheme.onSurfaceVariant
                                  : colorScheme.onSurfaceVariant.withAlpha(128),
                            ),
                          ),
                          if (versionNumber.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                versionNumber,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurfaceVariant.withAlpha(128),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'ID: ${widget.node.peerId}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onTertiaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${widget.node.baseInfo.latencyMs.round()}ms',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: widget.node.baseInfo.latencyMs < 100 
                                  ? Colors.green[600] 
                                  : widget.node.baseInfo.latencyMs < 300 
                                      ? Colors.yellow[600] 
                                      : Colors.red[600],
                            ),
                          ),
                          if (widget.node.baseInfo.lossRate > 0)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                '丢包: ${widget.node.baseInfo.lossRate.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.red[600],
                                ),
                              ),
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
          ),
        );
      });
    });
  }
}