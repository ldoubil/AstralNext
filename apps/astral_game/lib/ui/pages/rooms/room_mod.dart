class RoomMod {
  final int id;
  final String name;
  final String roomName;
  final String host;
  final int port;
  final String password;
  final String uuid;
  final DateTime createdAt;

  const RoomMod({
    required this.id,
    required this.name,
    required this.roomName,
    required this.host,
    required this.port,
    required this.password,
    required this.uuid,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'room_name': roomName,
        'host': host,
        'port': port,
        'password': password,
        'uuid': uuid,
        'created_at': createdAt.toIso8601String(),
      };

  factory RoomMod.fromJson(Map<String, dynamic> json) => RoomMod(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? '',
        roomName: json['room_name'] as String? ?? '',
        host: json['host'] as String? ?? '',
        port: (json['port'] as num?)?.toInt() ?? 0,
        password: json['password'] as String? ?? '',
        uuid: json['uuid'] as String? ?? '',
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}