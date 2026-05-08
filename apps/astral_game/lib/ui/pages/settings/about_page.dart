import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:astral_game/config/constants.dart';
import 'package:astral_game/di.dart';
import 'package:astral_game/data/state/update_state.dart';
import 'package:astral_game/data/services/update_service.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _currentVersion = AppConstants.appVersion;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final version = await getIt<UpdateService>().getCurrentVersion();
    if (mounted) setState(() => _currentVersion = version);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final updateState = getIt<UpdateState>();
    final updateService = getIt<UpdateService>();

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Center(
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Astral Game',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Watch((context) {
                final latestVersion = updateState.latestVersion.value;
                final hasNew = latestVersion != null &&
                    latestVersion.isNotEmpty &&
                    latestVersion != _currentVersion;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'v$_currentVersion',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.outline,
                          ),
                    ),
                    if (hasNew) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '新版本: $latestVersion',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              }),
              const SizedBox(height: 4),
              Text(
                'Astral 游戏客户端',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSettingsCard(
          context,
          children: [
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('版本信息'),
              subtitle: Text('当前版本: $_currentVersion'),
              trailing: const Icon(Icons.chevron_right),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.update),
              title: const Text('检查更新'),
              subtitle: const Text('查看是否有新版本'),
              trailing: Watch((context) {
                final isChecking = updateState.isChecking.value;
                if (isChecking) {
                  return const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                return const Icon(Icons.chevron_right);
              }),
              onTap: () {
                updateService.checkForUpdates(context);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('开源许可'),
              subtitle: const Text('查看第三方开源库许可'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                showLicensePage(
                  context: context,
                  applicationName: 'Astral Game',
                  applicationVersion: _currentVersion,
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          context,
          children: [
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('GitHub'),
              subtitle: const Text('访问项目源码'),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => _launchUrl('https://github.com/ldoubil/astral'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.bug_report_outlined),
              title: const Text('反馈问题'),
              subtitle: const Text('提交 Bug 或功能建议'),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () =>
                  _launchUrl('https://github.com/ldoubil/astral/issues'),
            ),
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

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
