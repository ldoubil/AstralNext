import 'package:flutter/material.dart';
import 'package:astral_game/ui/widgets/navigation/navigation_item.dart';

class BottomNav extends StatelessWidget {
  final List<NavigationItem> navigationItems;
  final ColorScheme colorScheme;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const BottomNav({
    super.key,
    required this.navigationItems,
    required this.colorScheme,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final isSmallWindow = screenWidth < 300 || screenHeight < 400;

    return NavigationBar(
      backgroundColor: colorScheme.surfaceContainerLow,
      indicatorColor: colorScheme.secondaryContainer,
      indicatorShape: const StadiumBorder(),
      height: isSmallWindow ? 56 : 80,
      labelBehavior: isSmallWindow
          ? NavigationDestinationLabelBehavior.alwaysHide
          : NavigationDestinationLabelBehavior.alwaysShow,
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      destinations: navigationItems
          .map(
            (item) => NavigationDestination(
              icon: Icon(
                item.icon,
                size: isSmallWindow ? 20 : 24,
                color: colorScheme.onSurface,
              ),
              selectedIcon: Icon(
                item.activeIcon,
                size: isSmallWindow ? 20 : 24,
                color: colorScheme.onSecondaryContainer,
              ),
              label: item.label,
            ),
          )
          .toList(),
    );
  }
}
