import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:collection';
import '../screens/log_screen.dart';

/// 日志状态
class LogState {
  final Queue<LogEntry> logs;
  final int maxLogs;
  final bool isLoggingEnabled;

  LogState({
    Queue<LogEntry>? logs,
    this.maxLogs = 100,  // 修改为100条
    this.isLoggingEnabled = false,  // 默认不记录日志
  }) : logs = logs ?? Queue<LogEntry>();

  LogState copyWith({
    Queue<LogEntry>? logs,
    int? maxLogs,
    bool? isLoggingEnabled,
  }) {
    return LogState(
      logs: logs ?? this.logs,
      maxLogs: maxLogs ?? this.maxLogs,
      isLoggingEnabled: isLoggingEnabled ?? this.isLoggingEnabled,
    );
  }
}

/// 日志管理器
class LogNotifier extends StateNotifier<LogState> {
  LogNotifier() : super(LogState());

  /// 切换日志记录状态
  void toggleLogging() {
    state = state.copyWith(isLoggingEnabled: !state.isLoggingEnabled);
  }

  /// 添加发送日志
  void addTxLog(List<int> data) {
    _addLog('TX', data);
  }

  /// 添加接收日志
  void addRxLog(List<int> data) {
    _addLog('RX', data);
  }

  /// 添加日志
  void _addLog(String direction, List<int> data) {
    // 如果日志记录未启用，直接返回
    if (!state.isLoggingEnabled) return;

    final newLogs = Queue<LogEntry>.from(state.logs);
    newLogs.add(LogEntry(
      timestamp: DateTime.now(),
      direction: direction,
      data: data,
    ));

    // 限制日志数量
    while (newLogs.length > state.maxLogs) {
      newLogs.removeFirst();
    }

    state = state.copyWith(logs: newLogs);
  }

  /// 清除所有日志
  void clearLogs() {
    state = LogState(
      maxLogs: state.maxLogs,
      isLoggingEnabled: state.isLoggingEnabled,
    );
  }

  /// 获取日志列表
  List<LogEntry> getLogs() {
    return state.logs.toList();
  }
}

/// 全局日志Provider
final logProvider = StateNotifierProvider<LogNotifier, LogState>((ref) {
  return LogNotifier();
});
