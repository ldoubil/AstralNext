class ServerMod {
  final int id;
  final String name;
  final String url;
  final bool enable;

  // 协议开关
  final bool tcp;
  final bool faketcp;
  final bool udp;
  final bool ws;
  final bool wss;
  final bool quic;
  final bool wg;
  final bool txt;
  final bool srv;
  final bool http;
  final bool https;

  /// 排序顺序
  final int sortOrder;

  static int _nextId = 1;

  static void setNextId(int value) {
    _nextId = value;
  }

  ServerMod({
    int? id,
    this.enable = false,
    required this.name,
    required this.url,
    this.tcp = false,
    this.faketcp = false,
    this.udp = false,
    this.ws = false,
    this.wss = false,
    this.quic = false,
    this.wg = false,
    this.txt = false,
    this.srv = false,
    this.http = false,
    this.https = false,
    this.sortOrder = 0,
  }) : id = id ?? _nextId++;

  ServerMod copyWith({
    String? name,
    String? url,
    bool? enable,
    bool? tcp,
    bool? faketcp,
    bool? udp,
    bool? ws,
    bool? wss,
    bool? quic,
    bool? wg,
    bool? txt,
    bool? srv,
    bool? http,
    bool? https,
    int? sortOrder,
  }) {
    return ServerMod(
      id: id,
      name: name ?? this.name,
      url: url ?? this.url,
      enable: enable ?? this.enable,
      tcp: tcp ?? this.tcp,
      faketcp: faketcp ?? this.faketcp,
      udp: udp ?? this.udp,
      ws: ws ?? this.ws,
      wss: wss ?? this.wss,
      quic: quic ?? this.quic,
      wg: wg ?? this.wg,
      txt: txt ?? this.txt,
      srv: srv ?? this.srv,
      http: http ?? this.http,
      https: https ?? this.https,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
        'enable': enable,
        'tcp': tcp,
        'faketcp': faketcp,
        'udp': udp,
        'ws': ws,
        'wss': wss,
        'quic': quic,
        'wg': wg,
        'txt': txt,
        'srv': srv,
        'http': http,
        'https': https,
        'sortOrder': sortOrder,
      };

  factory ServerMod.fromJson(Map<String, dynamic> json) => ServerMod(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? '',
        url: json['url'] as String? ?? '',
        enable: json['enable'] as bool? ?? false,
        tcp: json['tcp'] as bool? ?? false,
        faketcp: json['faketcp'] as bool? ?? false,
        udp: json['udp'] as bool? ?? false,
        ws: json['ws'] as bool? ?? false,
        wss: json['wss'] as bool? ?? false,
        quic: json['quic'] as bool? ?? false,
        wg: json['wg'] as bool? ?? false,
        txt: json['txt'] as bool? ?? false,
        srv: json['srv'] as bool? ?? false,
        http: json['http'] as bool? ?? false,
        https: json['https'] as bool? ?? false,
        sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      );
}
