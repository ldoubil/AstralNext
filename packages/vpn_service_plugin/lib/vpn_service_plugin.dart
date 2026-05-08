import 'dart:async';

import 'vpn_service_plugin_platform_interface.dart';

/// VPN 权限状态
enum VpnPermissionStatus {
  /// 权限已授予
  granted,

  /// 权限被拒绝
  denied,

  /// 没有 Activity（无法请求权限）
  errorNoActivity,

  /// 启动权限请求 Activity 失败
  errorStartActivity,

  /// 未知状态
  unknown,
}

/// VPN 服务插件
class VpnServicePlugin {
  VpnServicePlugin._();

  static final VpnServicePlugin instance = VpnServicePlugin._();

  VpnServicePluginPlatform get _platform => VpnServicePluginPlatform.instance;

  /// 检查 VPN 权限
  ///
  /// 返回 [VpnPermissionStatus]:
  /// - [VpnPermissionStatus.granted]: 权限已授予
  /// - [VpnPermissionStatus.denied]: 用户拒绝了权限
  /// - [VpnPermissionStatus.errorNoActivity]: 没有 Activity
  Future<VpnPermissionStatus> checkPermission() async {
    final result = await _platform.prepare();
    return _parseStatus(result);
  }

  /// 请求 VPN 权限
  ///
  /// 会弹出系统 VPN 权限对话框
  /// 返回 [VpnPermissionStatus]:
  /// - [VpnPermissionStatus.granted]: 用户授予了权限
  /// - [VpnPermissionStatus.denied]: 用户拒绝了权限
  Future<VpnPermissionStatus> requestPermission() async {
    final result = await _platform.prepare();
    return _parseStatus(result);
  }

  VpnPermissionStatus _parseStatus(String result) {
    switch (result) {
      case 'granted':
        return VpnPermissionStatus.granted;
      case 'denied':
        return VpnPermissionStatus.denied;
      case 'error_no_activity':
        return VpnPermissionStatus.errorNoActivity;
      case 'error_start_activity':
        return VpnPermissionStatus.errorStartActivity;
      default:
        return VpnPermissionStatus.unknown;
    }
  }

  /// 启动 VPN
  Future<void> startVpn({required String ipv4Addr, int mtu = 1500}) {
    return _platform.startVpn(ipv4Addr: ipv4Addr, mtu: mtu);
  }

  /// 停止 VPN
  Future<void> stopVpn() => _platform.stopVpn();

  /// VPN 服务启动事件（返回 TUN fd）
  Stream<Map<String, dynamic>> get onVpnServiceStarted =>
      _platform.onVpnServiceStarted;

  /// VPN 服务停止事件
  Stream<String> get onVpnServiceStopped =>
      _platform.onVpnServiceStopped;
}
