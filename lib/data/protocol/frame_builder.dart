import 'protocol_config.dart';
import '../../core/utils/crc_calculator.dart';

/// 协议帧构建器
class FrameBuilder {
  final ProtocolConfig config;

  FrameBuilder(this.config);

  /// 构建读取请求帧
  /// 
  /// 格式: [前导码]!READ:A;[校验值]
  /// 
  /// 参数:
  /// - [group]: 参数组名称（如 'A'）
  List<int> buildReadRequest(String group) {
    // 构建载荷: !READ:A;
    final payload = '${config.txStart}READ:$group;';
    final payloadBytes = payload.codeUnits;
    
    // 添加前导码
    final preambleBytes = config.getPreambleBytes();
    
    // 计算校验值
    final checksum = CrcCalculator.calculateChecksum(
      payloadBytes,
      config.checksumType.value,
    );
    
    // 组合完整帧
    return [...preambleBytes, ...payloadBytes, ...checksum];
  }

  /// 构建写入帧
  /// 
  /// 格式: [前导码]!WRITEA0:14.00,A1:60.00;[校验值]
  /// 
  /// 参数:
  /// - [group]: 参数组名称
  /// - [values]: 参数键值对 {A0: 14.0, A1: 60.0}
  /// - [precisionMap]: 精度映射 {A0: 2, A1: 2}
  List<int> buildWriteFrame(
    String group,
    Map<String, double> values,
    Map<String, int> precisionMap,
  ) {
    // 按键名排序（A0, A1, A2...）
    final sortedKeys = values.keys.toList()
      ..sort((a, b) {
        final numA = int.tryParse(a.substring(1)) ?? 0;
        final numB = int.tryParse(b.substring(1)) ?? 0;
        return numA.compareTo(numB);
      });

    // 构建参数字符串: A0:14.00,A1:60.00
    final parts = <String>[];
    for (var key in sortedKeys) {
      final value = values[key]!;
      final precision = precisionMap[key] ?? 2;
      final valueStr = value.toStringAsFixed(precision);
      parts.add('$key:$valueStr');
    }

    // 构建载荷: !WRITEA0:14.00,A1:60.00;
    final payload = '${config.txStart}WRITE${parts.join(',')};';
    final payloadBytes = payload.codeUnits;
    
    // 添加前导码
    final preambleBytes = config.getPreambleBytes();
    
    // 计算校验值
    final checksum = CrcCalculator.calculateChecksum(
      payloadBytes,
      config.checksumType.value,
    );
    
    // 组合完整帧
    return [...preambleBytes, ...payloadBytes, ...checksum];
  }

  /// 构建初始化帧
  ///
  /// 格式: [前导码]!HEX;[校验值]
  List<int> buildInitFrame() {
    // 构建载荷: !HEX;
    final payload = '${config.txStart}HEX;';
    final payloadBytes = payload.codeUnits;

    // 添加前导码
    final preambleBytes = config.getPreambleBytes();

    // 计算校验值
    final checksum = CrcCalculator.calculateChecksum(
      payloadBytes,
      config.checksumType.value,
    );

    // 组合完整帧
    return [...preambleBytes, ...payloadBytes, ...checksum];
  }

  /// 构建擦除帧
  ///
  /// 格式: [前导码]!HEX:ESIZE[块数];[校验值]
  ///
  /// 参数:
  /// - [blockCount]: 数据块数量
  List<int> buildEraseFrame(int blockCount) {
    // 构建载荷: !HEX:ESIZE[块数];
    final payload = '${config.txStart}HEX:ESIZE$blockCount;';
    final payloadBytes = payload.codeUnits;

    // 添加前导码
    final preambleBytes = config.getPreambleBytes();

    // 计算校验值
    final checksum = CrcCalculator.calculateChecksum(
      payloadBytes,
      config.checksumType.value,
    );

    // 组合完整帧
    return [...preambleBytes, ...payloadBytes, ...checksum];
  }

  /// 构建烧录数据帧
  ///
  /// 格式: [前导码]!HEX:START[地址],SIZE[大小],DATA[二进制数据];[校验值]
  ///
  /// 参数:
  /// - [address]: 起始地址（8位16进制，无0x前缀）
  /// - [data]: 数据字节
  List<int> buildFlashDataFrame(int address, List<int> data) {
    // 构建头部: !HEX:START08000000,SIZE256,DATA
    // 注意：地址格式为 8 位 16 进制，无 0x 前缀
    final header = '${config.txStart}HEX:START${address.toRadixString(16).toUpperCase().padLeft(8, '0')}'
        ',SIZE${data.length},DATA';

    // 构建载荷: 头部 + 二进制数据 + 分号
    final payloadBytes = [
      ...header.codeUnits,
      ...data,
      ';'.codeUnitAt(0),
    ];

    // 添加前导码
    final preambleBytes = config.getPreambleBytes();

    // 计算校验值
    final checksum = CrcCalculator.calculateChecksum(
      payloadBytes,
      config.checksumType.value,
    );

    // 组合完整帧
    return [...preambleBytes, ...payloadBytes, ...checksum];
  }

  /// 构建烧录校验帧
  ///
  /// 格式: [前导码]!HEX:ENDCRC[2字节CRC];[校验值]
  ///
  /// 参数:
  /// - [totalCrc]: 累计CRC值（2字节，大端序）
  List<int> buildFlashVerifyFrame(int totalCrc) {
    // 构建头部: !HEX:ENDCRC
    final header = '${config.txStart}HEX:ENDCRC';

    // 2字节CRC（大端序）
    final crcBytes = [
      (totalCrc >> 8) & 0xFF,  // 高字节
      totalCrc & 0xFF,         // 低字节
    ];

    // 构建载荷: 头部 + 2字节CRC + 分号
    final payloadBytes = [
      ...header.codeUnits,
      ...crcBytes,
      ';'.codeUnitAt(0),
    ];

    // 添加前导码
    final preambleBytes = config.getPreambleBytes();

    // 计算校验值
    final checksum = CrcCalculator.calculateChecksum(
      payloadBytes,
      config.checksumType.value,
    );

    // 组合完整帧
    return [...preambleBytes, ...payloadBytes, ...checksum];
  }
}
