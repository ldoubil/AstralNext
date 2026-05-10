import 'package:astral/data/services/app_settings_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class SoftwareSettingsPage extends StatefulWidget {
  const SoftwareSettingsPage({super.key});

  @override
  State<SoftwareSettingsPage> createState() => _SoftwareSettingsPageState();
}

class _SoftwareSettingsPageState extends State<SoftwareSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final settings = GetIt.I<AppSettingsService>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        Card(
          child: Column(
            children: [
              const ListTile(
                title: Text('窗口行为'),
                subtitle: Text('设置窗口关闭和启动行为'),
                leading: Icon(Icons.window),
              ),
              const Divider(height: 1),
              _ModeTile(
                title: '最小化到托盘',
                subtitle: '点击关闭按钮时隐藏窗口到系统托盘',
                selected: settings.getCloseBehavior() == CloseBehavior.minimizeToTray,
                onTap: () {
                  settings.setCloseBehavior(CloseBehavior.minimizeToTray);
                  setState(() {});
                },
              ),
              const Divider(height: 1),
              _ModeTile(
                title: '直接退出应用',
                subtitle: '点击关闭按钮时直接退出程序',
                selected: settings.getCloseBehavior() == CloseBehavior.exitApp,
                onTap: () {
                  settings.setCloseBehavior(CloseBehavior.exitApp);
                  setState(() {});
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              const ListTile(
                title: Text('编辑器设置'),
                subtitle: Text('设置默认的编辑模式'),
                leading: Icon(Icons.edit),
              ),
              const Divider(height: 1),
              _ModeTile(
                title: '默认可视化编辑',
                subtitle: '打开配置时优先使用可视化编辑器',
                selected: settings.getEditorDefaultMode() == ConfigEditorDefaultMode.visual,
                onTap: () async {
                  await settings.setEditorDefaultMode(ConfigEditorDefaultMode.visual);
                  if (mounted) setState(() {});
                },
              ),
              const Divider(height: 1),
              _ModeTile(
                title: '默认文本编辑',
                subtitle: '打开配置时优先使用 TOML 文本编辑器',
                selected: settings.getEditorDefaultMode() == ConfigEditorDefaultMode.text,
                onTap: () async {
                  await settings.setEditorDefaultMode(ConfigEditorDefaultMode.text);
                  if (mounted) setState(() {});
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModeTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTile({
    required this.title,
    required this.subtitle,
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
            ? colorScheme.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (selected) Icon(Icons.check, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }
}
