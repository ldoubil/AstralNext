import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

/// 单项诊断结果
enum DiagnosticStatus { pending, running, success, fail, timeout }

class _DiagnosticItem {
  final String label;
  final String description;
  DiagnosticStatus status = DiagnosticStatus.pending;
  String? detail;
  int? latencyMs;

  _DiagnosticItem({
    required this.label,
    required this.description,
  });
}

class NetworkDiagnosticPage extends StatefulWidget {
  const NetworkDiagnosticPage({super.key});

  @override
  State<NetworkDiagnosticPage> createState() => _NetworkDiagnosticPageState();
}

class _NetworkDiagnosticPageState extends State<NetworkDiagnosticPage> {
  bool _isRunning = false;
  final List<_DiagnosticItem> _items = [];

  @override
  void initState() {
    super.initState();
    _initItems();
  }

  void _initItems() {
    _items.clear();
    _items.add(_DiagnosticItem(
      label: '网络接口信息',
      description: '检测当前网络连接状态和接口',
    ));
    _items.add(_DiagnosticItem(
      label: 'IPv4 连通性',
      description: '检测 IPv4 网络连通性',
    ));
    _items.add(_DiagnosticItem(
      label: 'IPv6 连通性',
      description: '检测 IPv6 网络连通性',
    ));
    _items.add(_DiagnosticItem(
      label: 'DNS 解析 (IPv4)',
      description: '检测 IPv4 DNS 解析',
    ));
    _items.add(_DiagnosticItem(
      label: 'DNS 解析 (IPv6)',
      description: '检测 IPv6 DNS 解析',
    ));
    _items.add(_DiagnosticItem(
      label: '公网 IPv4',
      description: '获取本机公网 IPv4 地址',
    ));
    _items.add(_DiagnosticItem(
      label: '公网 IPv6',
      description: '获取本机公网 IPv6 地址',
    ));
    _items.add(_DiagnosticItem(
      label: '多目标测试',
      description: '测试多个国内网站连通性',
    ));
  }

  Future<void> _runDiagnostic() async {
    if (_isRunning) return;
    setState(() {
      _isRunning = true;
      for (final item in _items) {
        item.status = DiagnosticStatus.pending;
        item.detail = null;
        item.latencyMs = null;
      }
    });

    await _testNetworkInfo();
    await _testIPv4();
    await _testIPv6();
    await _testDnsIPv4();
    await _testDnsIPv6();
    await _testPublicIPv4();
    await _testPublicIPv6();
    await _testMultipleTargets();

    setState(() => _isRunning = false);
  }

  // ---- 诊断项 ----

  Future<void> _testNetworkInfo() async {
    final item = _items[0];
    setState(() => item.status = DiagnosticStatus.running);

    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      final details = <String>[];

      for (final iface in interfaces) {
        if (iface.addresses.isEmpty) continue;
        details.add('[${iface.name}]');
        for (final addr in iface.addresses) {
          details.add('  ${addr.address}');
        }
      }

      if (details.isEmpty) {
        details.add('未检测到网络接口');
      }

      setState(() {
        item.status = DiagnosticStatus.success;
        item.detail = details.join('\n');
      });
    } catch (e) {
      debugPrint('[网络诊断] 获取网络接口失败: $e');
      setState(() {
        item.status = DiagnosticStatus.fail;
        item.detail = '获取网络接口失败';
      });
    }
  }

  Future<void> _testIPv4() async {
    final item = _items[1];
    setState(() => item.status = DiagnosticStatus.running);

    try {
      final sw = Stopwatch()..start();
      await Socket.connect('baidu.com', 80, timeout: const Duration(seconds: 5));
      sw.stop();
      setState(() {
        item.status = DiagnosticStatus.success;
        item.latencyMs = sw.elapsedMilliseconds;
        item.detail = 'IPv4 延迟 ${sw.elapsedMilliseconds} ms';
      });
    } catch (e) {
      debugPrint('[网络诊断] IPv4 连接失败: $e');
      setState(() {
        item.status = DiagnosticStatus.fail;
        item.detail = 'IPv4 连接失败';
      });
    }
  }

  Future<void> _testIPv6() async {
    final item = _items[2];
    setState(() => item.status = DiagnosticStatus.running);

    try {
      final sw = Stopwatch()..start();
      // 尝试连接 IPv6 地址
      await Socket.connect('ipv6.google.com', 80, timeout: const Duration(seconds: 5));
      sw.stop();
      setState(() {
        item.status = DiagnosticStatus.success;
        item.latencyMs = sw.elapsedMilliseconds;
        item.detail = 'IPv6 延迟 ${sw.elapsedMilliseconds} ms';
      });
    } catch (e) {
      debugPrint('[网络诊断] IPv6 连接失败: $e');
      setState(() {
        item.status = DiagnosticStatus.fail;
        item.detail = 'IPv6 连接失败或未启用';
      });
    }
  }

  Future<void> _testDnsIPv4() async {
    final item = _items[3];
    setState(() => item.status = DiagnosticStatus.running);

    try {
      final sw = Stopwatch()..start();
      final addresses = await InternetAddress.lookup('baidu.com',
          type: InternetAddressType.IPv4);
      sw.stop();
      if (addresses.isNotEmpty) {
        setState(() {
          item.status = DiagnosticStatus.success;
          item.latencyMs = sw.elapsedMilliseconds;
          item.detail = 'IPv4: ${addresses.map((a) => a.address).join(', ')} (${sw.elapsedMilliseconds} ms)';
        });
      } else {
        setState(() {
          item.status = DiagnosticStatus.fail;
          item.detail = 'IPv4 DNS 解析结果为空';
        });
      }
    } on SocketException catch (e) {
      debugPrint('[网络诊断] IPv4 DNS 解析失败: $e');
      setState(() {
        item.status = DiagnosticStatus.fail;
        item.detail = 'IPv4 DNS 解析失败';
      });
    }
  }

  Future<void> _testDnsIPv6() async {
    final item = _items[4];
    setState(() => item.status = DiagnosticStatus.running);

    try {
      final sw = Stopwatch()..start();
      final addresses = await InternetAddress.lookup('google.com',
          type: InternetAddressType.IPv6);
      sw.stop();
      if (addresses.isNotEmpty) {
        setState(() {
          item.status = DiagnosticStatus.success;
          item.latencyMs = sw.elapsedMilliseconds;
          item.detail = 'IPv6: ${addresses.map((a) => a.address).join(', ')} (${sw.elapsedMilliseconds} ms)';
        });
      } else {
        setState(() {
          item.status = DiagnosticStatus.fail;
          item.detail = 'IPv6 DNS 解析结果为空';
        });
      }
    } on SocketException catch (e) {
      debugPrint('[网络诊断] IPv6 DNS 解析失败: $e');
      setState(() {
        item.status = DiagnosticStatus.fail;
        item.detail = 'IPv6 DNS 解析失败或未启用';
      });
    }
  }

  Future<void> _testPublicIPv4() async {
    final item = _items[5];
    setState(() => item.status = DiagnosticStatus.running);

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      final request = await client.getUrl(Uri.parse('https://api.ip.sb/ip'));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();
      final ip = body.trim();
      if (ip.contains(':')) {
        setState(() {
          item.status = DiagnosticStatus.fail;
          item.detail = '当前网络未分配 IPv4 公网地址';
        });
      } else {
        setState(() {
          item.status = DiagnosticStatus.success;
          item.detail = ip;
        });
      }
    } catch (e) {
      debugPrint('[网络诊断] 获取公网 IPv4 失败: $e');
      setState(() {
        item.status = DiagnosticStatus.fail;
        item.detail = '获取公网 IPv4 失败';
      });
    }
  }

  Future<void> _testPublicIPv6() async {
    final item = _items[6];
    setState(() => item.status = DiagnosticStatus.running);

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      final request = await client.getUrl(Uri.parse('https://api-ipv6.ip.sb/ip'));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();
      final ip = body.trim();
      if (ip.contains(':')) {
        setState(() {
          item.status = DiagnosticStatus.success;
          item.detail = ip;
        });
      } else {
        setState(() {
          item.status = DiagnosticStatus.fail;
          item.detail = '当前网络未分配 IPv6 公网地址';
        });
      }
    } catch (e) {
      debugPrint('[网络诊断] 获取公网 IPv6 失败: $e');
      setState(() {
        item.status = DiagnosticStatus.fail;
        item.detail = '获取公网 IPv6 失败或未启用 IPv6';
      });
    }
  }

  Future<void> _testMultipleTargets() async {
    final item = _items[7];
    setState(() => item.status = DiagnosticStatus.running);

    final targets = [
      ('baidu.com', 80, '百度'),
      ('qq.com', 80, '腾讯'),
      ('taobao.com', 80, '淘宝'),
      ('jd.com', 80, '京东'),
      ('163.com', 80, '网易'),
    ];

    final results = <String>[];
    var successCount = 0;

    for (final target in targets) {
      try {
        final sw = Stopwatch()..start();
        await Socket.connect(target.$1, target.$2, timeout: const Duration(seconds: 3));
        sw.stop();
        results.add('${target.$3}: ${sw.elapsedMilliseconds}ms');
        successCount++;
      } catch (e) {
        debugPrint('[网络诊断] ${target.$3} 连接失败: $e');
        results.add('${target.$3}: 失败');
      }
    }

    setState(() {
      item.status = successCount > 0 ? DiagnosticStatus.success : DiagnosticStatus.fail;
      item.detail = '成功率: ${(successCount / targets.length * 100).toStringAsFixed(1)}%\n${results.join('\n')}';
    });
  }

  // ---- UI ----

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        Text(
          '网络诊断',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '检测网络连通性和延迟，排查连接问题。',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _isRunning ? null : _runDiagnostic,
          icon: _isRunning
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.play_arrow, size: 18),
          label: Text(_isRunning ? '正在诊断...' : '开始诊断'),
        ),
        const SizedBox(height: 20),
        ..._items.map((item) => _buildItemCard(item)),
      ],
    );
  }

  Widget _buildItemCard(_DiagnosticItem item) {
    final colorScheme = Theme.of(context).colorScheme;

    final IconData? icon;
    final Color iconColor;
    switch (item.status) {
      case DiagnosticStatus.pending:
        icon = Icons.circle_outlined;
        iconColor = colorScheme.onSurfaceVariant;
      case DiagnosticStatus.running:
        icon = null;
        iconColor = colorScheme.primary;
      case DiagnosticStatus.success:
        icon = Icons.check_circle;
        iconColor = Colors.green;
      case DiagnosticStatus.fail:
        icon = Icons.cancel;
        iconColor = Colors.red;
      case DiagnosticStatus.timeout:
        icon = Icons.timer_off;
        iconColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: item.status == DiagnosticStatus.running
                  ? const CircularProgressIndicator(strokeWidth: 2.5)
                  : Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.description,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  if (item.detail != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.detail!,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (item.latencyMs != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _latencyColor(item.latencyMs!).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${item.latencyMs} ms',
                  style: TextStyle(
                    color: _latencyColor(item.latencyMs!),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _latencyColor(int ms) {
    if (ms < 50) return Colors.green;
    if (ms < 150) return Colors.orange;
    return Colors.red;
  }
}
