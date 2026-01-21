import 'package:flutter/foundation.dart';

/// 应用日志工具类
/// 在 debug 模式下输出日志，在 release 模式下自动禁用
class AppLogger {
  /// 是否启用日志（仅在 debug 模式下启用）
  static bool get isEnabled => kDebugMode;

  /// 输出调试日志
  static void debug(String message, [String? tag]) {
    if (!isEnabled) return;
    final prefix = tag != null ? '[$tag] ' : '';
    debugPrint('🔍 $prefix$message');
  }

  /// 输出信息日志
  static void info(String message, [String? tag]) {
    if (!isEnabled) return;
    final prefix = tag != null ? '[$tag] ' : '';
    debugPrint('ℹ️ $prefix$message');
  }

  /// 输出警告日志
  static void warning(String message, [String? tag]) {
    if (!isEnabled) return;
    final prefix = tag != null ? '[$tag] ' : '';
    debugPrint('⚠️ $prefix$message');
  }

  /// 输出错误日志
  static void error(String message, [String? tag, Object? error, StackTrace? stackTrace]) {
    if (!isEnabled) return;
    final prefix = tag != null ? '[$tag] ' : '';
    debugPrint('❌ $prefix$message');
    if (error != null) {
      debugPrint('Error: $error');
    }
    if (stackTrace != null) {
      debugPrint('StackTrace: $stackTrace');
    }
  }

  /// 输出成功日志
  static void success(String message, [String? tag]) {
    if (!isEnabled) return;
    final prefix = tag != null ? '[$tag] ' : '';
    debugPrint('✅ $prefix$message');
  }
}
