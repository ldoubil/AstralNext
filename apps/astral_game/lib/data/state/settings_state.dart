import 'package:get_it/get_it.dart';
import 'package:signals/signals.dart';
import 'package:astral_game/data/services/app_settings_service.dart';
import 'package:flutter/material.dart';

class SettingsState {
  final playerName = signal('Player');
  final closeMinimize = signal(true);
  final userListSimple = signal(true);
  final enableBannerCarousel = signal(true);
  final themeMode = signal(ThemeMode.system);
  final useDynamicColor = signal(false);
  final seedColor = signal(const Color(0xFF1B4DD7));

  final defaultProtocol = signal('tcp');
  final enableEncryption = signal(true);
  final latencyFirst = signal(false);
  final disableP2p = signal(false);
  /// Windows：局域网 UDP 广播转发到虚拟网（EasyTier `enable_udp_broadcast_relay`）。
  final enableUdpBroadcastRelay = signal(false);
  final dataCompressAlgo = signal(1);

  final listenList = signal<List<String>>([
    'tcp://0.0.0.0:0',
    'udp://0.0.0.0:0',
  ]);

  /// 从持久化存储加载设置
  void loadFromPersistence() {
    final settings = GetIt.I<AppSettingsService>();
    closeMinimize.value = settings.getCloseMinimize();
    userListSimple.value = settings.getUserListSimple();
    enableBannerCarousel.value = settings.getEnableBannerCarousel();
    themeMode.value = _themeModeFromString(settings.getThemeMode());
    useDynamicColor.value = settings.getUseDynamicColor();
    seedColor.value = Color(settings.getSeedColor());
    defaultProtocol.value = settings.getDefaultProtocol();
    enableEncryption.value = settings.getEnableEncryption();
    latencyFirst.value = settings.getLatencyFirst();
    disableP2p.value = settings.isDisableP2p();
    enableUdpBroadcastRelay.value = settings.isEnableUdpBroadcastRelay();
    dataCompressAlgo.value = settings.getDataCompressAlgo();
    listenList.value = settings.getListenList();
  }

  /// 保存所有设置到持久化存储
  Future<void> saveToPersistence() async {
    final settings = GetIt.I<AppSettingsService>();
    await Future.wait([
      settings.setCloseMinimize(closeMinimize.value),
      settings.setUserListSimple(userListSimple.value),
      settings.setEnableBannerCarousel(enableBannerCarousel.value),
      settings.setThemeMode(_themeModeToString(themeMode.value)),
      settings.setUseDynamicColor(useDynamicColor.value),
      settings.setSeedColor(seedColor.value.toARGB32()),
      settings.setDefaultProtocol(defaultProtocol.value),
      settings.setEnableEncryption(enableEncryption.value),
      settings.setLatencyFirst(latencyFirst.value),
      settings.setDisableP2p(disableP2p.value),
      settings.setEnableUdpBroadcastRelay(enableUdpBroadcastRelay.value),
      settings.setDataCompressAlgo(dataCompressAlgo.value),
      settings.setListenList(listenList.value),
    ]);
  }

  void addListenItem(String item) {
    final list = List<String>.from(listenList.value);
    list.add(item);
    listenList.value = list;
    saveToPersistence();
  }

  void updateListenItem(int index, String item) {
    final list = List<String>.from(listenList.value);
    list[index] = item;
    listenList.value = list;
    saveToPersistence();
  }

  void removeListenItem(int index) {
    final list = List<String>.from(listenList.value);
    list.removeAt(index);
    listenList.value = list;
    saveToPersistence();
  }

  static ThemeMode _themeModeFromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  static String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
