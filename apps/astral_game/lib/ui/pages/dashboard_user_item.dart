import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:astral_game/data/services/node_management_service.dart';
import 'package:astral_game/data/models/enhanced_node_info.dart';
import 'package:astral_game/utils/platform_version_parser.dart';

class DashboardUserItem extends StatelessWidget {
  final EnhancedNodeInfo node;
  final NodeManagementService p2pStore;

  const DashboardUserItem({
    super.key,
    required this.node,
    required this.p2pStore,
  });

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      return Builder(
        builder: (context) {
          final colorScheme = Theme.of(context).colorScheme;
          final (platformName, _) = PlatformVersionParser.parsePlatformInfo(
            node.baseInfo.version,
          );
          final versionNumber = PlatformVersionParser.getVersionNumber(
            node.baseInfo.version,
          );

          final shouldFetchAvatar = p2pStore.isValidIp(node.ipv4);
          final ipDisplayText = p2pStore.getNodeIpDisplayText(node.ipv4);

          final bool isDirect =
              node.baseInfo.cost <= 1 || node.baseInfo.hops.length <= 1;

          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildAvatar(colorScheme),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            node.customName != null
                                ? Text(
                                    node.customName!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.onSurface,
                                    ),
                                  )
                                : Text(
                                    '...',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.onSurfaceVariant
                                          .withAlpha(128),
                                    ),
                                  ),
                            if (platformName.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
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
                                    : colorScheme.onSurfaceVariant.withAlpha(
                                        128,
                                      ),
                              ),
                            ),
                            if (isDirect)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withAlpha(200),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '直连',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            if (versionNumber.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Text(
                                  versionNumber,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurfaceVariant
                                        .withAlpha(128),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.tertiaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'ID: ${node.peerId}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onTertiaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${node.baseInfo.latencyMs.round()}ms',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: node.baseInfo.latencyMs < 100
                                    ? Colors.green[600]
                                    : node.baseInfo.latencyMs < 300
                                        ? Colors.yellow[600]
                                        : Colors.red[600],
                              ),
                            ),
                            if (node.baseInfo.lossRate > 0)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Text(
                                  '丢包: ${node.baseInfo.lossRate.toStringAsFixed(1)}%',
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
        },
      );
    });
  }

  Widget _buildAvatar(ColorScheme colorScheme) {
    final size = 36.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.primaryContainer,
        border: Border.all(color: colorScheme.outline, width: 1),
      ),
      child: node.avatar != null
          ? ClipOval(
              child: Image.memory(
                node.avatar!,
                fit: BoxFit.cover,
                width: size,
                height: size,
                gaplessPlayback: true,
              ),
            )
          : Icon(
              Icons.person,
              size: size * 0.5,
              color: colorScheme.onPrimaryContainer,
            ),
    );
  }
}