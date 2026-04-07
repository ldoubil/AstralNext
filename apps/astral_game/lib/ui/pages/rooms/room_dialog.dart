import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'room_mod.dart';
import 'room_state.dart';

void showAddRoomDialog(BuildContext context) {
  String name = '';

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('创建房间'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              onChanged: (value) => name = value,
              decoration: InputDecoration(
                labelText: '房间名称',
                hintText: '输入房间名称',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(
                  Icons.meeting_room,
                  color: Theme.of(context).colorScheme.primary,
                ),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '房间名和密码将从 UUID 自动派生',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (name.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('请输入房间名称'),
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }
              final room = RoomMod(name: name.trim());
              roomState.addRoom(room);
              Navigator.of(context).pop();
            },
            child: const Text('创建'),
          ),
        ],
      );
    },
  );
}

void showEditRoomDialog(BuildContext context, {required RoomMod room}) {
  String name = room.name;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('编辑房间'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: TextEditingController(text: name),
              onChanged: (value) => name = value,
              decoration: InputDecoration(
                labelText: '房间名称',
                hintText: '输入房间名称',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(
                  Icons.meeting_room,
                  color: Theme.of(context).colorScheme.primary,
                ),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoTile(
              context,
              icon: Icons.fingerprint,
              label: 'UUID（密钥）',
              value: room.uuid,
            ),
            const SizedBox(height: 8),
            _buildInfoTile(
              context,
              icon: Icons.vpn_key,
              label: '派生房间名',
              value: room.roomName,
            ),
            const SizedBox(height: 8),
            _buildInfoTile(
              context,
              icon: Icons.lock,
              label: '派生密码',
              value: room.password,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (name.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('请输入房间名称'),
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }
              final updated = RoomMod(
                id: room.id,
                name: name.trim(),
                uuid: room.uuid,
                sortOrder: room.sortOrder,
              );
              roomState.updateRoom(updated);
              Navigator.of(context).pop();
            },
            child: const Text('保存'),
          ),
        ],
      );
    },
  );
}

Widget _buildInfoTile(
  BuildContext context, {
  required IconData icon,
  required String label,
  required String value,
}) {
  return ListTile(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(
        color: Theme.of(context).colorScheme.outline,
      ),
    ),
    title: Text(label),
    subtitle: Text(
      value,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontFamily: 'monospace',
          ),
    ),
    leading: Icon(
      icon,
      color: Theme.of(context).colorScheme.primary,
    ),
    trailing: IconButton(
      icon: const Icon(Icons.copy, size: 18),
      tooltip: '复制',
      onPressed: () {
        Clipboard.setData(ClipboardData(text: value));
      },
    ),
  );
}

void showImportRoomDialog(BuildContext context) {
  String importCode = '';

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('导入房间'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              onChanged: (value) => importCode = value,
              decoration: InputDecoration(
                labelText: '分享码',
                hintText: '粘贴分享码',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(
                  Icons.paste,
                  color: Theme.of(context).colorScheme.primary,
                ),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 12,
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final clipboard =
                      await Clipboard.getData(Clipboard.kTextPlain);
                  if (!context.mounted) return;
                  if (clipboard?.text != null &&
                      clipboard!.text!.isNotEmpty) {
                    Navigator.of(context).pop();
                    _doImport(context, clipboard.text!);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('剪贴板为空'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.content_paste_go),
                label: const Text('从剪贴板导入'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (importCode.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('请输入分享码'),
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }
              Navigator.of(context).pop();
              _doImport(context, importCode.trim());
            },
            child: const Text('导入'),
          ),
        ],
      );
    },
  );
}

void _doImport(BuildContext context, String shareCode) {
  final parsed = RoomMod.fromShareCode(shareCode);
  if (parsed == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('分享码格式无效'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
    return;
  }

  final (name, uuid) = parsed;

  // 检查是否已存在相同 uuid 的房间
  final existing =
      roomState.rooms.value.where((r) => r.uuid == uuid);
  if (existing.isNotEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('房间 "$name" 已存在'),
        duration: const Duration(seconds: 2),
      ),
    );
    return;
  }

  final room = RoomMod(
    name: name,
    uuid: uuid,
  );
  roomState.addRoom(room);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('已成功导入房间 "$name"'),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 2),
    ),
  );
}

void showShareRoomDialog(BuildContext context, {required RoomMod room}) {
  final shareCode = room.toShareCode();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('分享房间'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '房间名称: ${room.name}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            Text(
              '分享码:',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              child: SelectableText(
                shareCode,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '将分享码发送给好友，好友通过"导入房间"即可加入',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
          FilledButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: shareCode));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('分享码已复制到剪贴板'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('复制分享码'),
          ),
        ],
      );
    },
  );
}
