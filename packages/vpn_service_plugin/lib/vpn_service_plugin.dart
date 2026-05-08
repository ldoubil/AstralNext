import 'dart:async';

import 'vpn_service_plugin_method_channel.dart';
import 'vpn_service_plugin_platform_interface.dart';

/// VPN 权限状态
enum VpnPermissionStatus {
  granted,
  denied,
  errorNoActivity,
  errorStartActivity,
  unknown,
}

/// VPN 服务插件
class VpnServicePlugin {
  VpnServicePlugin._();

  static final VpnServicePlugin instance = VpnServicePlugin._();
  static bool _initialized = false;

  VpnServicePluginPlatform get _platform {
    if (!_initialized) {
      _initialized = true;
      MethodChannelVpnServicePlugin();
    }
    return VpnServicePluginPlatform.instance;
  }

  Future<VpnPermissionStatus> checkPermission() async {
    final result = await _platform.prepare();
    return _parseStatus(result);
  }

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

  Future<void> startVpn({
    required String ipv4Addr,
    int mtu = 1500,
    List<String> routes = const [],
    List<String> disallowedApplications = const [],
  }) {
    return _platform.startVpn(
      ipv4Addr: ipv4Addr,
      mtu: mtu,
      routes: routes,
      disallowedApplications: disallowedApplications,
    );
  }

  Future<void> stopVpn() => _platform.stopVpn();

  Stream<Map<String, dynamic>> get onVpnServiceStarted =>
      _platform.onVpnServiceStarted;

  Stream<String> get onVpnServiceStopped => _platform.onVpnServiceStopped;
}
