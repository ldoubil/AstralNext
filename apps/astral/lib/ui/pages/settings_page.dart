// lib/ui/pages/settings_page.dart
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
      padding: const EdgeInsets.all(28),
      children: [
        Text(
          '外观',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ValueListenableBuilder<ThemeMode>(
          valueListenable: themeStore.mode,
          builder: (context, mode, _) {
            return SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              title: const Text('深色模式'),
              subtitle: Text(
                mode == ThemeMode.dark ? '当前：深色' : '当前：浅色',
              ),
              value: mode == ThemeMode.dark,
              onChanged: (value) {
                themeStore.setMode(
                  value ? ThemeMode.dark : ThemeMode.light,
                );
              },
            );
          },
        ),
      ],
    );
  }
}
