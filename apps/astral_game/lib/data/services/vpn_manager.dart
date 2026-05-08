import 'dart:async';
import 'dart:io';

import 'package:astral_game/data/state/vpn_state.dart';
import 'package:astral_game/utils/logger.dart';
import 'package:astral_rust_core/p2p_service.dart';
import 'package:vpn_service_plugin/vpn_service_plugin.dart';

/// VPN 管理器
///
/// 负责 Android VPN 权限检查、生命周期管理和 TUN FD 配置
class VpnManager {
  final VpnState vpnState;
  final P2PService _p2pService;

  VpnManager(this.vpnState, this._p2pService);

  StreamSubscription<Map<String, dynamic>>? _startedSubscription;
  StreamSubscription<String>? _stoppedSubscription;
  String? _currentInstanceId;
  bool _isListening = false;

  /// 是否为 Android 平台
  bool get _isAndroid => Platform.isAndroid;

  /// 当前权限状态
  VpnPermissionStatus _permissionStatus = VpnPermissionStatus.unknown;
  VpnPermissionStatus get permissionStatus => _permissionStatus;

  /// 权限是否已授予
  bool get hasPermission => _permissionStatus == VpnPermissionStatus.granted;

  /// 检查 VPN 权限（不弹窗）
  ///
  /// 如果权限已授予返回 true，否则返回 false
  Future<bool> checkPermission() async {
    if (!_isAndroid) return true;

    try {
      final status = await VpnServicePlugin.instance.checkPermission();
      _permissionStatus = status;
      return status == VpnPermissionStatus.granted;
    } catch (e) {
      appLogger.e('[VpnManager] 检查 VPN 权限失败: $e');
      _permissionStatus = VpnPermissionStatus.unknown;
      return false;
    }
  }

  /// 请求 VPN 权限（弹出系统对话框）
  ///
  /// 返回用户是否授予了权限
  Future<bool> requestPermission() async {
    if (!_isAndroid) return true;

    try {
      final status = await VpnServicePlugin.instance.requestPermission();
      _permissionStatus = status;

      if (status == VpnPermissionStatus.granted) {
        appLogger.i('[VpnManager] VPN 权限已授予');
        return true;
      } else if (status == VpnPermissionStatus.denied) {
        appLogger.w('[VpnManager] VPN 权限被拒绝');
      } else {
        appLogger.e('[VpnManager] VPN 权限请求失败: $status');
      }
      return false;
    } catch (e) {
      appLogger.e('[VpnManager] 请求 VPN 权限异常: $e');
      _permissionStatus = VpnPermissionStatus.unknown;
      return false;
    }
  }

  /// 确保 VPN 权限已授予
  ///
  /// 先检查，如果没有权限则请求。
  /// 返回 true 表示权限已就绪，false 表示用户拒绝或请求失败。
  Future<bool> ensurePermission() async {
    if (await checkPermission()) return true;
    return requestPermission();
  }

  /// 启动 VPN（仅 Android）
  ///
  /// 自动检查权限，未授权时先请求权限。
  /// 返回 true 表示 VPN 已成功启动，false 表示启动失败。
  Future<bool> start({
    required String instanceId,
    required String ipv4Addr,
    int mtu = 1500,
  }) async {
    if (!_isAndroid) return true;

    // 确保权限已授予
    if (!await ensurePermission()) {
      appLogger.w('[VpnManager] VPN 权限未授予，无法启动');
      return false;
    }

    try {
      vpnState.setConnecting(true);
      final finalIpv4Addr = _withDefaultPrefix(ipv4Addr);
      vpnState.setIpv4Addr(finalIpv4Addr);
      vpnState.setMtu(mtu);
      _currentInstanceId = instanceId;

      await VpnServicePlugin.instance.startVpn(
        ipv4Addr: finalIpv4Addr,
        mtu: mtu,
        routes: vpnState.customRoutes.value,
        disallowedApplications: const ['com.example.astral_game'],
      );

      vpnState.setRunning(true);
      vpnState.setConnecting(false);
      appLogger.i('[VpnManager] VPN 已启动: $finalIpv4Addr');
      return true;
    } catch (e) {
      vpnState.setConnecting(false);
      appLogger.e('[VpnManager] 启动 VPN 失败: $e');
      return false;
    }
  }

  /// 停止 VPN（仅 Android）
  Future<void> stop() async {
    if (!_isAndroid) return;

    try {
      await VpnServicePlugin.instance.stopVpn();

      vpnState.setRunning(false);
      vpnState.setConnecting(false);
      _currentInstanceId = null;
      appLogger.i('[VpnManager] VPN 已停止');
    } catch (e) {
      appLogger.e('[VpnManager] 停止 VPN 失败: $e');
    }
  }

  /// 配置 TUN 文件描述符
  ///
  /// Android VPN 服务启动后会返回 TUN 设备的文件描述符
  /// 需要传递给 Rust 层的 easytier 引擎
  Future<void> configureTunFd(int fd) async {
    final instanceId = _currentInstanceId;
    if (instanceId == null) {
      appLogger.w('[VpnManager] 无活跃实例，跳过 TUN FD 配置');
      return;
    }

    try {
      await _p2pService.setTunFd(instanceId, fd);
      appLogger.i('[VpnManager] TUN FD 已配置: $fd (instance: $instanceId)');
    } catch (e) {
      appLogger.e('[VpnManager] 配置 TUN FD 失败: $e');
    }
  }

  /// 监听 VPN 服务事件
  void startListening() {
    if (_isListening) return;
    _isListening = true;
    _startedSubscription?.cancel();
    _stoppedSubscription?.cancel();

    _startedSubscription = VpnServicePlugin.instance.onVpnServiceStarted.listen(
      (data) {
        final fd = data['fd'] as int?;
        if (fd != null) {
          configureTunFd(fd);
        }
      },
      onError: (e) => appLogger.e('[VpnManager] VPN 启动事件监听错误: $e'),
    );

    _stoppedSubscription = VpnServicePlugin.instance.onVpnServiceStopped.listen(
      (_) {
        vpnState.setRunning(false);
        vpnState.setConnecting(false);
        _currentInstanceId = null;
        appLogger.i('[VpnManager] VPN 服务已停止');
      },
      onError: (e) => appLogger.e('[VpnManager] VPN 停止事件监听错误: $e'),
    );
  }

  /// 释放资源
  void dispose() {
    _startedSubscription?.cancel();
    _stoppedSubscription?.cancel();
    _startedSubscription = null;
    _stoppedSubscription = null;
    _isListening = false;
  }

  String _withDefaultPrefix(String ipv4Addr) {
    final trimmed = ipv4Addr.trim();
    if (trimmed.isEmpty) return '100.100.100.0/24';
    return trimmed.contains('/') ? trimmed : '$trimmed/24';
  }
}
