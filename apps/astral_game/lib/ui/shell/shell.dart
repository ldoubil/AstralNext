import 'package:astral_game/data/services/screen_state_service.dart';
import 'package:astral_game/di.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../pages/dashboard_page.dart';
import '../pages/servers/servers_main_page.dart';
import '../pages/settings/settings_main_page.dart';
import '../widgets/window_button.dart';
import 'shell_content_controller.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  late final ShellContentController _contentController;
  late final ScreenStateService _screenStateService;

  @override
  void initState() {
    super.initState();
    _contentController = getIt<ShellContentController>();
    _contentController.addListener(_onContentChanged);
    _screenStateService = getIt<ScreenStateService>();
  }

  @override
  void dispose() {
    _contentController.removeListener(_onContentChanged);
    super.dispose();
  }

  void _onContentChanged() {
    setState(() {});
  }

  void _handleDestinationSelected(int index) {
    if (_contentController.hasOverlay) {
      _contentController.closeOverlay();
      return;
    }
    setState(() => _selectedIndex = index);
  }

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _screenStateService.updateScreenWidth(screenWidth);
      }
    });
    
    final isCompact = _screenStateService.isNarrow;

    final hasOverlay = _contentController.hasOverlay;
    final overlayTitle = _contentController.overlayTitle;

    return Scaffold(
      backgroundColor: colorScheme.primaryContainer,
      body: Row(
        children: [
          if (!isCompact)
            _ShellNavigationRail(
              selectedIndex: _selectedIndex,
              onSelected: _handleDestinationSelected,
            ),
          Expanded(
            child: Column(
              children: [
                if (!isCompact)
                  _TitleBar(
                    height: 44,
                    title: hasOverlay ? overlayTitle! : 'Astral Game',
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
                      child: hasOverlay
                          ? AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeIn,
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                              child: KeyedSubtree(
                                key: ValueKey(overlayTitle),
                                child: _contentController.overlayContent!,
                              ),
                            )
                          : IndexedStack(
                              index: _selectedIndex,
                              sizing: StackFit.expand,
                              children: const [
                                DashboardPage(key: PageStorageKey('dashboard')),
                                ServersMainPage(key: PageStorageKey('servers')),
                                SettingsMainPage(key: PageStorageKey('settings')),
                              ],
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
              selectedIndex: _selectedIndex,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              onDestinationSelected: _handleDestinationSelected,
              backgroundColor: colorScheme.primaryContainer,
              indicatorColor: colorScheme.primary,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: '仪表盘',
                ),
                NavigationDestination(
                  icon: Icon(Icons.dns_outlined),
                  selectedIcon: Icon(Icons.dns),
                  label: '服务器',
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
                child: Align(
                  alignment: Alignment.centerLeft,
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
                onTap: () => windowManager.close(),
              ),
            ],
          ),
        ),
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
            label: '仪表盘',
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
            selected: selectedIndex == 0,
            onTap: () => onSelected(0),
          ),
          _RailDestination(
            label: '服务器',
            icon: Icons.dns_outlined,
            selectedIcon: Icons.dns,
            selected: selectedIndex == 1,
            onTap: () => onSelected(1),
          ),
          const Spacer(),
          _RailDestination(
            label: '设置',
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings,
            selected: selectedIndex == 2,
            onTap: () => onSelected(2),
          ),
        ],
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
            icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
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
