import 'package:astral/data/services/app_settings_service.dart';
import 'package:astral/data/services/tray_service.dart';
import 'package:astral/di.dart';
import 'package:astral/ui/shell/shell_content_controller.dart';
import 'package:astral/ui/shell/shell_navigation_controller.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../pages/configs_page.dart';
import '../pages/dashboard_page.dart';
import '../pages/instances_page.dart';
import '../pages/tools_page.dart';
import '../pages/settings_page.dart';
import '../widgets/window_button.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  late final ShellNavigationController _navController;
  late final ShellContentController _contentController;

  @override
  void initState() {
    super.initState();
    _navController = getIt<ShellNavigationController>();
    _contentController = getIt<ShellContentController>();
    _navController.addListener(_onNavigationChanged);
    _contentController.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _navController.removeListener(_onNavigationChanged);
    _contentController.removeListener(_onContentChanged);
    super.dispose();
  }

  void _onNavigationChanged() {
    _contentController.closeOverlay();
    setState(() {});
  }

  void _onContentChanged() {
    setState(() {});
  }

  void _handleDestinationSelected(int index) {
    _navController.navigateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCompact = MediaQuery.of(context).size.width < 900;
    final selectedIndex = _navController.selectedIndex;
    const pages = [
      DashboardPage(key: PageStorageKey('dashboard')),
      InstancesPage(key: PageStorageKey('instances')),
      ConfigsPage(key: PageStorageKey('configs')),
      ToolsPage(key: PageStorageKey('tools')),
      SettingsPage(key: PageStorageKey('settings')),
    ];

    final hasOverlay = _contentController.hasOverlay;
    final overlayTitle = _contentController.overlayTitle;

    return Scaffold(
      backgroundColor: colorScheme.primaryContainer,
      body: Row(
        children: [
          if (!isCompact)
            _ShellNavigationRail(
              selectedIndex: selectedIndex,
              onSelected: _handleDestinationSelected,
            ),
          Expanded(
            child: Column(
              children: [
                if (!isCompact)
                  _TitleBar(
                    height: 44,
                    title: hasOverlay ? overlayTitle! : 'Astral',
                    showBackButton: hasOverlay,
                    onBack: hasOverlay
                        ? () => _contentController.closeOverlay()
                        : null,
                  ),
                if (isCompact && hasOverlay)
                  _CompactOverlayAppBar(
                    title: overlayTitle!,
                    onBack: () => _contentController.closeOverlay(),
                  ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: isCompact && hasOverlay
                        ? BorderRadius.zero
                        : const BorderRadius.only(
                            topLeft: Radius.circular(18),
                          ),
                    child: Container(
                      color: colorScheme.surface,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                        child: hasOverlay
                            ? _contentController.overlayContent
                            : pages[selectedIndex],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isCompact && !hasOverlay
          ? NavigationBar(
              selectedIndex: selectedIndex,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              onDestinationSelected: _handleDestinationSelected,
              backgroundColor: colorScheme.primaryContainer,
              indicatorColor: colorScheme.primary,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: '面板',
                ),
                NavigationDestination(
                  icon: Icon(Icons.dns_outlined),
                  selectedIcon: Icon(Icons.dns),
                  label: '实例',
                ),
                NavigationDestination(
                  icon: Icon(Icons.tune_outlined),
                  selectedIcon: Icon(Icons.tune),
                  label: '配置',
                ),
                NavigationDestination(
                  icon: Icon(Icons.build_outlined),
                  selectedIcon: Icon(Icons.build),
                  label: '工具',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: '设置',
                ),
              ],
            )
          : null,
    );
  }
}

class _TitleBar extends StatefulWidget {
  final double height;
  final String title;
  final bool showBackButton;
  final VoidCallback? onBack;

  const _TitleBar({
    required this.height,
    required this.title,
    this.showBackButton = false,
    this.onBack,
  });

  @override
  State<_TitleBar> createState() => _TitleBarState();
}

class _TitleBarState extends State<_TitleBar> {
  bool _isMaximized = false;

  void _toggleMaximize() async {
    if (_isMaximized) {
      await windowManager.restore();
      setState(() => _isMaximized = false);
    } else {
      await windowManager.maximize();
      setState(() => _isMaximized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      child: SizedBox(
        height: widget.height,
        child: Container(
          color: colorScheme.primaryContainer,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              if (widget.showBackButton)
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                  onPressed: widget.onBack,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                )
              else
                const SizedBox(width: 36),
              Expanded(
                child: Center(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 36),
              WindowButton(
                icon: Icons.remove,
                iconSize: 16,
                hoverColor: colorScheme.primary.withValues(alpha: 0.12),
                iconColor: colorScheme.onPrimaryContainer,
                onTap: () => windowManager.minimize(),
              ),
              WindowButton(
                icon: _isMaximized ? Icons.filter_none : Icons.crop_square,
                iconSize: _isMaximized ? 14 : 14,
                hoverColor: colorScheme.primary.withValues(alpha: 0.12),
                iconColor: colorScheme.onPrimaryContainer,
                onTap: _toggleMaximize,
              ),
              WindowButton(
                icon: Icons.close,
                iconSize: 16,
                hoverColor: colorScheme.errorContainer,
                iconColor: colorScheme.onPrimaryContainer,
                onTap: () {
                  final settings = getIt<AppSettingsService>();
                  if (settings.getCloseBehavior() == CloseBehavior.minimizeToTray) {
                    getIt<TrayService>().minimizeToTray();
                  } else {
                    getIt<TrayService>().exitApp();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactOverlayAppBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _CompactOverlayAppBar({
    required this.title,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 56,
      color: colorScheme.surface,
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: colorScheme.onSurface,
            ),
            onPressed: onBack,
          ),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

class _ShellNavigationRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _ShellNavigationRail({
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const railWidth = 92.0;

    return Container(
      width: railWidth,
      color: colorScheme.primaryContainer,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          const _BrandBadge(),
          const SizedBox(height: 12),
          _RailDestination(
            label: '面板',
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
            selected: selectedIndex == 0,
            onTap: () => onSelected(0),
          ),
          _RailDestination(
            label: '实例',
            icon: Icons.dns_outlined,
            selectedIcon: Icons.dns,
            selected: selectedIndex == 1,
            onTap: () => onSelected(1),
          ),
          _RailDestination(
            label: '配置',
            icon: Icons.tune_outlined,
            selectedIcon: Icons.tune,
            selected: selectedIndex == 2,
            onTap: () => onSelected(2),
          ),
          _RailDestination(
            label: '工具',
            icon: Icons.build_outlined,
            selectedIcon: Icons.build,
            selected: selectedIndex == 3,
            onTap: () => onSelected(3),
          ),
          const Spacer(),
          _RailDestination(
            label: '设置',
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings,
            selected: selectedIndex == 4,
            onTap: () => onSelected(4),
          ),
        ],
      ),
    );
  }
}

class _BrandBadge extends StatelessWidget {
  const _BrandBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/logo.png',
        fit: BoxFit.cover,
      ),
    );
  }
}

class _RailDestination extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  const _RailDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = selected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onPrimaryContainer.withValues(alpha: 0.72);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? colorScheme.primary.withValues(alpha: 0.18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(selected ? selectedIcon : icon, color: foreground),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
