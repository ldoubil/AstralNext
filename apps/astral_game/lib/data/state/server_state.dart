import 'dart:async';
import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:signals/signals.dart';
import 'package:astral_game/ui/pages/servers/server_mod.dart';

typedef ServerPersistenceCallback = Future<List<ServerMod>> Function();
typedef ServerSaveCallback = Future<void> Function(List<ServerMod>);

enum ServerStatus {
  online,
  offline,
  inUse,
  unknown,
}

class ServerState {
  final servers = signal<List<ServerMod>>([]);
  ServerPersistenceCallback? _loadCallback;
  ServerSaveCallback? _saveCallback;

  void setPersistenceCallbacks({
    required ServerPersistenceCallback loadCallback,
    required ServerSaveCallback saveCallback,
  }) {
    _loadCallback = loadCallback;
    _saveCallback = saveCallback;
  }

  Future<void> loadFromPersistence() async {
    if (_loadCallback != null) {
      final loaded = await _loadCallback!();
      servers.value = loaded;
    }
  }

  Future<void> _saveToPersistence() async {
    if (_saveCallback != null) {
      await _saveCallback!(servers.value);
    }
  }

  void setServers(List<ServerMod> serverList) {
    servers.value = serverList;
    _saveToPersistence();
  }

  void addServer(ServerMod server) {
    final list = List<ServerMod>.from(servers.value);
    list.add(server);
    servers.value = list;
    _saveToPersistence();
  }

  void removeServer(int id) {
    final list = servers.value.where((s) => s.id != id).toList();
    servers.value = list;
    _saveToPersistence();
  }

  void updateServer(ServerMod updatedServer) {
    final list = servers.value.map((s) {
      return s.id == updatedServer.id ? updatedServer : s;
    }).toList();
    servers.value = list;
    _saveToPersistence();
  }

  void reorderServers(List<ServerMod> reordered) {
    servers.value = reordered;
    _saveToPersistence();
  }

  void toggleServerEnabled(int id, bool enabled) {
    final list = servers.value.map((s) {
      if (s.id == id) {
        return s.copyWith(enable: enabled);
      }
      return s;
    }).toList();
    servers.value = list;
    _saveToPersistence();
  }

  ServerMod? getServerById(int id) {
    try {
      return servers.value.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  List<ServerMod> getEnabledServers() {
    return servers.value.where((s) => s.enable).toList();
  }
}

class ServerStatusState {
  final serverStatuses = signal<Map<int, ServerStatus>>({});
  final activeServerIds = signal<Set<int>>({});
  Timer? _checkTimer;

  void startPeriodicCheck(List<ServerMod> servers, Duration interval) {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(interval, (_) {
      checkServersStatus(servers);
    });
    checkServersStatus(servers);
  }

  void stopPeriodicCheck() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  Future<void> checkServersStatus(List<ServerMod> servers) async {
    final Map<int, ServerStatus> newStatuses = {};
    final activeIds = activeServerIds.value;

    for (final server in servers) {
      if (activeIds.contains(server.id)) {
        newStatuses[server.id] = ServerStatus.inUse;
        continue;
      }

      final isOnline = await _checkServerOnline(server);
      newStatuses[server.id] =
          isOnline ? ServerStatus.online : ServerStatus.offline;
    }

    serverStatuses.value = newStatuses;
  }

  Future<bool> _checkServerOnline(ServerMod server) async {
    try {
      final latency = await PingUtil.ping(server.url);
      return latency != null;
    } catch (e) {
      return false;
    }
  }

  void setActiveServers(Set<int> serverIds) {
    activeServerIds.value = serverIds;
  }

  ServerStatus getServerStatus(int serverId) {
    return serverStatuses.value[serverId] ?? ServerStatus.unknown;
  }

  void dispose() {
    stopPeriodicCheck();
  }
}

class PingUtil {
  static Future<int?> ping(String server) async {
    try {
      final parts = server.split(':');
      final hostname = parts[0];
      final port = parts.length > 1 ? int.parse(parts[1]) : 80;

      Socket? socket;
      final stopwatch = Stopwatch();

      try {
        stopwatch.start();
        socket = await Socket.connect(
          hostname,
          port,
          timeout: const Duration(seconds: 5),
        );
        stopwatch.stop();
        final ms = stopwatch.elapsedMilliseconds;
        return ms > 800 ? null : ms;
      } on SocketException {
        return null;
      } finally {
        socket?.destroy();
      }
    } catch (e) {
      return null;
    }
  }
}

ServerState get serverState => GetIt.I<ServerState>();
ServerStatusState get serverStatusState => GetIt.I<ServerStatusState>();
