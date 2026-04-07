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

  /// 实例路径（可选，用于按实例过滤）
  final String? instancePath;

  LogEntry({
    required this.time,
    required this.level,
    required this.module,
    required this.message,
    this.instancePath,
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
        printer: PrettyPrinter(
          methodCount: 0,
          errorMethodCount: 5,
          lineLength: 80,
          colors: true,
          printEmojis: true,
          dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
        ),
      );

  /// 记录一条日志：同时输出到控制台并写入内存与流中
  void log(String module, Level level, String message, {String? instancePath}) {
    _logger.log(level, '[$module] $message');

    final entry = LogEntry(
      time: DateTime.now(),
      level: level.toString(),
      module: module,
      message: message,
      instancePath: instancePath,
    );

    _entries.add(entry);
    _streamController.add(entry);
  }

  /// info 级别快捷方法
  void info(String module, String message, {String? instancePath}) =>
      log(module, Level.info, message, instancePath: instancePath);

  /// debug 级别快捷方法
  void debug(String module, String message, {String? instancePath}) =>
      log(module, Level.debug, message, instancePath: instancePath);

  /// warning 级别快捷方法
  void warn(String module, String message, {String? instancePath}) =>
      log(module, Level.warning, message, instancePath: instancePath);

  /// error 级别快捷方法
  void error(String module, String message, {String? instancePath}) =>
      log(module, Level.error, message, instancePath: instancePath);

  /// 获取指定实例的日志历史
  List<LogEntry> getHistoryForInstance(String instancePath) {
    return _entries.where((e) => e.instancePath == instancePath).toList();
  }

  /// 清空所有日志
  void clear() {
    _entries.clear();
  }

  /// 清空指定实例的日志
  void clearForInstance(String instancePath) {
    _entries.removeWhere((e) => e.instancePath == instancePath);
  }

  /// 释放资源：关闭流控制器
  void dispose() {
    _streamController.close();
  }
}
