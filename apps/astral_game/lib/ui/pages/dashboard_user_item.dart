import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:astral_game/config/constants.dart';
import 'package:astral_game/data/models/enhanced_node_info.dart';
import 'package:astral_game/utils/platform_version_parser.dart';

class DashboardUserItem extends StatefulWidget {
  final EnhancedNodeInfo node;

  const DashboardUserItem({
    super.key,
    required this.node,
  });

  @override
  State<DashboardUserItem> createState() => _DashboardUserItemState();
}

class _DashboardUserItemState extends State<DashboardUserItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Watch(
      (context) {
        final node = widget.node;
        final hasIpv4 = node.hasValidIpv4;
        final ipDisplayText = hasIpv4 ? node.ipv4 : '未分配 IP';
        final isDirect = node.baseInfo.cost <= 1 || node.baseInfo.hops.length <= 1;
        final (platformName, _) = PlatformVersionParser.parsePlatformInfo(node.baseInfo.version);
        final versionNumber = PlatformVersionParser.getVersionNumber(node.baseInfo.version);

        return _buildContent(
          context,
          node,
          platformName,
          versionNumber,
          hasIpv4,
          ipDisplayText,
          isDirect,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    EnhancedNodeInfo node,
    String platformName,
    String versionNumber,
    bool hasIpv4,
    String ipDisplayText,
    bool isDirect,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

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
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
              : Colors.transparent,
          borderRadius: AppRadius.brMedium,
          border: Border.all(
            color: _isHovered ? colorScheme.outline.withValues(alpha: 0.2) : Colors.transparent,
            width: 1,
          ),
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
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                              ),
                            ),
                      if (platformName.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.secondaryContainer,
                              borderRadius: AppRadius.brSmall,
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
                          color: hasIpv4
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      if (isDirect)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.online,
                              borderRadius: AppRadius.brSmall,
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
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
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
                          borderRadius: AppRadius.brSmall,
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
                              ? AppColors.online
                              : node.baseInfo.latencyMs < 300
                                  ? AppColors.warning
                                  : AppColors.error,
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
                              color: AppColors.error,
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
      child: widget.node.avatar != null
          ? ClipOval(
              child: Image.memory(
                widget.node.avatar!,
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