import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:get_it/get_it.dart';
import 'package:signals/signals_core.dart';
import 'package:astral_game/utils/logger.dart';
import 'package:astral_game/config/constants.dart';
import 'package:astral_rust_core/p2p_service.dart';
import 'package:astral_rust_core/src/rust/api/p2p.dart' show KVNetworkStatus;

import '../models/enhanced_node_info.dart';
import 'app_settings_service.dart';
import 'node_net/node_net_client.dart';

/// 节点管理服务
///
/// 负责：
/// - 管理网络中的节点信息
/// - 轮询网络状态
/// - 获取节点头像和昵称
/// - 发送节点事件
class NodeManagementService {
  final _p2pService = GetIt.I<P2PService>();
  final _appSettings = GetIt.I<AppSettingsService>();

  /// 是否打印“每秒轮询细节”日志（非常刷屏，默认关闭）
  static const bool _verbosePollLogs = false;

  /// 用户节点列表
  final userNodes = signal<List<EnhancedNodeInfo>>([]);
  
  /// 当前实例 ID
  final currentInstanceId = signal<String?>(null);
  
  /// 网络状态
  final networkStatus = signal<KVNetworkStatus?>(null);
  
  /// 当前用户头像
  final currentUserAvatar = signal<Uint8List?>(null);
  
  /// 当前用户名
  final currentUsername = signal<String>('');

  Timer? _pollingTimer;
  int _pollTick = 0;

  /// 轮询间隔（用户列表需要更及时：1 秒）
  static const Duration _pollingInterval = Duration(seconds: 1);

  // 按需求：不做冷却，轮询时直接刷新昵称/头像

  String? get instanceId => currentInstanceId.value;
  bool get isRunning => currentInstanceId.value != null;

  /// 启动节点管理
  void start(String instanceId) {
    currentInstanceId.value = instanceId;
    _startPolling(instanceId);
    appLogger.i('[NodeManagementService] 已启动，实例ID: $instanceId');
  }

  /// 停止节点管理
  void stop() {
    _stopPolling();
    currentInstanceId.value = null;
    userNodes.value = [];
    appLogger.i('[NodeManagementService] 已停止');
  }

  /// 开始轮询网络状态
  void _startPolling(String instanceId) {
    _stopPolling();
    _pollNetworkStatus(instanceId);
    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      if (_verbosePollLogs) {
        // 用于确认轮询“确实在每秒触发”（非常刷屏）
        _pollTick++;
        appLogger.d('[NodeManagementService] poll tick=$_pollTick');
      }
      _pollNetworkStatus(instanceId);
    });
  }

  /// 停止轮询
  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// 轮询网络状态
  ///
  /// 获取最新的网络状态和节点信息
  Future<void> _pollNetworkStatus(String instanceId) async {
    try {
      final status = await _p2pService.getNetworkStatus(instanceId);
      final newTotalNodes = status.totalNodes;
      final newNodesList = status.nodes;

      // 旧项目里网络状态是“持续更新”的；这里如果只在数量变化时更新，
      // 会导致 latency/loss/cost/hops 等字段变化无法及时反映到 UI。
      networkStatus.value = KVNetworkStatus(
        totalNodes: newTotalNodes,
        nodes: List.from(newNodesList),
      );

      final currentNodes = Map<int, EnhancedNodeInfo>.fromEntries(
        userNodes.value.map((node) => MapEntry(node.peerId, node)),
      );

      // 每次轮询都“重建一份规范化节点表”，避免历史列表里混入重复项后无法被增量逻辑清理。
      // 去重主键：peerId（Rust 侧也会去重，但这里兜底保证 UI 列表不出现重复条目）。
      final newNodes = <int, EnhancedNodeInfo>{};
      for (final node in newNodesList) {
        // 公共服务器仅用于中继/目录，不应出现在“在线用户”列表。
        if (node.hostname.startsWith(AppConstants.publicServerHostname)) continue;
        final port = _parsePortFromHostname(node.hostname);
        final prev = currentNodes[node.peerId];
        newNodes[node.peerId] = EnhancedNodeInfo(
          baseInfo: node,
          port: port,
          // 合并已有用户资料，避免每次重建都丢失 avatar/customName
          customName: prev?.customName,
          avatar: prev?.avatar,
        );
      }

      // 纯周期获取：每次轮询都全量覆盖列表（不依赖事件驱动）
      final normalized = newNodes.values.toList()
        ..sort((a, b) => a.peerId.compareTo(b.peerId));

      userNodes.value = normalized;

      if (_verbosePollLogs) {
        // 每秒打印“本次实际获取到的节点列表”（非常刷屏）
        final nodesPreview = normalized
            .map((n) => '${n.peerId}:${n.hostname}:${_normalizeIpv4(n.ipv4)}')
            .join(', ');
        appLogger.d(
          '[NodeManagementService] poll users(total=${normalized.length}, rawTotal=$newTotalNodes) [$nodesPreview]',
        );
      }

      // 同步拉取资料（昵称/头像），不做冷却；不推送自己的资料。
      for (final n in normalized) {
        if (_isPublicServerNode(n)) continue;
        final ip = _normalizeIpv4(n.ipv4);
        if (!isValidIp(ip)) continue;
        _fetchNodeInfo(n);
      }
    } catch (e, stackTrace) {
      appLogger.e('[NodeManagementService] 轮询网络状态失败: $e', error: e, stackTrace: stackTrace);
    }
  }

  /// 从主机名解析端口号
  int? _parsePortFromHostname(String hostname) {
    try {
      return int.parse(hostname);
    } catch (e) {
      return null;
    }
  }

  /// 规范化节点 IPv4（兼容 CIDR: "x.x.x.x/24" -> "x.x.x.x"）
  String _normalizeIpv4(String raw) {
    final trimmed = raw.trim();
    final slash = trimmed.indexOf('/');
    return (slash >= 0 ? trimmed.substring(0, slash) : trimmed).trim();
  }

  bool _isPublicServerNode(EnhancedNodeInfo node) {
    // 公共服务器节点不一定有可直连的虚拟网 IP（可能为空/0.0.0.0），
    // 且其用途是“中转/目录”，不需要进行 user.getInfo / user.update 探测。
    return node.hostname.startsWith(AppConstants.publicServerHostname);
  }

  /// 获取节点信息（头像和昵称）
  Future<void> _fetchNodeInfo(EnhancedNodeInfo node) async {
    if (_isPublicServerNode(node)) return;
    final ip = _normalizeIpv4(node.ipv4);
    final port = node.port ?? 4924;
    if (!isValidIp(ip)) return;

    try {
      final client = GetIt.I<NodeNetClient>();
      final result = await client.call(ip, port, 'user.getInfo');

      if (result != null) {
        final name = result['name'] as String?;
        final avatarBytes = result['avatar'] != null
            ? base64Decode(result['avatar'] as String)
            : null;

        if (name != null || avatarBytes != null) {
          _updateNodeInfo(node.peerId, name: name, avatar: avatarBytes);
        }
      }
    } catch (e) {
      appLogger.e('[NodeManagementService] 获取节点信息失败 $ip:$port: $e');
    }
  }

  /// 批量更新节点信息（头像和/或昵称），单次 signal 触发
  void _updateNodeInfo(int peerId, {String? name, Uint8List? avatar}) {
    userNodes.value = userNodes.value.map((n) {
      if (n.peerId == peerId) {
        return n.copyWith(
          customName: name ?? n.customName,
          avatar: avatar ?? n.avatar,
        );
      }
      return n;
    }).toList();
  }

  /// 初始化用户信息
  ///
  /// 从持久化存储加载用户名和头像
  void initUserInfo() {
    currentUsername.value = _appSettings.getUsername();
    final avatar = _appSettings.getAvatar();
    if (avatar != null) {
      currentUserAvatar.value = avatar;
    }
    appLogger.i('[NodeManagementService] 用户信息已初始化: ${currentUsername.value}');
  }

  /// 设置运行状态
  void setRunning(String instanceId) {
    start(instanceId);
  }

  /// 设置停止状态
  void setStopped() {
    stop();
  }

  /// 检查 IP 是否有效
  bool isValidIp(String ip) {
    final normalized = _normalizeIpv4(ip);
    if (normalized.isEmpty) return false;
    return normalized != '0.0.0.0';
  }

  /// 更新当前用户头像
  Future<void> updateCurrentUserAvatar(Uint8List? avatar) async {
    currentUserAvatar.value = avatar;
    if (avatar != null) {
      await _appSettings.setAvatar(avatar);
      appLogger.i('[NodeManagementService] 用户头像已更新');
    } else {
      await _appSettings.clearAvatar();
      appLogger.i('[NodeManagementService] 用户头像已清除');
    }
  }

  /// 更新当前用户名
  Future<void> updateCurrentUsername(String username) async {
    currentUsername.value = username;
    await _appSettings.setUsername(username);
    appLogger.i('[NodeManagementService] 用户名已更新: $username');
  }

  /// 释放资源
  void dispose() {
    stop();
    appLogger.i('[NodeManagementService] 资源已释放');
  }
}