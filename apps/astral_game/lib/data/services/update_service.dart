import 'dart:convert';
import 'dart:math';

import 'package:astral_game/config/constants.dart';
import 'package:astral_game/data/state/update_state.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// 更新检测服务
class UpdateService {
  final UpdateState updateState;
  static const _requestTimeout = Duration(seconds: 15);
  static const String _downloadPage = 'https://astral.fan/quick-start/download-install/';

  UpdateService(this.updateState);

  /// 获取当前应用版本号
  Future<String> getCurrentVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version;
    } catch (e) {
      return AppConstants.appVersion;
    }
  }

  /// 检查是否有新版本
  Future<void> checkForUpdates(
    BuildContext context, {
    bool showNoUpdateMessage = true,
    bool showFailureMessage = true,
  }) async {
    if (updateState.isChecking.value) return;
    updateState.isChecking.value = true;

    try {
      final releaseInfo = await _fetchLatestRelease(
        includePrereleases: updateState.beta.value,
      );

      if (releaseInfo == null) {
        if (!context.mounted) return;
        if (showFailureMessage) {
          _showMessageDialog(context, '检查更新失败', '无法获取最新版本信息');
        }
        return;
      }

      final currentVersion = await getCurrentVersion();
      final latestVersion = _extractString(releaseInfo, 'tag_name');

      if (latestVersion.isEmpty) {
        if (!context.mounted) return;
        if (showFailureMessage) {
          _showMessageDialog(context, '检查更新失败', '无法解析版本号');
        }
        return;
      }

      updateState.setLatestVersion(latestVersion);

      if (!context.mounted) return;

      final releaseNotes = _extractString(releaseInfo, 'body',
          fallback: '新版本已发布');

      if (_shouldUpdate(currentVersion, latestVersion)) {
        _showUpdateDialog(context, latestVersion, releaseNotes);
      } else if (showNoUpdateMessage) {
        _showMessageDialog(context, '当前已是最新版本', '当前版本: $currentVersion');
      }
    } catch (e) {
      if (!context.mounted) return;
      if (showFailureMessage) {
        _showMessageDialog(context, '更新检查失败', '检查更新时发生错误: $e');
      }
    } finally {
      updateState.isChecking.value = false;
    }
  }

  /// 获取最新 release 信息
  Future<Map<String, dynamic>?> _fetchLatestRelease({
    bool includePrereleases = false,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse(AppConstants.githubReleasesUrl),
            headers: {
              'Accept': 'application/vnd.github.v3+json',
              'User-Agent': 'astral-game',
            },
          )
          .timeout(_requestTimeout);

      if (response.statusCode != 200) return null;

      final decoded = json.decode(response.body);
      if (decoded is! List) return null;

      for (final item in decoded) {
        if (item is! Map) continue;
        final release = Map<String, dynamic>.from(item);
        if (release['draft'] == true) continue;
        if (!includePrereleases && release['prerelease'] == true) continue;
        return release;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// 比较版本号，判断是否需要更新
  bool _shouldUpdate(String currentVersion, String latestVersion) {
    final current = currentVersion.replaceAll(RegExp(r'^v'), '');
    final latest = latestVersion.replaceAll(RegExp(r'^v'), '');

    final currentParts = current.split('-');
    final latestParts = latest.split('-');

    final currentMain = _parseVersionParts(currentParts[0]);
    final latestMain = _parseVersionParts(latestParts[0]);

    for (int i = 0; i < 3; i++) {
      final curr = i < currentMain.length ? currentMain[i] : 0;
      final lat = i < latestMain.length ? latestMain[i] : 0;
      if (lat > curr) return true;
      if (lat < curr) return false;
    }

    if (currentParts.length == 1) return latestParts.length > 1;
    if (latestParts.length == 1) return true;

    return _comparePreRelease(currentParts[1], latestParts[1]) < 0;
  }

  List<int> _parseVersionParts(String version) {
    return version.split('.').map((s) => int.tryParse(s) ?? 0).toList();
  }

  int _comparePreRelease(String a, String b) {
    final aParts = a.split('.');
    final bParts = b.split('.');
    for (int i = 0; i < max(aParts.length, bParts.length); i++) {
      final aVal = i < aParts.length ? aParts[i] : '';
      final bVal = i < bParts.length ? bParts[i] : '';
      final aNum = int.tryParse(aVal);
      final bNum = int.tryParse(bVal);
      if (aNum != null && bNum != null) {
        if (aNum != bNum) return aNum.compareTo(bNum);
      } else {
        final cmp = aVal.compareTo(bVal);
        if (cmp != 0) return cmp;
      }
    }
    return 0;
  }

  String _extractString(Map<String, dynamic> source, String key,
      {String fallback = ''}) {
    final value = source[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return fallback;
  }

  /// 显示更新对话框
  void _showUpdateDialog(
    BuildContext context,
    String version,
    String releaseNotes,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('发现新版本: $version'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('当前版本: ${updateState.latestVersion.value ?? version}'),
              const SizedBox(height: 12),
              const Text('更新内容:'),
              const SizedBox(height: 8),
              Text(releaseNotes, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('稍后再说'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _launchUrl(_downloadPage);
            },
            child: const Text('前往更新'),
          ),
        ],
      ),
    );
  }

  /// 显示简单消息对话框
  void _showMessageDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
