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

    final now = DateTime.now();

    // 优化：直接操作现有队列，避免创建副本
    final logsList = state.logs.toList();
    
    // 向后查找最近的相同方向和相同数据的条目（最多查找10条）
    int foundIndex = -1;
    final searchLimit = logsList.length > 10 ? logsList.length - 10 : 0;
    
    for (int i = logsList.length - 1; i >= searchLimit; i--) {
      final log = logsList[i];
      if (log.direction == direction && log.hasSameData(data)) {
        foundIndex = i;
        break;
      }
    }

    if (foundIndex != -1) {
      // 找到相同的条目，更新计数和时间戳
      final foundLog = logsList[foundIndex];
      final updatedLog = foundLog.copyWith(
        timestamp: now,
        count: foundLog.count + 1,
      );
      
      // 直接替换
      logsList[foundIndex] = updatedLog;
      state = state.copyWith(logs: Queue<LogEntry>.from(logsList));
      return;
    }

    // 没有找到相同数据，添加新条目
    logsList.add(LogEntry(
      timestamp: now,
      direction: direction,
      data: data,
      count: 1,
    ));

    // 限制日志数量
    while (logsList.length > state.maxLogs) {
      logsList.removeAt(0);
    }

    state = state.copyWith(logs: Queue<LogEntry>.from(logsList));
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
