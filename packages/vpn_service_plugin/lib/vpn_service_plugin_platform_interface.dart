import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class VpnServicePluginPlatform extends PlatformInterface {
  VpnServicePluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static VpnServicePluginPlatform _instance = MethodChannelVpnServicePlugin();

  static VpnServicePluginPlatform get instance => _instance;

  static set instance(VpnServicePluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// 检查/请求 VPN 权限
  ///
  /// 返回字符串状态：'granted' / 'denied' / 'error_no_activity' / 'error_start_activity'
  Future<String> prepare() => throw UnimplementedError('prepare() not implemented');

  Future<void> startVpn({required String ipv4Addr, int mtu = 1500}) =>
      throw UnimplementedError('startVpn() not implemented');

  Future<void> stopVpn() => throw UnimplementedError('stopVpn() not implemented');

  Stream<Map<String, dynamic>> get onVpnServiceStarted =>
      throw UnimplementedError('onVpnServiceStarted not implemented');

  Stream<String> get onVpnServiceStopped =>
      throw UnimplementedError('onVpnServiceStopped not implemented');
}
