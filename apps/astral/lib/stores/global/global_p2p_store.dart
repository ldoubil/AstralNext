import 'package:get_it/get_it.dart';
import 'package:signals/signals_core.dart';
import 'package:astral_rust_core/p2p_service.dart';

class GlobalP2PStore {
  final _p2pService = GetIt.I<P2PService>();
  final version = Signal<String>("");

  GlobalP2PStore() {
    _p2pService.easytierVersion().then((v) {
      version.value = v;
    });
  }
}
