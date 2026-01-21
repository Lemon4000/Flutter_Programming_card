/// 校验类型枚举
enum ChecksumType {
  crc16Modbus('CRC16_MODBUS'),
  sum8('SUM8');

  final String value;
  const ChecksumType(this.value);

  /// 从字符串解析校验类型
  static ChecksumType fromString(String value) {
    return switch (value.toUpperCase()) {
      'CRC16_MODBUS' || 'CRC16' => ChecksumType.crc16Modbus,
      'SUM8' => ChecksumType.sum8,
      _ => throw ArgumentError('未知的校验类型: $value'),
    };
  }
}

/// 协议配置模型
class ProtocolConfig {
  /// 发送前导码（十六进制字符串，如"FC"）
  final String preamble;

  /// 接收前导码（十六进制字符串，如"FF"）
  /// 如果为空，则使用 preamble
  final String? rxPreamble;

  /// 校验类型
  final ChecksumType checksumType;

  /// 波特率
  final int baudRate;

  /// 发送起始符
  final String txStart;

  /// 接收起始符
  final String rxStart;

  const ProtocolConfig({
    required this.preamble,
    this.rxPreamble,
    required this.checksumType,
    required this.baudRate,
    required this.txStart,
    required this.rxStart,
  });

  /// 从JSON创建配置
  factory ProtocolConfig.fromJson(Map<String, dynamic> json) {
    return ProtocolConfig(
      preamble: json['preamble'] as String,
      rxPreamble: json['rxPreamble'] as String?,
      checksumType: ChecksumType.fromString(json['checksum'] as String),
      baudRate: json['baudRate'] as int,
      txStart: json['txStart'] as String,
      rxStart: json['rxStart'] as String,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'preamble': preamble,
      if (rxPreamble != null) 'rxPreamble': rxPreamble,
      'checksum': checksumType.value,
      'baudRate': baudRate,
      'txStart': txStart,
      'rxStart': rxStart,
    };
  }

  /// 获取发送前导码字节
  /// 注意：当前配置为不发送前导码，直接返回空列表
  List<int> getPreambleBytes() {
    // 不发送前导码
    return [];
  }

  /// 获取接收前导码字节
  List<int> getRxPreambleBytes() {
    // 如果没有配置 rxPreamble，返回空数组（表示接收时不使用前导码）
    if (rxPreamble == null || rxPreamble!.isEmpty) {
      return [];
    }

    final preambleStr = rxPreamble!;
    final bytes = <int>[];
    for (int i = 0; i < preambleStr.length; i += 2) {
      final hex = preambleStr.substring(i, i + 2);
      bytes.add(int.parse(hex, radix: 16));
    }
    return bytes;
  }

  @override
  String toString() {
    return 'ProtocolConfig('
        'preamble: $preamble, '
        'rxPreamble: $rxPreamble, '
        'checksum: ${checksumType.value}, '
        'baudRate: $baudRate, '
        'txStart: $txStart, '
        'rxStart: $rxStart)';
  }
}
