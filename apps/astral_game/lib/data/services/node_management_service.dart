import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:get_it/get_it.dart';
import 'package:signals/signals_core.dart';
import 'package:astral_game/utils/logger.dart';
import 'package:astral_game/config/constants.dart';
import 'package:astral_rust_core/p2p_service.dart';
import 'package:astral_rust_core/src/rust/api/p2p.dart'
    show KVNetworkStatus, myPeerId;

import '../models/enhanced_node_info.dart';
import 'app_settings_service.dart';
import 'peer_rpc/peer_rpc_client.dart';
import 'peer_rpc/peer_rpc_exception.dart';

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

  /// 本机的虚拟网 IPv4（不带 CIDR）。轮询时从 `userNodes` 中取 peer_id=0 的
  /// 哨兵节点的 ipv4。未连接 / 尚未拿到地址 / DHCP 未分配时为空字符串。
  final myVirtualIpv4 = signal<String>('');

  Timer? _pollingTimer;
  int _pollTick = 0;

  /// 本机在当前 EasyTier instance 内的 peer_id。`null` 表示尚未取到（首次轮询
  /// 期间会在后台异步刷新）。用于在拉取资料时把"自己"过滤掉，避免无意义的
  /// 自调自请求把日志刷到屏幕上。
  int? _myPeerId;

  /// `astral_rust_core` 为本机节点合成的哨兵 peer_id（见 `LOCAL_SYNTHETIC_PEER_ID`）。
  /// 这是一个常量 0；它会出现在 `userNodes` 里但不是真实的可寻址节点。
  static const int _localSyntheticPeerId = 0;

  /// 轮询间隔（用户列表需要更及时：1 秒）
  static const Duration _pollingInterval = Duration(seconds: 1);

  String? get instanceId => currentInstanceId.value;
  bool get isRunning => currentInstanceId.value != null;

  /// 启动节点管理
  void start(String instanceId) {
    currentInstanceId.value = instanceId;
    _myPeerId = null;
    // 后台异步取本机 peer_id，不阻塞 polling 启动；取到之前 polling 已经会用
    // `peerId == 0` 这个守卫挡掉合成本机节点。
    unawaited(_refreshMyPeerId(instanceId));
    _startPolling(instanceId);
    appLogger.i('[NodeManagementService] 已启动，实例ID: $instanceId');
  }

  /// 停止节点管理
  void stop() {
    _stopPolling();
    currentInstanceId.value = null;
    _myPeerId = null;
    userNodes.value = [];
    myVirtualIpv4.value = '';
    appLogger.i('[NodeManagementService] 已停止');
  }

  Future<void> _refreshMyPeerId(String instanceId) async {
    try {
      final id = await myPeerId(instanceId: instanceId);
      // 防止 stop() 之后才返回时把状态污染回去。
      if (currentInstanceId.value == instanceId) {
        _myPeerId = id;
        if (_verbosePollLogs) {
          appLogger.d('[NodeManagementService] 本机 peer_id=$id');
        }
      }
    } catch (e) {
      appLogger.w('[NodeManagementService] 获取本机 peer_id 失败: $e');
    }
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
        final prev = currentNodes[node.peerId];
        var enhanced = EnhancedNodeInfo(
          baseInfo: node,
          // 合并已有用户资料，避免每次重建都丢失 avatar/customName
          customName: prev?.customName,
          avatar: prev?.avatar,
        );
        // 本机条目（合成哨兵 peer_id=0 或真实本机 peer_id）直接用本地资料填充，
        // 不走 RPC：自己问自己没意义，而且能保证 UI 列表里"自己"始终最新。
        if (_isLocalPeer(node.peerId)) {
          enhanced = _enrichLocalNode(enhanced);
        }
        newNodes[node.peerId] = enhanced;
      }

      // 纯周期获取：每次轮询都全量覆盖列表（不依赖事件驱动）
      final normalized = newNodes.values.toList()
        ..sort((a, b) => a.peerId.compareTo(b.peerId));

      userNodes.value = normalized;

      // 本机虚拟 IP：优先取 `astral_rust_core` 合成的本机哨兵节点（peer_id=0）
      // 的 ipv4；个别状态下 EasyTier 的 routes 表里也可能直接给本机一条
      // 真实 peer_id 的条目，做一个兜底匹配。任意一种都拿不到时清空。
      final myIp = _resolveMyVirtualIpv4(normalized);
      if (myIp != myVirtualIpv4.value) {
        myVirtualIpv4.value = myIp;
      }

      if (_verbosePollLogs) {
        // 每秒打印“本次实际获取到的节点列表”（非常刷屏）
        final nodesPreview = normalized
            .map((n) => '${n.peerId}:${n.hostname}:${n.ipv4.split('/').first}')
            .join(', ');
        appLogger.d(
          '[NodeManagementService] poll users(total=${normalized.length}, rawTotal=$newTotalNodes) [$nodesPreview]',
        );
      }

      // 同步拉取对端资料（昵称/头像），不做冷却。本机会被 _fetchNodeInfo 内部
      // 的守卫直接 return；这里循环里也提前过滤一下，省一次方法调用。
      for (final n in normalized) {
        if (_isPublicServerNode(n)) continue;
        if (_isLocalPeer(n.peerId)) continue;
        _fetchNodeInfo(n);
      }
    } catch (e, stackTrace) {
      appLogger.e('[NodeManagementService] 轮询网络状态失败: $e', error: e, stackTrace: stackTrace);
    }
  }

  /// 判断给定 peer_id 是否对应"本机"（合成哨兵或真实本机）。
  bool _isLocalPeer(int peerId) =>
      peerId == _localSyntheticPeerId ||
      (_myPeerId != null && peerId == _myPeerId);

  /// 从节点列表里挑出"本机"的虚拟 IPv4（去掉 CIDR 后缀），找不到返回空串。
  String _resolveMyVirtualIpv4(List<EnhancedNodeInfo> nodes) {
    EnhancedNodeInfo? candidate;
    for (final n in nodes) {
      if (!_isLocalPeer(n.peerId)) continue;
      // 优先选有合法 IPv4 的本机条目；若全都没有，至少返回第一条本机
      if (n.hasValidIpv4) return n.ipv4.split('/').first.trim();
      candidate ??= n;
    }
    if (candidate == null) return '';
    final raw = candidate.ipv4.split('/').first.trim();
    return raw == '0.0.0.0' ? '' : raw;
  }

  /// 把本地持久化的用户名/头像盖到一个本机 [`EnhancedNodeInfo`] 上。
  /// 仅当本地有值时覆盖；本地清空（用户重置头像）也会下沉到 UI 上。
  EnhancedNodeInfo _enrichLocalNode(EnhancedNodeInfo node) {
    final localName = _appSettings.getUsername().trim();
    final localAvatar = _appSettings.getAvatar();
    return node.copyWith(
      customName: localName.isEmpty ? node.customName : localName,
      avatar: localAvatar ?? node.avatar,
    );
  }

  bool _isPublicServerNode(EnhancedNodeInfo node) {
    // 公共服务器节点不一定有可直连的虚拟网 IP（可能为空/0.0.0.0），
    // 且其用途是“中转/目录”，不需要进行 user.getInfo / user.update 探测。
    return node.hostname.startsWith(AppConstants.publicServerHostname);
  }

  /// 获取节点信息（头像和昵称）
  ///
  /// 走 peer-RPC 的 `user.getInfo` channel，路由由 EasyTier 负责，调用方只需要
  /// 知道目标节点的 `peerId`。
  Future<void> _fetchNodeInfo(EnhancedNodeInfo node) async {
    if (_isPublicServerNode(node)) return;

    // 跳过本机节点：
    //   - peer_id == 0 是 `astral_rust_core` 合成的本机哨兵（见 LOCAL_SYNTHETIC_PEER_ID）；
    //   - peer_id == _myPeerId 是真正的本机，避免自调自陷入超时。
    if (node.peerId == _localSyntheticPeerId) return;
    if (_myPeerId != null && node.peerId == _myPeerId) return;

    final client = GetIt.I<PeerRpcClient>();
    if (!client.isBound) return;

    try {
      final result = await client.call(node.peerId, 'user.getInfo');

      if (result is Map) {
        final name = result['name'] as String?;
        final avatarBytes = result['avatar'] != null
            ? base64Decode(result['avatar'] as String)
            : null;

        if (name != null || avatarBytes != null) {
          _updateNodeInfo(node.peerId, name: name, avatar: avatarBytes);
        }
      }
    } on RpcException catch (e) {
      // 对端不可达 / 暂未运行 astral_game：每秒轮询很容易刷屏，统一降到 debug。
      //   -1     NO_SUBSCRIBER：对端跑的不是 astral_game（或 router 还没起）。
      //   -2     REPLY_TIMEOUT：对端 handler 超时未回复。
      //   -32000 客户端等待响应超时（PeerRpcClient 翻译过的本端 RPC timeout）。
      //   -32603 通用内部错误（包括底层 anyhow! 的 Timeout 字符串）。
      if (e.code == -1 ||
          e.code == -2 ||
          e.code == -32000 ||
          e.code == -32603) {
        if (_verbosePollLogs) {
          appLogger.d(
            '[NodeManagementService] 拉取节点信息失败(忽略) peer=${node.peerId} code=${e.code}: ${e.message}',
          );
        }
        return;
      }
      appLogger.w(
        '[NodeManagementService] 获取节点信息失败 peer=${node.peerId} code=${e.code}: ${e.message}',
      );
    } catch (e) {
      appLogger.e('[NodeManagementService] 获取节点信息异常 peer=${node.peerId}: $e');
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
    _refreshLocalNodesFromSettings();
  }

  /// 更新当前用户名
  Future<void> updateCurrentUsername(String username) async {
    currentUsername.value = username;
    await _appSettings.setUsername(username);
    appLogger.i('[NodeManagementService] 用户名已更新: $username');
    _refreshLocalNodesFromSettings();
  }

  /// 把最新的本地用户名/头像同步到 [`userNodes`] 列表里的本机条目，省得等下一次
  /// 1 秒轮询才在 UI 上看到变更。
  void _refreshLocalNodesFromSettings() {
    final nodes = userNodes.value;
    if (nodes.isEmpty) return;
    var changed = false;
    final updated = nodes.map((n) {
      if (!_isLocalPeer(n.peerId)) return n;
      final enriched = _enrichLocalNode(n);
      if (!identical(enriched, n)) changed = true;
      return enriched;
    }).toList();
    if (changed) {
      userNodes.value = updated;
    }
  }

  /// 释放资源
  void dispose() {
    stop();
    appLogger.i('[NodeManagementService] 资源已释放');
  }
}