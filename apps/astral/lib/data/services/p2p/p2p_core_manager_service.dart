import 'package:astral/data/services/p2p/p2p_core_instance.dart';

class P2pCoreManagerService {
  final Map<String, P2pCoreInstance> _instances = {};

  P2pCoreInstance? getInstance(String id) => _instances[id];
}
