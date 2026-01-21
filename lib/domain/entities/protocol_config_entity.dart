/// 协议配置实体
///
/// 领域层的协议配置模型
class ProtocolConfigEntity {
  /// 前导码（十六进制字符串）
  final String preamble;

  /// 校验类型
  final String checksumType;

  /// 波特率
  final int baudRate;

  /// 发送起始符
  final String txStart;

  /// 接收起始符
  final String rxStart;

  const ProtocolConfigEntity({
    required this.preamble,
    required this.checksumType,
    required this.baudRate,
    required this.txStart,
    required this.rxStart,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ProtocolConfigEntity &&
        other.preamble == preamble &&
        other.checksumType == checksumType &&
        other.baudRate == baudRate &&
        other.txStart == txStart &&
        other.rxStart == rxStart;
  }

  @override
  int get hashCode {
    return Object.hash(
      preamble,
      checksumType,
      baudRate,
      txStart,
      rxStart,
    );
  }

  @override
  String toString() {
    return 'ProtocolConfigEntity('
        'preamble: $preamble, '
        'checksum: $checksumType, '
        'baudRate: $baudRate, '
        'txStart: $txStart, '
        'rxStart: $rxStart)';
  }
}
