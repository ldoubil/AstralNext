import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import 'server_state.dart';
import 'server_dialog.dart';
import 'blocked_servers.dart';
import 'server_mod.dart';

class ServersMainPage extends StatefulWidget {
  const ServersMainPage({super.key});

  @override
  State<ServersMainPage> createState() => _ServersMainPageState();
}

class _ServersMainPageState extends State<ServersMainPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      serverStatusState.startPeriodicCheck(
        serverState.servers.value,
        const Duration(seconds: 30),
      );
    });
  }

  @override
  void dispose() {
    serverStatusState.stopPeriodicCheck();
    super.dispose();
  }

  Color _getStatusColor(ServerStatus status, ColorScheme colorScheme) {
    switch (status) {
      case ServerStatus.online:
        return Colors.green;
      case ServerStatus.offline:
        return Colors.red;
      case ServerStatus.inUse:
        return Colors.blue;
      case ServerStatus.unknown:
        return colorScheme.outline;
    }
  }

  Widget _buildBody(BuildContext context) {
    return Watch((context) {
      final servers = serverState.servers.value;
      final statuses = serverStatusState.serverStatuses.value;

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
        serverState.reorderServers(newServers);
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
                BlockedServers.isBlocked(server.url) ? '***' : server.url,
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
                        serverState.toggleServerEnabled(server.id, value);
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        if (BlockedServers.isBlocked(server.url)) {
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddServerDialog(context),
        child: const Icon(Icons.add),
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
              serverState.removeServer(server.id);
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
