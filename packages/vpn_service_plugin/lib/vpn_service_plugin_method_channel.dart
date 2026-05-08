import 'dart:async';
import 'package:flutter/services.dart';
import 'vpn_service_plugin_platform_interface.dart';

class MethodChannelVpnServicePlugin extends VpnServicePluginPlatform {
  final _methodChannel = const MethodChannel('vpn_service');
  final _eventChannel = const EventChannel('vpn_service_events');

  StreamController<Map<String, dynamic>>? _startedController;
  StreamController<String>? _stoppedController;
  StreamSubscription? _eventSubscription;

  MethodChannelVpnServicePlugin() {
    VpnServicePluginPlatform.instance = this;
  }

  @override
  Future<String> prepare() async {
    try {
      final result = await _methodChannel.invokeMethod<String>('prepareVpn');
      return result ?? 'unknown';
    } on PlatformException {
      return 'error_start_activity';
    }
  }

  @override
  Future<void> startVpn({required String ipv4Addr, int mtu = 1500}) async {
    await _methodChannel.invokeMethod('startVpn', {
      'ipv4Addr': ipv4Addr,
      'mtu': mtu,
    });
  }

  @override
  Future<void> stopVpn() async {
    await _methodChannel.invokeMethod('stopVpn');
  }

  @override
  Stream<Map<String, dynamic>> get onVpnServiceStarted {
    _startedController ??= StreamController<Map<String, dynamic>>.broadcast();
    _listenEvents();
    return _startedController!.stream;
  }

  @override
  Stream<String> get onVpnServiceStopped {
    _stoppedController ??= StreamController<String>.broadcast();
    _listenEvents();
    return _stoppedController!.stream;
  }

  void _listenEvents() {
    _eventSubscription?.cancel();
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen((event) {
      if (event is Map) {
        final data = Map<String, dynamic>.from(event);
        final type = data['type'] as String?;
        if (type == 'vpn_service_start') {
          _startedController?.add(data);
        } else if (type == 'vpn_service_stop') {
          _stoppedController?.add(type!);
        }
      }
    });
  }
}
