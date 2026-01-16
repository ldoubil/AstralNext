import 'package:astral/stores/global/theme_store.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeStore = GetIt.I<ThemeStore>();
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        Text(
          '外观与偏好',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '遵循 MD3：纯色块层级，无阴影、无描边。',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ValueListenableBuilder<ThemeMode>(
            valueListenable: themeStore.mode,
            builder: (context, mode, _) {
              return Column(
                children: [
                  _ModeTile(
                    title: '浅色模式',
                    selected: mode == ThemeMode.light,
                    onTap: () => themeStore.setMode(ThemeMode.light),
                  ),
                  const Divider(height: 1),
                  _ModeTile(
                    title: '深色模式',
                    selected: mode == ThemeMode.dark,
                    onTap: () => themeStore.setMode(ThemeMode.dark),
                  ),
                  const Divider(height: 1),
                  _ModeTile(
                    title: '跟随系统',
                    selected: mode == ThemeMode.system,
                    onTap: () => themeStore.setMode(ThemeMode.system),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ModeTile extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        color: selected
            ? colorScheme.primary.withOpacity(0.08)
            : Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (selected)
              Icon(
                Icons.check,
                color: colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}
