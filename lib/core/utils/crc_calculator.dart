/// CRC 和校验和计算工具
class CrcCalculator {
  /// CRC16 MODBUS 算法
  /// 
  /// 多项式: 0xA001 (反向)
  /// 初始值: 0xFFFF
  /// 结果异或: 0x0000
  static int crc16Modbus(List<int> data) {
    int crc = 0xFFFF;
    
    for (var byte in data) {
      crc ^= byte & 0xFF;
      for (int i = 0; i < 8; i++) {
        if ((crc & 0x0001) != 0) {
          crc = (crc >> 1) ^ 0xA001;
        } else {
          crc >>= 1;
        }
      }
    }
    
    return crc & 0xFFFF;
  }

  /// SUM8 校验算法
  /// 
  /// 简单的字节求和，取低8位
  static int sum8(List<int> data) {
    int sum = 0;
    for (var byte in data) {
      sum += byte & 0xFF;
    }
    return sum & 0xFF;
  }

  /// 根据校验类型计算校验值
  /// 
  /// 返回校验值的字节列表（小端序）
  static List<int> calculateChecksum(List<int> data, String checksumType) {
    switch (checksumType.toUpperCase()) {
      case 'CRC16_MODBUS':
      case 'CRC16':
        final crc = crc16Modbus(data);
        // 小端序：低字节在前
        return [crc & 0xFF, (crc >> 8) & 0xFF];
      
      case 'SUM8':
        return [sum8(data)];
      
      default:
        throw ArgumentError('不支持的校验类型: $checksumType');
    }
  }

  /// 验证校验值
  /// 
  /// 返回 true 如果校验通过
  static bool verifyChecksum(
    List<int> data,
    List<int> checksum,
    String checksumType,
  ) {
    final calculated = calculateChecksum(data, checksumType);
    
    if (calculated.length != checksum.length) {
      return false;
    }
    
    for (int i = 0; i < calculated.length; i++) {
      if (calculated[i] != checksum[i]) {
        return false;
      }
    }
    
    return true;
  }

  /// 将十六进制字符串转换为字节列表
  static List<int> hexStringToBytes(String hex) {
    final bytes = <int>[];
    // 移除空格和其他分隔符
    hex = hex.replaceAll(RegExp(r'[\s,:-]'), '');
    
    for (int i = 0; i < hex.length; i += 2) {
      if (i + 1 < hex.length) {
        final byteStr = hex.substring(i, i + 2);
        bytes.add(int.parse(byteStr, radix: 16));
      }
    }
    
    return bytes;
  }

  /// 将字节列表转换为十六进制字符串
  static String bytesToHexString(List<int> bytes, {String separator = ' '}) {
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(separator);
  }
}
