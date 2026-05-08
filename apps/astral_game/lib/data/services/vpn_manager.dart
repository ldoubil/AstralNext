import 'dart:async';
import 'dart:io';

import 'package:astral_game/data/state/vpn_state.dart';
import 'package:astral_game/utils/logger.dart';
import 'package:astral_rust_core/p2p_service.dart';

/// VPN 管理器
///
/// 负责 Android VPN 生命周期管理
class VpnManager {
  final VpnState vpnState;
  final P2PService _p2pService;

  VpnManager(this.vpnState, this._p2pService);

  StreamSubscription<Map<String, dynamic>>? _startedSubscription;
  StreamSubscription<String>? _stoppedSubscription;

  /// 是否为 Android 平台
  bool get _isAndroid => Platform.isAndroid;

  /// 准备 VPN 权限（仅 Android）
  Future<bool> prepare() async {
    if (!_isAndroid) return false;

    try {
      // Android VPN 权限请求需要通过 VPN Service Plugin
      // 暂时返回 true，后续集成 vpn_service_plugin 后完善
      return true;
    } catch (e) {
      appLogger.e('[VpnManager] 准备 VPN 失败: $e');
      return false;
    }
  }

  /// 启动 VPN（仅 Android）
  Future<void> start({
    required String ipv4Addr,
    int mtu = 1500,
  }) async {
    if (!_isAndroid) return;

    try {
      vpnState.setConnecting(true);
      vpnState.setIpv4Addr(ipv4Addr);
      vpnState.setMtu(mtu);

      // TODO: 集成 vpn_service_plugin 后实现
      // await VpnServicePlugin.instance.startVpn(ipv4Addr: ipv4Addr, mtu: mtu);

      vpnState.setRunning(true);
      vpnState.setConnecting(false);
      appLogger.i('[VpnManager] VPN 已启动: $ipv4Addr');
    } catch (e) {
      vpnState.setConnecting(false);
      appLogger.e('[VpnManager] 启动 VPN 失败: $e');
    }
  }

  /// 停止 VPN（仅 Android）
  Future<void> stop() async {
    if (!_isAndroid) return;

    try {
      // TODO: 集成 vpn_service_plugin 后实现
      // await VpnServicePlugin.instance.stopVpn();

      vpnState.setRunning(false);
      vpnState.setConnecting(false);
      appLogger.i('[VpnManager] VPN 已停止');
    } catch (e) {
      appLogger.e('[VpnManager] 停止 VPN 失败: $e');
    }
  }

  /// 配置 TUN 文件描述符
  ///
  /// Android VPN 服务启动后会返回 TUN 设备的文件描述符
  /// 需要传递给 Rust 层的 easytier 引擎
  Future<void> configureTunFd(String instanceId, int fd) async {
    try {
      await _p2pService.setTunFd(instanceId, fd);
      appLogger.i('[VpnManager] TUN FD 已配置: $fd');
    } catch (e) {
      appLogger.e('[VpnManager] 配置 TUN FD 失败: $e');
    }
  }

  /// 释放资源
  void dispose() {
    _startedSubscription?.cancel();
    _stoppedSubscription?.cancel();
  }
}
