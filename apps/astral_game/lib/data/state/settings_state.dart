import 'package:signals/signals.dart';

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

  void addListenItem(String item) {
    final list = List<String>.from(listenList.value);
    list.add(item);
    listenList.value = list;
  }

  void updateListenItem(int index, String item) {
    final list = List<String>.from(listenList.value);
    list[index] = item;
    listenList.value = list;
  }

  void removeListenItem(int index) {
    final list = List<String>.from(listenList.value);
    list.removeAt(index);
    listenList.value = list;
  }
}
