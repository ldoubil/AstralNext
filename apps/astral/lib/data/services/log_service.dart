import 'dart:async';

import 'package:logger/logger.dart';

/// 日志条目模型
/// 用于在内存中保存每一条日志的时间、级别、模块和内容
class LogEntry {
  /// 记录时间
  final DateTime time;

  /// 日志级别（如 Level.info 等的字符串表示）
  final String level;

  /// 产生日志的模块或来源（便于过滤和定位）
  final String module;

  /// 日志内容
  final String message;

  LogEntry({
    required this.time,
    required this.level,
    required this.module,
    required this.message,
  });
}

/// 日志服务
/// 负责把日志输出到控制台（通过 logger 包）并在内存中保存历史，同时提供一个可订阅的流用于实时监听
class LogService {
  // 用于控制台输出的 Logger 实例
  final Logger _logger;

  // 存放历史日志条目的内存列表（追加式）
  final _entries = <LogEntry>[];

  // 广播型 StreamController，允许多个订阅者同时监听新日志
  final _streamController = StreamController<LogEntry>.broadcast();

  /// 用于外部订阅实时日志的流
  Stream<LogEntry> get stream => _streamController.stream;

  /// 只读的历史日志列表快照
  List<LogEntry> get history => List.unmodifiable(_entries);

  LogService()
    : _logger = Logger(
        // 配置 PrettyPrinter，控制输出样式与细节
        printer: PrettyPrinter(
          methodCount: 0, // 控制台输出时不显示堆栈方法链
          errorMethodCount: 5, // 错误时显示的堆栈深度
          lineLength: 80, // 每行长度
          colors: true, // 是否带颜色（终端支持时）
          printEmojis: true, // 是否打印 emoji
          dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart, // 时间格式
        ),
      );

  /// 记录一条日志：同时输出到控制台并写入内存与流中
  void log(String module, Level level, String message) {
    // 控制台输出，带模块标签
    _logger.log(level, '[$module] $message');

    // 构造日志条目并保存
    final entry = LogEntry(
      time: DateTime.now(),
      level: level.toString(),
      module: module,
      message: message,
    );

    _entries.add(entry);
    _streamController.add(entry);
  }

  /// info 级别快捷方法
  void info(String module, String message) => log(module, Level.info, message);

  /// debug 级别快捷方法
  void debug(String module, String message) =>
      log(module, Level.debug, message);

  /// warning 级别快捷方法
  void warn(String module, String message) =>
      log(module, Level.warning, message);

  /// error 级别快捷方法
  void error(String module, String message) =>
      log(module, Level.error, message);

  /// 释放资源：关闭流控制器
  void dispose() {
    _streamController.close();
  }
}
