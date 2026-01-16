import 'package:bitsdojo_window/bitsdojo_window.dart' show MoveWindow, WindowTitleBarBox;
import 'package:flutter/material.dart';

import '../pages/dashboard_page.dart';
import '../pages/logs_page.dart';
import '../pages/nodes_page.dart';
import '../pages/settings_page.dart';
import '../widgets/window_button.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _selectedIndex = 0;

  void _handleDestinationSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCompact = MediaQuery.of(context).size.width < 900;
    const pages = [
      DashboardPage(key: PageStorageKey('dashboard')),
      NodesPage(key: PageStorageKey('nodes')),
      LogsPage(key: PageStorageKey('logs')),
      SettingsPage(key: PageStorageKey('settings')),
    ];

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
                if (!isCompact) const _TitleBar(height: 44, title: 'Astral'),
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                    ),
                    child: Container(
                      color: colorScheme.surface,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(opacity: animation, child: child);
                        },
                        child: pages[_selectedIndex],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isCompact
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
                  label: '面板',
                ),
                NavigationDestination(
                  icon: Icon(Icons.dns_outlined),
                  selectedIcon: Icon(Icons.dns),
                  label: '实例',
                ),
                NavigationDestination(
                  icon: Icon(Icons.article_outlined),
                  selectedIcon: Icon(Icons.article),
                  label: '日志',
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

class _TitleBar extends StatelessWidget {
  final double height;
  final String title;
  final VoidCallback? onMinimize;
  final VoidCallback? onMaximize;
  final VoidCallback? onClose;

  const _TitleBar({
    required this.height,
    required this.title,
    this.onMinimize,
    this.onMaximize,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return WindowTitleBarBox(
      child: SizedBox(
        height: height,
        child: Container(
          color: colorScheme.primaryContainer,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: MoveWindow(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              WindowButton(
                icon: Icons.remove,
                iconSize: 16,
                hoverColor: colorScheme.primary.withOpacity(0.12),
                iconColor: colorScheme.onPrimaryContainer,
                onTap: onMinimize ?? () {},
              ),
              WindowButton(
                icon: Icons.crop_square,
                iconSize: 14,
                hoverColor: colorScheme.primary.withOpacity(0.12),
                iconColor: colorScheme.onPrimaryContainer,
                onTap: onMaximize ?? () {},
              ),
              WindowButton(
                icon: Icons.close,
                iconSize: 16,
                hoverColor: colorScheme.errorContainer,
                iconColor: colorScheme.onPrimaryContainer,
                onTap: onClose ?? () {},
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
            label: '日志',
            icon: Icons.article_outlined,
            selectedIcon: Icons.article,
            selected: selectedIndex == 2,
            onTap: () => onSelected(2),
          ),
          const Spacer(),
          _RailDestination(
            label: '设置',
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings,
            selected: selectedIndex == 3,
            onTap: () => onSelected(3),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.center,
      child: Text(
        'A',
        style: TextStyle(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
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
        : colorScheme.onPrimaryContainer.withOpacity(0.72);

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
                    ? colorScheme.primary.withOpacity(0.18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                selected ? selectedIcon : icon,
                color: foreground,
              ),
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
