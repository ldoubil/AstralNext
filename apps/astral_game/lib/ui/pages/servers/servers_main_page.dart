import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:astral_game/di.dart';
import 'package:astral_game/data/state/server_state.dart';
import 'package:astral_game/config/constants.dart';
import 'package:astral_game/data/models/server_mod.dart';
import 'package:astral_game/data/services/public_server_service.dart';

import 'server_dialog.dart';
import 'blocked_servers.dart';

class ServersMainPage extends StatefulWidget {
  const ServersMainPage({super.key});

  @override
  State<ServersMainPage> createState() => _ServersMainPageState();
}

class _ServersMainPageState extends State<ServersMainPage> {
  final _serverState = getIt<ServerState>();
  final _serverStatusState = getIt<ServerStatusState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _serverStatusState.startPeriodicCheck(
        _serverState.servers.value,
        const Duration(seconds: 30),
      );
    });
  }

  @override
  void dispose() {
    _serverStatusState.stopPeriodicCheck();
    super.dispose();
  }

  Color _getStatusColor(ServerStatus status, ColorScheme colorScheme) {
    switch (status) {
      case ServerStatus.online:
        return AppColors.online;
      case ServerStatus.offline:
        return AppColors.error;
      case ServerStatus.inUse:
        return AppColors.info;
      case ServerStatus.unknown:
        return colorScheme.outline;
    }
  }

  Widget _buildBody(BuildContext context) {
    return Watch((context) {
      final servers = _serverState.servers.value;
      final statuses = _serverStatusState.serverStatuses.value;

      if (servers.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.dns_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                '暂无服务器',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => showAddServerDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('添加服务器'),
              ),
            ],
          ),
        );
      }

      return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: servers.length,
      buildDefaultDragHandles: false,
      proxyDecorator: (child, index, animation) {
        return Material(
          elevation: 0,
          color: Colors.transparent,
          child: child,
        );
      },
      onReorder: (oldIndex, newIndex) {
        final newServers = List<ServerMod>.from(servers);
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        final server = newServers.removeAt(oldIndex);
        newServers.insert(newIndex, server);
        _serverState.reorderServers(newServers);
      },
      itemBuilder: (context, index) {
        final server = servers[index];
        final status = statuses[server.id] ?? ServerStatus.unknown;

        return ReorderableDragStartListener(
          key: ValueKey(server.id),
          index: index,
          child: Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color:
                      _getStatusColor(status, Theme.of(context).colorScheme),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              title: Text(
                server.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                (BlockedServers.isBlocked(server.url) || server.encrypted)
                    ? '***'
                    : server.url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: server.enable,
                      onChanged: (value) {
                        _serverState.toggleServerEnabled(server.id, value);
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        if (BlockedServers.isBlocked(server.url) || server.encrypted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('此服务器不可编辑'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } else {
                          showEditServerDialog(context, server: server);
                        }
                      } else if (value == 'delete') {
                        _showDeleteConfirmDialog(server);
                      }
                    },
                    itemBuilder: (context) {
                      final isBlocked =
                          BlockedServers.isBlocked(server.url);
                      final colorScheme = Theme.of(context).colorScheme;
                      return [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: isBlocked
                                    ? colorScheme.outline
                                    : colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '编辑',
                                style: TextStyle(
                                  color:
                                      isBlocked ? colorScheme.outline : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: colorScheme.error,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '删除',
                                style:
                                    TextStyle(color: colorScheme.error),
                              ),
                            ],
                          ),
                        ),
                      ];
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(context),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'public_servers',
            onPressed: () => _showPublicServersDialog(context),
            child: const Icon(Icons.public),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            heroTag: 'add_server',
            onPressed: () => showAddServerDialog(context),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(ServerMod server) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除服务器'),
        content: Text('确定要删除服务器 "${server.name}" 吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              _serverState.removeServer(server.id);
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showPublicServersDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _PublicServerDialog(
        serverState: _serverState,
      ),
    );
  }
}

class _PublicServerDialog extends StatefulWidget {
  final ServerState serverState;

  const _PublicServerDialog({required this.serverState});

  @override
  State<_PublicServerDialog> createState() => _PublicServerDialogState();
}

class _PublicServerDialogState extends State<_PublicServerDialog> {
  final _service = PublicServerService();
  List<PublicServer> _servers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadServers();
  }

  Future<void> _loadServers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final servers = await _service.fetchServers();
      if (mounted) {
        setState(() {
          _servers = servers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '加载失败: $e';
          _isLoading = false;
        });
      }
    }
  }

  bool _isAlreadyAdded(String encryptedUrl) {
    return widget.serverState.servers.value.any((s) => s.url == encryptedUrl);
  }

  void _addServer(PublicServer server) {
    widget.serverState.addServer(
      ServerMod(
        name: server.name,
        url: server.encryptedUrl,
        encrypted: true,
        enable: true,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已添加 "${server.name}"')),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('公共服务器'),
      content: SizedBox(
        width: 400,
        height: 300,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                        const SizedBox(height: 12),
                        Text(_error!, style: TextStyle(color: colorScheme.error)),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _loadServers,
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  )
                : _servers.isEmpty
                    ? const Center(child: Text('暂无公共服务器'))
                    : ListView.builder(
                        itemCount: _servers.length,
                        itemBuilder: (context, index) {
                          final server = _servers[index];
                          final added = _isAlreadyAdded(server.encryptedUrl);

                          return ListTile(
                            title: Text(server.name),
                            subtitle: Text(
                              server.encryptedUrl,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: added
                                ? Icon(Icons.check_circle, color: colorScheme.outline)
                                : FilledButton.tonal(
                                    onPressed: () => _addServer(server),
                                    child: const Text('添加'),
                                  ),
                          );
                        },
                      ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}
