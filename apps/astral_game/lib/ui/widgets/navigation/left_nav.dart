import 'package:flutter/material.dart';
import 'package:astral_game/ui/widgets/navigation/navigation_item.dart';

class LeftNav extends StatefulWidget {
  final List<NavigationItem> items;
  final ColorScheme colorScheme;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const LeftNav({
    super.key,
    required this.items,
    required this.colorScheme,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  State<LeftNav> createState() => _LeftNavState();
}

class _LeftNavState extends State<LeftNav> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _currentIndex = 0;
  int _targetIndex = 0;

  static const double _railWidth = 92.0;
  static const double _itemHeight = 64.0;
  static const double _itemMargin = 4.0;
  static const double _itemSpacing = _itemHeight + (_itemMargin * 2);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
    _currentIndex = widget.selectedIndex.clamp(0, widget.items.length - 1);
    _targetIndex = _currentIndex;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateAnimation(int newIndex) {
    if (newIndex < 0 || newIndex >= widget.items.length) return;

    if (_targetIndex != newIndex) {
      setState(() {
        _currentIndex = _targetIndex;
        _targetIndex = newIndex;
      });
      _animationController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = widget.colorScheme;
    final selectedIndex = widget.selectedIndex.clamp(0, widget.items.length - 1);

    _updateAnimation(selectedIndex);

    Widget buildNavItem(NavigationItem item, int index, bool isSelected) {
      final foreground = isSelected
          ? colorScheme.onPrimaryContainer
          : colorScheme.onPrimaryContainer.withValues(alpha: 0.72);

      return Container(
        height: _itemHeight,
        margin: EdgeInsets.symmetric(vertical: _itemMargin, horizontal: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => widget.onSelected(index),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? item.activeIcon : item.icon,
                  color: foreground,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: foreground,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      width: _railWidth,
      color: colorScheme.primaryContainer,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          const _BrandBadge(),
          const SizedBox(height: 12),
          Expanded(
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    final startPosition = _itemMargin + (_currentIndex * _itemSpacing);
                    final endPosition = _itemMargin + (_targetIndex * _itemSpacing);
                    final currentPosition =
                        startPosition +
                        (endPosition - startPosition) * _animation.value;

                    return Positioned(
                      top: currentPosition,
                      left: 12,
                      right: 12,
                      height: _itemHeight,
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    );
                  },
                ),
                ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.items.length,
                  itemBuilder: (context, index) {
                    final item = widget.items[index];
                    return buildNavItem(item, index, selectedIndex == index);
                  },
                ),
              ],
            ),
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