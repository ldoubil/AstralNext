// lib/ui/shell/shell.dart
import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart'
    show MoveWindow, WindowTitleBarBox;
import '../pages/dashboard_page.dart';
import '../pages/nodes_page.dart';
import '../pages/logs_page.dart';
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
    return Scaffold(
      body: Column(
        children: [
          const _TitleBar(height: 44, title: 'Astral 控制台'),
          Expanded(
            child: Row(
              children: [
                _ShellNavigationRail(
                  selectedIndex: _selectedIndex,
                  onSelected: _handleDestinationSelected,
                ),
                Expanded(child: _ShellContent(selectedIndex: _selectedIndex)),
              ],
            ),
          ),
        ],
      ),
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
          color: colorScheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Row(
            children: [
              Expanded(
                child: MoveWindow(
                  child: Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              WindowButton(
                icon: Icons.remove,
                iconSize: 16,
                hoverColor: colorScheme.surfaceVariant,
                onTap: onMinimize ?? () {},
              ),
              WindowButton(
                icon: Icons.crop_square,
                iconSize: 14,
                hoverColor: colorScheme.surfaceVariant,
                onTap: onMaximize ?? () {},
              ),
              WindowButton(
                icon: Icons.close,
                iconSize: 16,
                hoverColor: colorScheme.errorContainer,
                iconColor: colorScheme.onSurfaceVariant,
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
    const railWidth = 72.0;

    return Container(
      width: railWidth,
      color: colorScheme.surface,
      child: Column(
        children: [
          const SizedBox(height: 12),
          _RailDestination(
            label: '面板',
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
            selected: selectedIndex == 0,
            onTap: () => onSelected(0),
          ),
          _RailDestination(
            label: '节点',
            icon: Icons.devices_outlined,
            selectedIcon: Icons.devices,
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
          const SizedBox(height: 12),
        ],
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
    final iconColor = selected
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;
    final textStyle = TextStyle(
      color: iconColor,
      fontSize: 12,
      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
    );
    final highlightColor = colorScheme.secondaryContainer;

    return InkResponse(
      onTap: onTap,
      radius: 28,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: selected ? highlightColor : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: Icon(
                  selected ? selectedIcon : icon,
                  key: ValueKey<bool>(selected),
                  color: iconColor,
                ),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              style: textStyle,
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShellContent extends StatelessWidget {
  final int selectedIndex;

  const _ShellContent({required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.only(top: 0),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(16)),
        child: Container(
          color: colorScheme.surfaceVariant,
          child: IndexedStack(
            index: selectedIndex,
            children: const [
              DashboardPage(),
              NodesPage(),
              LogsPage(),
              SettingsPage(),
            ],
          ),
        ),
      ),
    );
  }
}
