import 'dart:convert';

class DashboardWidgetConfig {
  final String id;
  final String type;
  final int widthSpan;
  final int heightSpan;
  final int order;
  final Map<String, dynamic> props;

  const DashboardWidgetConfig({
    required this.id,
    required this.type,
    this.widthSpan = 1,
    this.heightSpan = 1,
    this.order = 0,
    this.props = const {},
  });

  DashboardWidgetConfig copyWith({
    String? id,
    String? type,
    int? widthSpan,
    int? heightSpan,
    int? order,
    Map<String, dynamic>? props,
  }) {
    return DashboardWidgetConfig(
      id: id ?? this.id,
      type: type ?? this.type,
      widthSpan: widthSpan ?? this.widthSpan,
      heightSpan: heightSpan ?? this.heightSpan,
      order: order ?? this.order,
      props: props ?? this.props,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'widthSpan': widthSpan,
      'heightSpan': heightSpan,
      'order': order,
      'props': props,
    };
  }

  factory DashboardWidgetConfig.fromMap(Map<String, dynamic> map) {
    return DashboardWidgetConfig(
      id: map['id'] as String,
      type: map['type'] as String,
      widthSpan: (map['widthSpan'] as num?)?.toInt() ?? 1,
      heightSpan: (map['heightSpan'] as num?)?.toInt() ?? 1,
      order: (map['order'] as num?)?.toInt() ?? 0,
      props: Map<String, dynamic>.from(map['props'] as Map? ?? {}),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory DashboardWidgetConfig.fromJson(String source) =>
      DashboardWidgetConfig.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

class DashboardLayout {
  final List<DashboardWidgetConfig> widgets;
  final int columns;
  final double unitHeight;

  const DashboardLayout({
    required this.widgets,
    this.columns = 4,
    this.unitHeight = 140,
  });

  DashboardLayout copyWith({
    List<DashboardWidgetConfig>? widgets,
    int? columns,
    double? unitHeight,
  }) {
    return DashboardLayout(
      widgets: widgets ?? this.widgets,
      columns: columns ?? this.columns,
      unitHeight: unitHeight ?? this.unitHeight,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'widgets': widgets.map((w) => w.toMap()).toList(),
      'columns': columns,
      'unitHeight': unitHeight,
    };
  }

  factory DashboardLayout.fromMap(Map<String, dynamic> map) {
    return DashboardLayout(
      widgets: (map['widgets'] as List?)
              ?.map((w) => DashboardWidgetConfig.fromMap(w as Map<String, dynamic>))
              .toList() ??
          [],
      columns: (map['columns'] as num?)?.toInt() ?? 4,
      unitHeight: (map['unitHeight'] as num?)?.toDouble() ?? 140,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory DashboardLayout.fromJson(String source) =>
      DashboardLayout.fromMap(jsonDecode(source) as Map<String, dynamic>);

  static DashboardLayout get defaultLayout => const DashboardLayout(
        widgets: [
          DashboardWidgetConfig(
            id: 'traffic',
            type: 'traffic',
            widthSpan: 3,
            heightSpan: 1,
            order: 0,
          ),
          DashboardWidgetConfig(
            id: 'node_list',
            type: 'node_list',
            widthSpan: 2,
            heightSpan: 1,
            order: 1,
          ),
          DashboardWidgetConfig(
            id: 'node_topology',
            type: 'node_topology',
            widthSpan: 2,
            heightSpan: 1,
            order: 2,
          ),
          DashboardWidgetConfig(
            id: 'connection_stats',
            type: 'connection_stats',
            widthSpan: 1,
            heightSpan: 1,
            order: 3,
          ),
        ],
      );
}
