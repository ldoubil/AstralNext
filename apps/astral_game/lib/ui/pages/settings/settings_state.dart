import 'package:get_it/get_it.dart';
import 'package:signals/signals.dart';

class SettingsState {
  // 通用设置
  final playerName = signal('Player');
  final closeMinimize = signal(true);
  final userListSimple = signal(true);
  final enableBannerCarousel = signal(true);

  // 网络设置
  final defaultProtocol = signal('tcp');
  final enableEncryption = signal(true);
  final latencyFirst = signal(false);
  final disableP2p = signal(false);
  final dataCompressAlgo = signal(1);

  // 监听列表
  final listenList = signal<List<String>>([
    'tcp://0.0.0.0:0',
    'udp://0.0.0.0:0',
  ]);
}

SettingsState get settingsState => GetIt.I<SettingsState>();
