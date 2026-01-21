/// 烧录状态枚举
enum FlashStatus {
  /// 空闲状态
  idle('空闲'),

  /// 准备中
  preparing('准备中'),

  /// 初始化中
  initializing('初始化中'),

  /// 擦除中
  erasing('擦除中'),

  /// 烧录中
  flashing('烧录中'),

  /// 校验中
  verifying('校验中'),

  /// 完成
  completed('完成'),

  /// 失败
  failed('失败'),

  /// 已取消
  cancelled('已取消');

  final String displayName;
  const FlashStatus(this.displayName);
}

/// 烧录进度模型
///
/// 表示固件烧录的当前进度和状态
class FlashProgress {
  /// 烧录状态
  final FlashStatus status;

  /// 当前进度（0.0 - 1.0）
  final double progress;

  /// 已烧录的块数
  final int completedBlocks;

  /// 总块数
  final int totalBlocks;

  /// 已烧录的字节数
  final int completedBytes;

  /// 总字节数
  final int totalBytes;

  /// 当前消息
  final String message;

  /// 错误信息（如果有）
  final String? error;

  /// 开始时间
  final DateTime? startTime;

  /// 结束时间
  final DateTime? endTime;

  const FlashProgress({
    required this.status,
    this.progress = 0.0,
    this.completedBlocks = 0,
    this.totalBlocks = 0,
    this.completedBytes = 0,
    this.totalBytes = 0,
    this.message = '',
    this.error,
    this.startTime,
    this.endTime,
  });

  /// 创建空闲状态
  factory FlashProgress.idle() {
    return const FlashProgress(
      status: FlashStatus.idle,
      message: '等待开始',
    );
  }

  /// 创建准备状态
  factory FlashProgress.preparing(String message) {
    return FlashProgress(
      status: FlashStatus.preparing,
      message: message,
      startTime: DateTime.now(),
    );
  }

  /// 创建初始化状态
  factory FlashProgress.initializing(String message) {
    return FlashProgress(
      status: FlashStatus.initializing,
      progress: 0.05,  // 5% 进度
      message: message,
    );
  }

  /// 创建擦除状态
  factory FlashProgress.erasing(String message) {
    return FlashProgress(
      status: FlashStatus.erasing,
      progress: 0.10,  // 10% 进度
      message: message,
    );
  }

  /// 创建烧录中状态
  factory FlashProgress.flashing({
    required int completedBlocks,
    required int totalBlocks,
    required int completedBytes,
    required int totalBytes,
    String? message,
  }) {
    // 烧录进度占 10%-98% 的范围
    final blockProgress = totalBlocks > 0 ? completedBlocks / totalBlocks : 0.0;
    final progress = 0.10 + (blockProgress * 0.88);  // 10% + (0-88%) = 10%-98%
    return FlashProgress(
      status: FlashStatus.flashing,
      progress: progress,
      completedBlocks: completedBlocks,
      totalBlocks: totalBlocks,
      completedBytes: completedBytes,
      totalBytes: totalBytes,
      message: message ?? '烧录中 $completedBlocks/$totalBlocks',
    );
  }

  /// 创建校验中状态
  factory FlashProgress.verifying(String message) {
    return FlashProgress(
      status: FlashStatus.verifying,
      progress: 0.98,  // 98% 进度
      message: message,
    );
  }

  /// 创建完成状态
  factory FlashProgress.completed({
    required int totalBlocks,
    required int totalBytes,
    DateTime? startTime,
  }) {
    final endTime = DateTime.now();
    return FlashProgress(
      status: FlashStatus.completed,
      progress: 1.0,
      completedBlocks: totalBlocks,
      totalBlocks: totalBlocks,
      completedBytes: totalBytes,
      totalBytes: totalBytes,
      message: '烧录完成',
      startTime: startTime,
      endTime: endTime,
    );
  }

  /// 创建失败状态
  factory FlashProgress.failed(String error, {DateTime? startTime}) {
    return FlashProgress(
      status: FlashStatus.failed,
      message: '烧录失败',
      error: error,
      startTime: startTime,
      endTime: DateTime.now(),
    );
  }

  /// 创建取消状态
  factory FlashProgress.cancelled({DateTime? startTime}) {
    return FlashProgress(
      status: FlashStatus.cancelled,
      message: '烧录已取消',
      startTime: startTime,
      endTime: DateTime.now(),
    );
  }

  /// 复制并更新
  FlashProgress copyWith({
    FlashStatus? status,
    double? progress,
    int? completedBlocks,
    int? totalBlocks,
    int? completedBytes,
    int? totalBytes,
    String? message,
    String? error,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return FlashProgress(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      completedBlocks: completedBlocks ?? this.completedBlocks,
      totalBlocks: totalBlocks ?? this.totalBlocks,
      completedBytes: completedBytes ?? this.completedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      message: message ?? this.message,
      error: error ?? this.error,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  /// 获取进度百分比
  int get progressPercent => (progress * 100).round();

  /// 获取耗时（秒）
  int? get elapsedSeconds {
    if (startTime == null) return null;
    final end = endTime ?? DateTime.now();
    return end.difference(startTime!).inSeconds;
  }

  /// 获取耗时字符串
  String get elapsedTimeString {
    final seconds = elapsedSeconds;
    if (seconds == null) return '--';

    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    if (minutes > 0) {
      return '$minutes分${remainingSeconds}秒';
    } else {
      return '$remainingSeconds秒';
    }
  }

  /// 获取平均速度（字节/秒）
  double? get averageSpeed {
    final seconds = elapsedSeconds;
    if (seconds == null || seconds == 0) return null;
    return completedBytes / seconds;
  }

  /// 获取速度字符串
  String get speedString {
    final speed = averageSpeed;
    if (speed == null) return '--';

    if (speed >= 1024) {
      return '${(speed / 1024).toStringAsFixed(1)} KB/s';
    } else {
      return '${speed.toStringAsFixed(0)} B/s';
    }
  }

  /// 是否正在进行中
  bool get isInProgress {
    return status == FlashStatus.preparing ||
        status == FlashStatus.initializing ||
        status == FlashStatus.erasing ||
        status == FlashStatus.flashing ||
        status == FlashStatus.verifying;
  }

  /// 是否已完成（成功或失败）
  bool get isFinished {
    return status == FlashStatus.completed ||
        status == FlashStatus.failed ||
        status == FlashStatus.cancelled;
  }

  /// 是否成功
  bool get isSuccess {
    return status == FlashStatus.completed;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FlashProgress &&
        other.status == status &&
        other.progress == progress &&
        other.completedBlocks == completedBlocks &&
        other.totalBlocks == totalBlocks &&
        other.completedBytes == completedBytes &&
        other.totalBytes == totalBytes &&
        other.message == message &&
        other.error == error &&
        other.startTime == startTime &&
        other.endTime == endTime;
  }

  @override
  int get hashCode {
    return Object.hash(
      status,
      progress,
      completedBlocks,
      totalBlocks,
      completedBytes,
      totalBytes,
      message,
      error,
      startTime,
      endTime,
    );
  }

  @override
  String toString() {
    return 'FlashProgress('
        'status: ${status.displayName}, '
        'progress: ${progressPercent}%, '
        'blocks: $completedBlocks/$totalBlocks, '
        'message: $message'
        ')';
  }
}
