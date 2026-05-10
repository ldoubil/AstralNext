import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:astral_game/di.dart';
import 'package:astral_game/data/state/settings_state.dart';
import 'package:astral_game/data/state/update_state.dart';

class GeneralSettingsPage extends StatelessWidget {
  const GeneralSettingsPage({super.key});

  static const List<Color> _presetSeedColors = [
    Color(0xFF1B4DD7), // Blue
    Color(0xFF7C3AED), // Purple
    Color(0xFF10B981), // Green
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Red
    Color(0xFF06B6D4), // Cyan
  ];

  @override
  Widget build(BuildContext context) {
    final settingsState = getIt<SettingsState>();
    final updateState = getIt<UpdateState>();

    return ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSettingsCard(
            context,
            children: [
              const ListTile(
                title: Text('界面设置'),
                subtitle: Text('控制应用的界面行为'),
                leading: Icon(Icons.settings),
              ),
              const Divider(height: 1),
              Watch((context) {
                return ListTile(
                  title: const Text('主题模式'),
                  subtitle: const Text('浅色 / 深色 / 跟随系统'),
                  leading: const Icon(Icons.color_lens_outlined),
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<ThemeMode>(
                      value: settingsState.themeMode.value,
                      items: const [
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text('跟随系统'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text('浅色'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text('深色'),
                        ),
                      ],
                      onChanged: (mode) {
                        if (mode == null) return;
                        settingsState.themeMode.value = mode;
                        settingsState.saveToPersistence();
                      },
                    ),
                  ),
                );
              }),
              const Divider(height: 1),
              Watch((context) {
                return SwitchListTile(
                  title: const Text('系统动态取色（Material You）'),
                  subtitle: const Text('在支持的平台上从系统主题取色（Android 12+）'),
                  value: settingsState.useDynamicColor.value,
                  onChanged: (value) {
                    settingsState.useDynamicColor.value = value;
                    settingsState.saveToPersistence();
                  },
                );
              }),
              const Divider(height: 1),
              Watch((context) {
                return ListTile(
                  title: const Text('主题主色'),
                  subtitle: const Text('选择应用主色（动态取色开启时可能被系统配色覆盖）'),
                  leading: const Icon(Icons.palette_outlined),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  isThreeLine: true,
                  trailing: TextButton(
                    onPressed: () => _showHexSeedColorDialog(context, settingsState),
                    child: const Text('自定义'),
                  ),
                  subtitleTextStyle: Theme.of(context).textTheme.bodySmall,
                  titleTextStyle: Theme.of(context).textTheme.bodyLarge,
                );
              }),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                child: Watch((context) {
                  final selected = settingsState.seedColor.value;

                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final color in _presetSeedColors)
                        ChoiceChip(
                          label: const Text(''),
                          selected: selected.toARGB32() == color.toARGB32(),
                          onSelected: (_) {
                            settingsState.seedColor.value = color;
                            settingsState.saveToPersistence();
                          },
                          avatar: _ColorDot(color: color),
                        ),
                    ],
                  );
                }),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('关闭时最小化到托盘'),
                subtitle: const Text('点击关闭按钮时最小化而不是退出'),
                value: settingsState.closeMinimize.value,
                onChanged: (value) {
                  settingsState.closeMinimize.value = value;
                  settingsState.saveToPersistence();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSettingsCard(
            context,
            children: [
              const ListTile(
                title: Text('更新设置'),
                subtitle: Text('配置应用更新行为'),
                leading: Icon(Icons.system_update),
              ),
              const Divider(height: 1),
              Watch((context) {
                return SwitchListTile(
                  title: const Text('自动检查更新'),
                  subtitle: const Text('启动时自动检查是否有新版本'),
                  value: updateState.autoCheckUpdate.value,
                  onChanged: (value) {
                    updateState.setAutoCheckUpdate(value);
                  },
                );
              }),
              const Divider(height: 1),
              Watch((context) {
                return SwitchListTile(
                  title: const Text('测试版频道'),
                  subtitle: const Text('接收测试版和预发布版本的更新'),
                  value: updateState.beta.value,
                  onChanged: (value) {
                    updateState.setBeta(value);
                  },
                );
              }),
            ],
          ),
        ],
      );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required List<Widget> children,
  }) {
    return Card(
      child: Column(children: children),
    );
  }

  Future<void> _showHexSeedColorDialog(
    BuildContext context,
    SettingsState settingsState,
  ) async {
    final controller = TextEditingController(
      text: _colorToHex(settingsState.seedColor.value),
    );

    final result = await showDialog<Color>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('自定义主题色'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: '颜色（HEX）',
              hintText: '#RRGGBB 或 #AARRGGBB',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                final color = _tryParseHexColor(controller.text);
                Navigator.of(context).pop(color);
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );

    if (result == null) return;
    settingsState.seedColor.value = result;
    await settingsState.saveToPersistence();
  }

  static String _colorToHex(Color color) {
    final a = color.a.toInt().toRadixString(16).padLeft(2, '0').toUpperCase();
    final r = color.r.toInt().toRadixString(16).padLeft(2, '0').toUpperCase();
    final g = color.g.toInt().toRadixString(16).padLeft(2, '0').toUpperCase();
    final b = color.b.toInt().toRadixString(16).padLeft(2, '0').toUpperCase();

    if (a == 'FF') return '#$r$g$b';
    return '#$a$r$g$b';
  }

  static Color? _tryParseHexColor(String input) {
    var hex = input.trim().toUpperCase();
    if (hex.startsWith('#')) hex = hex.substring(1);
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    if (hex.length != 8) return null;
    final value = int.tryParse(hex, radix: 16);
    if (value == null) return null;
    return Color(value);
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;

  const _ColorDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
