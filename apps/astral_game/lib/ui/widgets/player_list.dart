import 'package:flutter/material.dart';

class Player {
  final String id;
  final String name;
  final bool isOnline;
  final int latency;

  Player({
    required this.id,
    required this.name,
    this.isOnline = true,
    this.latency = 0,
  });
}

class PlayerList extends StatefulWidget {
  const PlayerList({super.key});

  @override
  State<PlayerList> createState() => _PlayerListState();
}

class _PlayerListState extends State<PlayerList> {
  final List<Player> _players = [
    Player(id: '1', name: 'Player1', isOnline: true, latency: 25),
    Player(id: '2', name: 'Player2', isOnline: true, latency: 56),
    Player(id: '3', name: 'Player3', isOnline: false, latency: 0),
    Player(id: '4', name: 'Player4', isOnline: true, latency: 12),
    Player(id: '5', name: 'Player5', isOnline: true, latency: 89),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.people_outline, size: 20),
                const SizedBox(width: 8),
                Text(
                  '房间成员',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_players.where((p) => p.isOnline).length}/${_players.length}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _players.length,
              itemBuilder: (context, index) {
                final player = _players[index];
                return ListTile(
                  leading: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: player.isOnline
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  title: Text(
                    player.name,
                    style: textTheme.bodyMedium?.copyWith(
                      color: player.isOnline
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  trailing: player.isOnline
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${player.latency}ms',
                              style: textTheme.bodySmall?.copyWith(
                                color: _getLatencyColor(player.latency),
                              ),
                            ),
                          ],
                        )
                      : null,
                  onTap: () {},
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getLatencyColor(int latency) {
    if (latency < 50) return Colors.green;
    if (latency < 100) return Colors.yellow;
    return Colors.red;
  }
}
