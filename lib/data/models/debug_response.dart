/// 调试响应状态
enum DebugStatus {
  /// 成功
  success,

  /// 超时
  timeout,

  /// 错误
  error,

  /// 等待中
  waiting,
}

/// 调试响应模型
class DebugResponse {
  /// 响应状态
  final DebugStatus status;

  /// 响应消息
  final String message;

  /// 原始数据（字节数组）
  final List<int>? rawData;

  /// 解析后的数据
  final Map<String, dynamic>? parsedData;

  /// 耗时
  final Duration elapsed;

  /// 时间戳
  final DateTime timestamp;

  /// 发送时间
  final DateTime? sendTime;

  /// 接收时间
  final DateTime? receiveTime;

  DebugResponse({
    required this.status,
    required this.message,
    this.rawData,
    this.parsedData,
    required this.elapsed,
    DateTime? timestamp,
    this.sendTime,
    this.receiveTime,
  }) : timestamp = timestamp ?? DateTime.now();

  /// 创建成功响应
  factory DebugResponse.success({
    required String message,
    List<int>? rawData,
    Map<String, dynamic>? parsedData,
    required Duration elapsed,
    DateTime? sendTime,
    DateTime? receiveTime,
  }) {
    return DebugResponse(
      status: DebugStatus.success,
      message: message,
      rawData: rawData,
      parsedData: parsedData,
      elapsed: elapsed,
      sendTime: sendTime,
      receiveTime: receiveTime,
    );
  }

  /// 创建超时响应
  factory DebugResponse.timeout({
    required String message,
    required Duration elapsed,
    DateTime? sendTime,
  }) {
    return DebugResponse(
      status: DebugStatus.timeout,
      message: message,
      elapsed: elapsed,
      sendTime: sendTime,
    );
  }

  /// 创建错误响应
  factory DebugResponse.error({
    required String message,
    List<int>? rawData,
    required Duration elapsed,
    DateTime? sendTime,
  }) {
    return DebugResponse(
      status: DebugStatus.error,
      message: message,
      rawData: rawData,
      elapsed: elapsed,
      sendTime: sendTime,
    );
  }

  /// 创建等待响应
  factory DebugResponse.waiting({
    required String message,
  }) {
    return DebugResponse(
      status: DebugStatus.waiting,
      message: message,
      elapsed: Duration.zero,
    );
  }

  /// 将原始数据转换为十六进制字符串
  String? get rawDataHex {
    if (rawData == null) return null;
    return rawData!.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');
  }

  /// 是否成功
  bool get isSuccess => status == DebugStatus.success;

  /// 是否超时
  bool get isTimeout => status == DebugStatus.timeout;

  /// 是否错误
  bool get isError => status == DebugStatus.error;

  /// 是否等待中
  bool get isWaiting => status == DebugStatus.waiting;

  @override
  String toString() {
    return 'DebugResponse(status: $status, message: $message, elapsed: ${elapsed.inMilliseconds}ms)';
  }
}
