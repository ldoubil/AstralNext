import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Logo 和应用名称
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
                Text(
                  'v1.0.0',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Astral 游戏客户端',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
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
                subtitle: const Text('当前版本: 1.0.0'),
                trailing: const Icon(Icons.chevron_right),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.update),
                title: const Text('检查更新'),
                subtitle: const Text('查看是否有新版本'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('当前已是最新版本')),
                  );
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
                    applicationVersion: '1.0.0',
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
