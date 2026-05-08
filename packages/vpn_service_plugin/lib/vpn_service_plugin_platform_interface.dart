import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'vpn_service_plugin_method_channel.dart';

abstract class VpnServicePluginPlatform extends PlatformInterface {
  VpnServicePluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static VpnServicePluginPlatform _instance = MethodChannelVpnServicePlugin();

  static VpnServicePluginPlatform get instance => _instance;

  static set instance(VpnServicePluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String> prepare() => throw UnimplementedError('prepare() not implemented');
  Future<void> startVpn({required String ipv4Addr, int mtu = 1500}) =>
      throw UnimplementedError('startVpn() not implemented');
  Future<void> stopVpn() => throw UnimplementedError('stopVpn() not implemented');
  Stream<Map<String, dynamic>> get onVpnServiceStarted =>
      throw UnimplementedError('onVpnServiceStarted not implemented');
  Stream<String> get onVpnServiceStopped =>
      throw UnimplementedError('onVpnServiceStopped not implemented');
}
