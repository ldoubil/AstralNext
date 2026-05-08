import 'dart:async';
import 'package:flutter/services.dart';
import 'vpn_service_plugin_platform_interface.dart';

class VpnServicePlugin {
  VpnServicePlugin._();

  static final VpnServicePlugin instance = VpnServicePlugin._();

  VpnServicePluginPlatform get _platform => VpnServicePluginPlatform.instance;

  Future<bool> prepare() => _platform.prepare();
  Future<void> startVpn({required String ipv4Addr, int mtu = 1500}) => _platform.startVpn(ipv4Addr: ipv4Addr, mtu: mtu);
  Future<void> stopVpn() => _platform.stopVpn();
  Stream<Map<String, dynamic>> get onVpnServiceStarted => _platform.onVpnServiceStarted;
  Stream<String> get onVpnServiceStopped => _platform.onVpnServiceStopped;
}
