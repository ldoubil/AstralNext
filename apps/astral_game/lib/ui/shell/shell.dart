import 'package:astral_game/data/services/screen_state_service.dart';
import 'package:astral_game/di.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../pages/dashboard_page.dart';
import '../pages/servers/servers_main_page.dart';
import '../pages/settings/settings_main_page.dart';
import '../widgets/navigation/bottom_nav.dart';
import '../widgets/navigation/left_nav.dart';
import '../widgets/navigation/navigation_item.dart';
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final screenWidth = MediaQuery.of(context).size.width;
        _screenStateService.updateScreenWidth(screenWidth);
      }
    });
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

  List<NavigationItem> get _navigationItems => [
        NavigationItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home,
          label: '主页',
          page: const DashboardPage(key: PageStorageKey('dashboard')),
        ),
        NavigationItem(
          icon: Icons.dns_outlined,
          activeIcon: Icons.dns,
          label: '服务器',
          page: const ServersMainPage(key: PageStorageKey('servers')),
        ),
        NavigationItem(
          icon: Icons.settings_outlined,
          activeIcon: Icons.settings,
          label: '设置',
          page: const SettingsMainPage(key: PageStorageKey('settings')),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    _screenStateService.updateScreenWidth(screenWidth);

    final isCompact = _screenStateService.isNarrow;

    final hasOverlay = _contentController.hasOverlay;
    final overlayTitle = _contentController.overlayTitle;

    return Scaffold(
      backgroundColor: colorScheme.primaryContainer,
      body: Row(
        children: [
          if (!isCompact)
            LeftNav(
              items: _navigationItems,
              colorScheme: colorScheme,
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
                              children: _navigationItems
                                  .map((item) => item.page)
                                  .toList(),
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
          ? BottomNav(
              navigationItems: _navigationItems,
              colorScheme: colorScheme,
              selectedIndex: _selectedIndex,
              onSelected: _handleDestinationSelected,
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