part of 'package:astral/ui/pages/dashboard_page.dart';

class _QuoteCard extends StatefulWidget {
  const _QuoteCard();

  @override
  State<_QuoteCard> createState() => _QuoteCardState();
}

class _QuoteCardState extends State<_QuoteCard> {
  String _appVersion = '';
  String _coreVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersions();
  }

  Future<void> _loadVersions() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final coreVersion = await easytierVersion();
    if (mounted) {
      setState(() {
        _appVersion = packageInfo.version;
        _coreVersion = coreVersion;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: '版本信息',
      subtitle: 'Version',
      contentPadding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVersionRow(
            context,
            icon: Icons.apps,
            label: '软件版本',
            version: _appVersion,
          ),
          const SizedBox(height: 8),
          _buildVersionRow(
            context,
            icon: Icons.memory,
            label: '内核版本',
            version: _coreVersion,
          ),
        ],
      ),
    );
  }

  Widget _buildVersionRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String version,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            version.isNotEmpty ? 'v$version' : '...',
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
