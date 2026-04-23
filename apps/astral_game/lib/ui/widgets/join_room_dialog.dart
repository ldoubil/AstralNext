import 'package:flutter/material.dart';

class SavedRoom {
  final String id;
  final String name;
  final String roomName;
  final String password;

  SavedRoom({
    required this.id,
    required this.name,
    required this.roomName,
    required this.password,
  });
}

class JoinRoomDialog extends StatefulWidget {
  const JoinRoomDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const JoinRoomDialog(),
    );
  }

  @override
  State<JoinRoomDialog> createState() => _JoinRoomDialogState();
}

class _JoinRoomDialogState extends State<JoinRoomDialog> {
  final TextEditingController _shareCodeController = TextEditingController();
  final List<SavedRoom> _savedRooms = [
    SavedRoom(
      id: '1',
      name: '游戏房间A',
      roomName: 'GameRoom_A',
      password: 'password123',
    ),
    SavedRoom(
      id: '2',
      name: '朋友房间',
      roomName: 'FriendRoom',
      password: 'friend456',
    ),
    SavedRoom(
      id: '3',
      name: '测试房间',
      roomName: 'TestRoom',
      password: 'test789',
    ),
  ];

  @override
  void dispose() {
    _shareCodeController.dispose();
    super.dispose();
  }

  void _joinWithShareCode() {
    if (_shareCodeController.text.isNotEmpty) {
      Navigator.pop(context);
    }
  }

  void _joinWithSavedRoom(SavedRoom room) {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '加入房间',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '输入分享码或选择已保存的房间',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '分享码',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _shareCodeController,
                decoration: InputDecoration(
                  hintText: '请输入分享码',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner_outlined),
                    onPressed: () {},
                  ),
                ),
                onSubmitted: (_) => _joinWithShareCode(),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _shareCodeController.text.isNotEmpty
                    ? _joinWithShareCode
                    : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('快速加入'),
              ),
              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Text(
                '已保存的房间',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _savedRooms.length,
                itemBuilder: (context, index) {
                  final room = _savedRooms[index];
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(room.name),
                      subtitle: Text(room.roomName),
                      trailing: FilledButton.tonal(
                        onPressed: () => _joinWithSavedRoom(room),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('加入'),
                      ),
                      onTap: () => _joinWithSavedRoom(room),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
