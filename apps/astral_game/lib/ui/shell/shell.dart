import 'dart:async';
import 'dart:io';

import 'package:astral_game/data/services/screen_state_service.dart';
import 'package:astral_game/data/services/update_service.dart';
import 'package:astral_game/data/state/settings_state.dart';
import 'package:astral_game/data/state/update_state.dart';
import 'package:astral_game/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:tray_manager/tray_manager.dart';
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

class _ShellState extends State<Shell> with WindowListener, TrayListener {
  late final ShellContentController _contentController;
  late final ScreenStateService _screenStateService;
  late final List<NavigationItem> _navigationItems;
  final TrayManager _trayManager = TrayManager.instance;

  @override
  void initState() {
    super.initState();
    _contentController = getIt<ShellContentController>();
    _contentController.addListener(_onContentChanged);
    _screenStateService = getIt<ScreenStateService>();

    _navigationItems = [
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final screenWidth = MediaQuery.of(context).size.width;
        _screenStateService.updateScreenWidth(screenWidth);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final updateState = getIt<UpdateState>();
        if (updateState.autoCheckUpdate.value) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              getIt<UpdateService>().checkForUpdates(
                context,
                showNoUpdateMessage: false,
                showFailureMessage: false,
              );
            }
          });
        }
      }
    });

    _setupDesktopCloseBehavior();
  }

  @override
  void dispose() {
    if (_isDesktopPlatform) {
      windowManager.removeListener(this);
      _trayManager.removeListener(this);
    }
    _contentController.removeListener(_onContentChanged);
    super.dispose();
  }

  void _onContentChanged() {
    setState(() {});
  }

  bool get _isDesktopPlatform =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  Future<void> _setupDesktopCloseBehavior() async {
    if (!_isDesktopPlatform) return;

    windowManager.addListener(this);
    _trayManager.addListener(this);
    await windowManager.setPreventClose(true);
    await _initTray();
  }

  Future<void> _initTray() async {
    // tray_manager 需要“文件路径”，直接传 asset 路径在 Windows 上常见会无图标。
    // 旧版在 Windows 使用 .ico；这里优先尝试 .ico，否则回退到从 asset 导出 png。
    final String iconPath;
    if (Platform.isWindows) {
      iconPath = await _ensureTrayIconFile(
        preferredAssetPath: 'assets/icon.ico',
        fallbackAssetPath: 'assets/logo.png',
        outputFileName: 'astral_game_tray_icon',
      );
    } else {
      iconPath = await _ensureTrayIconFile(
        preferredAssetPath: 'assets/logo.png',
        fallbackAssetPath: 'assets/logo.png',
        outputFileName: 'astral_game_tray_icon',
      );
    }

    await _trayManager.setIcon(iconPath);
    if (!Platform.isLinux) {
      await _trayManager.setToolTip('Astral Game');
    }
    await _trayManager.setContextMenu(
      Menu(
        items: [
          MenuItem(key: 'show_window', label: '显示主界面'),
          MenuItem.separator(),
          MenuItem(key: 'exit', label: '退出'),
        ],
      ),
    );
  }

  Future<String> _ensureTrayIconFile({
    required String preferredAssetPath,
    required String fallbackAssetPath,
    required String outputFileName,
  }) async {
    final tmpDir = await getTemporaryDirectory();

    Future<String> writeAsset(String assetPath, String ext) async {
      final bytes = await rootBundle.load(assetPath);
      final file = File('${tmpDir.path}${Platform.pathSeparator}$outputFileName$ext');
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      return file.path;
    }

    try {
      final ext = preferredAssetPath.toLowerCase().endsWith('.ico') ? '.ico' : '.png';
      return await writeAsset(preferredAssetPath, ext);
    } catch (_) {
      final ext = fallbackAssetPath.toLowerCase().endsWith('.ico') ? '.ico' : '.png';
      return await writeAsset(fallbackAssetPath, ext);
    }
  }

  Future<void> _showWindowFromTray() async {
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> _handleCloseRequested() async {
    if (!_isDesktopPlatform) return;
    final closeMinimize = getIt<SettingsState>().closeMinimize.value;
    if (closeMinimize) {
      await windowManager.hide();
      return;
    }
    await windowManager.setPreventClose(false);
    await windowManager.close();
  }

  @override
  void onWindowClose() {
    unawaited(_handleCloseRequested());
  }

  @override
  void onTrayIconMouseDown() {
    unawaited(_showWindowFromTray());
  }

  @override
  void onTrayIconRightMouseDown() {
    unawaited(_trayManager.popUpContextMenu());
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show_window':
        unawaited(_showWindowFromTray());
        break;
      case 'exit':
        unawaited(() async {
          await windowManager.setPreventClose(false);
          await windowManager.close();
        }());
        break;
    }
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

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 600;
    _screenStateService.updateScreenWidth(screenWidth);

    final hasOverlay = _contentController.hasOverlay;
    final overlayTitle = _contentController.overlayTitle;
    final isDesktop = _isDesktopPlatform;

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
                if (isDesktop)
                  _TitleBar(
                    height: 44,
                    title: hasOverlay ? overlayTitle! : 'Astral Game',
                    showBackButton: hasOverlay,
                    onClose: () => unawaited(_handleCloseRequested()),
                    onBack: hasOverlay
                        ? () => _contentController.closeOverlay()
                        : null,
                  ),
                if (!isDesktop)
                  _CompactTopAppBar(
                    title: hasOverlay ? overlayTitle ?? '' : '',
                    showBackButton: hasOverlay,
                    onBack: hasOverlay ? () => _contentController.closeOverlay() : null,
                  ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: !isCompact
                        ? const BorderRadius.only(
                            topLeft: Radius.circular(18),
                          )
                        : BorderRadius.zero,
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
                                child: _contentController.overlayContentBuilder!(context),
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
  final VoidCallback onClose;

  const _TitleBar({
    required this.height,
    required this.title,
    required this.onClose,
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
                onTap: widget.onClose,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactTopAppBar extends StatelessWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBack;

  const _CompactTopAppBar({
    required this.title,
    this.showBackButton = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasContent = showBackButton || title.isNotEmpty;

    return SafeArea(
      bottom: false,
      child: Container(
        color: colorScheme.surface,
        height: hasContent ? 56 : 0,
        child: hasContent
            ? Row(
                children: [
                  if (showBackButton)
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
                      onPressed: onBack,
                    )
                  else
                    const SizedBox(width: 16),
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
              )
            : null,
      ),
    );
  }
}