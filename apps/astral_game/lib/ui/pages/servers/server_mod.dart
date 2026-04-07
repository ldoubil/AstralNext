class ServerMod {
  int id;
  String name;
  String url;
  bool enable;

  // 协议开关
  bool tcp;
  bool faketcp;
  bool udp;
  bool ws;
  bool wss;
  bool quic;
  bool wg;
  bool txt;
  bool srv;
  bool http;
  bool https;

  /// 排序顺序
  int sortOrder;

  static int _nextId = 1;

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
}
