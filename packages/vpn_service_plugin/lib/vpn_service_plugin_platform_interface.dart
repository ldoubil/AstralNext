import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class VpnServicePluginPlatform extends PlatformInterface {
  VpnServicePluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static VpnServicePluginPlatform? _instance;

  static VpnServicePluginPlatform get instance {
    _instance ??= _UnsupportedPlatform();
    return _instance!;
  }

  static set instance(VpnServicePluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String> prepare() =>
      throw UnimplementedError('prepare() not implemented');
  Future<void> startVpn({
    required String ipv4Addr,
    int mtu = 1500,
    List<String> routes = const [],
    List<String> disallowedApplications = const [],
  }) => throw UnimplementedError('startVpn() not implemented');
  Future<void> stopVpn() =>
      throw UnimplementedError('stopVpn() not implemented');
  Stream<Map<String, dynamic>> get onVpnServiceStarted =>
      throw UnimplementedError('onVpnServiceStarted not implemented');
  Stream<String> get onVpnServiceStopped =>
      throw UnimplementedError('onVpnServiceStopped not implemented');
}

class _UnsupportedPlatform extends VpnServicePluginPlatform {
  @override
  Future<String> prepare() async => 'error_no_activity';

  @override
  Future<void> startVpn({
    required String ipv4Addr,
    int mtu = 1500,
    List<String> routes = const [],
    List<String> disallowedApplications = const [],
  }) async {}

  @override
  Future<void> stopVpn() async {}

  @override
  Stream<Map<String, dynamic>> get onVpnServiceStarted => const Stream.empty();

  @override
  Stream<String> get onVpnServiceStopped => const Stream.empty();
}
