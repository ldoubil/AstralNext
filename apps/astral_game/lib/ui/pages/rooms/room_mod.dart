import 'dart:convert';
import 'package:uuid/uuid.dart';

class RoomMod {
  int id;
  String name; // 房间别名（显示名称）
  final String uuid; // 唯一标识（创建时自动生成）
  int sortOrder;

  static int _nextId = 1;

  RoomMod({
    int? id,
    required this.name,
    String? uuid,
    this.sortOrder = 0,
  })  : id = id ?? _nextId++,
        uuid = uuid ?? const Uuid().v4();

  /// 从 UUID 密钥派生房间名
  String get roomName => _deriveFromUuid(uuid, 0);

  /// 从 UUID 密钥派生密码
  String get password => _deriveFromUuid(uuid, 1);

  /// 密钥派生算法：
  /// 将 UUID（去连字符）的 32 位 hex 平分为两半，
  /// 各取 8 字节做 base64url 编码（去 padding），得到两个短字符串。
  /// 同一 UUID 永远派生出相同的 roomName 和 password。
  static String _deriveFromUuid(String uuid, int index) {
    final hex = uuid.replaceAll('-', ''); // 32 hex chars
    final start = index * 16;
    final half = hex.substring(start, start + 16); // 16 hex = 8 bytes
    final bytes = [
      for (int i = 0; i < half.length; i += 2)
        int.parse(half.substring(i, i + 2), radix: 16),
    ];
    // base64url 去掉 +/ 和 padding，确保是安全的字母数字串
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  /// 生成分享码：房间名 + uuid 拼接
  String toShareCode() {
    return '$name$uuid';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'uuid': uuid,
        'sortOrder': sortOrder,
      };

  factory RoomMod.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as int? ?? 1;
    final room = RoomMod(
      id: id,
      name: json['name'] as String? ?? '',
      uuid: json['uuid'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
    if (id >= RoomMod._nextId) {
      RoomMod._nextId = id + 1;
    }
    return room;
  }

  /// 从分享码解析房间信息
  /// 格式：name(变长) + uuid(36字符UUID)
  static (String name, String uuid)? fromShareCode(String shareCode) {
    // 最短格式：至少1字符name + 36 UUID = 37字符
    if (shareCode.length < 37) return null;

    final uuidPattern = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    );

    final uuid = shareCode.substring(shareCode.length - 36);
    if (!uuidPattern.hasMatch(uuid)) return null;

    final name = shareCode.substring(0, shareCode.length - 36);
    if (name.isEmpty) return null;

    return (name, uuid);
  }
}
