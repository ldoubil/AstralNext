class RoomMod {
  final int id;
  final String name;
  final String host;
  final int port;
  final String password;
  final DateTime createdAt;

  const RoomMod({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.password,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'host': host,
        'port': port,
        'password': password,
        'created_at': createdAt.toIso8601String(),
      };

  factory RoomMod.fromJson(Map<String, dynamic> json) => RoomMod(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? '',
        host: json['host'] as String? ?? '',
        port: (json['port'] as num?)?.toInt() ?? 0,
        password: json['password'] as String? ?? '',
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}