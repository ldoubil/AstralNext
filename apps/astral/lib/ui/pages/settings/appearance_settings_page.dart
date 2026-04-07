import 'package:astral/config/theme.dart';
import 'package:astral/stores/global/theme_store.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class _PresetTheme {
  final String name;
  final Color color;

  const _PresetTheme({required this.name, required this.color});
}

const List<_PresetTheme> _presetThemes = [
  _PresetTheme(name: '默认蓝', color: Color(0xFF1B4DD7)),
  _PresetTheme(name: '紫罗兰', color: Color(0xFF7C4DFF)),
  _PresetTheme(name: '靛蓝', color: Color(0xFF3F51B5)),
  _PresetTheme(name: '青色', color: Color(0xFF00BCD4)),
  _PresetTheme(name: '青绿色', color: Color(0xFF1DE9B6)),
  _PresetTheme(name: '绿色', color: Color(0xFF4CAF50)),
  _PresetTheme(name: '酸橙色', color: Color(0xFF8BC34A)),
  _PresetTheme(name: '黄色', color: Color(0xFFFFC107)),
  _PresetTheme(name: '橙色', color: Color(0xFFFF9800)),
  _PresetTheme(name: '红色', color: Color(0xFFF44336)),
  _PresetTheme(name: '粉红色', color: Color(0xFFE91E63)),
  _PresetTheme(name: '深红色', color: Color(0xFFB71C1C)),
];

class AppearanceSettingsPage extends StatelessWidget {
  const AppearanceSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeStore = GetIt.I<ThemeStore>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        ValueListenableBuilder<ThemeMode>(
          valueListenable: themeStore.mode,
          builder: (context, mode, _) {
            return ValueListenableBuilder<Color>(
              valueListenable: themeStore.seedColor,
              builder: (context, seedColor, _) {
                return _ThemeModeSection(
                  mode: mode,
                  seedColor: seedColor,
                  onModeChanged: (newMode) => themeStore.setMode(newMode),
                  onColorChanged: (newColor) => themeStore.setSeedColor(newColor),
                );
              },
            );
          },
        ),
        const SizedBox(height: 20),
        ValueListenableBuilder<Color>(
          valueListenable: themeStore.seedColor,
          builder: (context, currentColor, _) {
            return _ColorPickerSection(
              currentColor: currentColor,
              onColorSelected: (color) => themeStore.setSeedColor(color),
            );
          },
        ),
      ],
    );
  }
}

class _ThemeModeSection extends StatelessWidget {
  final ThemeMode mode;
  final Color seedColor;
  final ValueChanged<ThemeMode> onModeChanged;
  final ValueChanged<Color> onColorChanged;

  const _ThemeModeSection({
    required this.mode,
    required this.seedColor,
    required this.onModeChanged,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '主题模式',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ThemeModeCard(
                    icon: Icons.wb_sunny,
                    label: '浅色',
                    isSelected: mode == ThemeMode.light,
                    theme: AstralTheme.light(seedColor: seedColor),
                    onTap: () => onModeChanged(ThemeMode.light),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ThemeModeCard(
                    icon: Icons.dark_mode,
                    label: '深色',
                    isSelected: mode == ThemeMode.dark,
                    theme: AstralTheme.dark(seedColor: seedColor),
                    onTap: () => onModeChanged(ThemeMode.dark),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ThemeModeCard(
                    icon: Icons.brightness_auto,
                    label: '系统',
                    isSelected: mode == ThemeMode.system,
                    theme: Theme.of(context).brightness == Brightness.light
                        ? AstralTheme.light(seedColor: seedColor)
                        : AstralTheme.dark(seedColor: seedColor),
                    onTap: () => onModeChanged(ThemeMode.system),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeModeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final ThemeData theme;
  final VoidCallback onTap;

  const _ThemeModeCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 32,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colorScheme.secondary.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: isSelected ? colorScheme.primary : null),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? colorScheme.primary : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorPickerSection extends StatelessWidget {
  final Color currentColor;
  final ValueChanged<Color> onColorSelected;

  const _ColorPickerSection({
    required this.currentColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '主题配色',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _ColorGrid(
              currentColor: currentColor,
              onColorSelected: onColorSelected,
            ),
            const SizedBox(height: 20),
            _CustomColorPicker(
              currentColor: currentColor,
              onColorSelected: onColorSelected,
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorGrid extends StatelessWidget {
  final Color currentColor;
  final ValueChanged<Color> onColorSelected;

  const _ColorGrid({
    required this.currentColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _presetThemes.map((theme) {
        final isSelected = (theme.color.value & 0xFFFFFF) == (currentColor.value & 0xFFFFFF);
        return _ColorOption(
          color: theme.color,
          isSelected: isSelected,
          name: theme.name,
          onTap: () => onColorSelected(theme.color),
        );
      }).toList(),
    );
  }
}

class _ColorOption extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final String name;
  final VoidCallback onTap;

  const _ColorOption({
    required this.color,
    required this.isSelected,
    required this.name,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: name,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              width: isSelected ? 3 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: isSelected
              ? Icon(
                  Icons.check,
                  color: ThemeData.estimateBrightnessForColor(color) == Brightness.light
                      ? Colors.black87
                      : Colors.white,
                  size: 28,
                )
              : null,
        ),
      ),
    );
  }
}

class _CustomColorPicker extends StatefulWidget {
  final Color currentColor;
  final ValueChanged<Color> onColorSelected;

  const _CustomColorPicker({
    required this.currentColor,
    required this.onColorSelected,
  });

  @override
  State<_CustomColorPicker> createState() => _CustomColorPickerState();
}

class _CustomColorPickerState extends State<_CustomColorPicker> {
  late Color _tempColor;

  @override
  void initState() {
    super.initState();
    _tempColor = widget.currentColor;
  }

  @override
  void didUpdateWidget(_CustomColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentColor != widget.currentColor) {
      _tempColor = widget.currentColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '自定义颜色',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              _SliderRow(
                label: '红',
                value: (_tempColor.value >> 16) & 0xFF,
                color: Colors.red,
                onChanged: (value) {
                  setState(() {
                    _tempColor = Color.fromARGB(
                      _tempColor.alpha,
                      value,
                      (_tempColor.value >> 8) & 0xFF,
                      _tempColor.value & 0xFF,
                    );
                  });
                },
              ),
              const SizedBox(height: 12),
              _SliderRow(
                label: '绿',
                value: (_tempColor.value >> 8) & 0xFF,
                color: Colors.green,
                onChanged: (value) {
                  setState(() {
                    _tempColor = Color.fromARGB(
                      _tempColor.alpha,
                      (_tempColor.value >> 16) & 0xFF,
                      value,
                      _tempColor.value & 0xFF,
                    );
                  });
                },
              ),
              const SizedBox(height: 12),
              _SliderRow(
                label: '蓝',
                value: _tempColor.value & 0xFF,
                color: Colors.blue,
                onChanged: (value) {
                  setState(() {
                    _tempColor = Color.fromARGB(
                      _tempColor.alpha,
                      (_tempColor.value >> 16) & 0xFF,
                      (_tempColor.value >> 8) & 0xFF,
                      value,
                    );
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: _tempColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '#${_tempColor.value.toRadixString(16).substring(2, 8).toUpperCase()}',
                          style: TextStyle(
                            color: ThemeData.estimateBrightnessForColor(_tempColor) == Brightness.light
                                ? Colors.black87
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () {
                      widget.onColorSelected(_tempColor);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('应用'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final ValueChanged<int> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 30,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.2),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: value.toDouble(),
              min: 0,
              max: 255,
              divisions: 255,
              label: value.toString(),
              onChanged: (newValue) => onChanged(newValue.round()),
            ),
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            value.toString(),
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}
