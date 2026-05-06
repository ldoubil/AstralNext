import 'package:get_it/get_it.dart';
import 'package:signals/signals.dart';
import 'package:astral_game/data/services/app_settings_service.dart';

class SettingsState {
  final playerName = signal('Player');
  final closeMinimize = signal(true);
  final userListSimple = signal(true);
  final enableBannerCarousel = signal(true);

  final defaultProtocol = signal('tcp');
  final enableEncryption = signal(true);
  final latencyFirst = signal(false);
  final disableP2p = signal(false);
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
    defaultProtocol.value = settings.getDefaultProtocol();
    enableEncryption.value = settings.getEnableEncryption();
    latencyFirst.value = settings.getLatencyFirst();
    disableP2p.value = settings.isDisableP2p();
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
      settings.setDefaultProtocol(defaultProtocol.value),
      settings.setEnableEncryption(enableEncryption.value),
      settings.setLatencyFirst(latencyFirst.value),
      settings.setDisableP2p(disableP2p.value),
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
}
