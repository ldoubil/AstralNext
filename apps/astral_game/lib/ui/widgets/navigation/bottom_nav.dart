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

    return BottomNavigationBar(
      backgroundColor: colorScheme.surfaceContainerLow,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onSurfaceVariant,
      showUnselectedLabels: !isSmallWindow,
      selectedFontSize: isSmallWindow ? 10 : 12,
      unselectedFontSize: isSmallWindow ? 8 : 10,
      items: navigationItems
          .map(
            (item) => BottomNavigationBarItem(
              icon: Icon(
                item.icon,
                size: isSmallWindow ? 20 : 24,
              ),
              activeIcon: Icon(
                item.activeIcon,
                size: isSmallWindow ? 20 : 24,
              ),
              label: item.label,
            ),
          )
          .toList(),
      currentIndex: selectedIndex,
      onTap: onSelected,
    );
  }
}