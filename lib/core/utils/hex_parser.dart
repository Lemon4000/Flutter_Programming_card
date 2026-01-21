/// Intel HEX文件解析器
///
/// 支持解析标准的Intel HEX文件格式，用于固件烧录功能
class HexParser {
  // 记录类型常量
  static const int dataRecord = 0x00;
  static const int eofRecord = 0x01;
  static const int extendedSegmentAddress = 0x02;
  static const int startSegmentAddress = 0x03;
  static const int extendedLinearAddress = 0x04;
  static const int startLinearAddress = 0x05;

  /// 地址到字节值的映射
  final Map<int, int> _dataMap = {};

  /// 最小地址
  int? minAddress;

  /// 最大地址
  int? maxAddress;

  /// 解析HEX文件内容
  ///
  /// 参数:
  /// - [hexContent]: HEX文件的文本内容
  ///
  /// 返回:
  /// - 解析成功返回true，失败返回false
  bool parseContent(String hexContent) {
    try {
      print('=== HEX 解析开始 ===');
      print('内容长度: ${hexContent.length} 字符');

      _dataMap.clear();
      minAddress = null;
      maxAddress = null;

      final lines = hexContent.split('\n');
      print('总行数: ${lines.length}');

      int extendedAddress = 0;

      for (int lineNum = 0; lineNum < lines.length; lineNum++) {
        final line = lines[lineNum].trim();
        if (line.isEmpty) continue;

        if (!line.startsWith(':')) {
          print('错误：第 $lineNum 行不以 ":" 开头: $line');
          return false;
        }

        // 解析记录
        final record = _parseLine(line.substring(1), extendedAddress);
        if (record == null) {
          print('错误：第 $lineNum 行解析失败: $line');
          return false;
        }

        // 处理不同类型的记录
        if (record.recordType == dataRecord) {
          // 数据记录
          for (int i = 0; i < record.data.length; i++) {
            final addr = record.address + i;
            _dataMap[addr] = record.data[i];

            if (minAddress == null || addr < minAddress!) {
              minAddress = addr;
            }
            if (maxAddress == null || addr > maxAddress!) {
              maxAddress = addr;
            }
          }
        } else if (record.recordType == extendedLinearAddress) {
          // 扩展线性地址
          if (record.data.length == 2) {
            extendedAddress = (record.data[0] << 8 | record.data[1]) << 16;
          }
        } else if (record.recordType == eofRecord) {
          // 文件结束
          break;
        }
      }

      print('解析完成：');
      print('  - 数据字节数: ${_dataMap.length}');
      print('  - 地址范围: 0x${minAddress?.toRadixString(16)} - 0x${maxAddress?.toRadixString(16)}');
      print('=== HEX 解析结束 ===');

      return true;
    } catch (e) {
      print('HEX 解析异常: $e');
      return false;
    }
  }

  /// 解析单行HEX记录
  _HexRecord? _parseLine(String line, int extendedAddress) {
    try {
      // 移除空格
      line = line.replaceAll(' ', '');

      if (line.length < 10) {
        return null;
      }

      // 解析各字段
      final byteCount = int.parse(line.substring(0, 2), radix: 16);
      final address = int.parse(line.substring(2, 6), radix: 16);
      final recordType = int.parse(line.substring(6, 8), radix: 16);

      // 提取数据
      const dataStart = 8;
      final dataEnd = dataStart + byteCount * 2;

      if (line.length < dataEnd + 2) {
        return null;
      }

      final dataHex = line.substring(dataStart, dataEnd);

      // 将十六进制字符串转换为字节列表
      final data = <int>[];
      for (int i = 0; i < dataHex.length; i += 2) {
        data.add(int.parse(dataHex.substring(i, i + 2), radix: 16));
      }

      // 校验和
      final checksum = int.parse(line.substring(dataEnd, dataEnd + 2), radix: 16);

      // 验证校验和
      int calcSum = byteCount + (address >> 8) + (address & 0xFF) + recordType;
      for (final byte in data) {
        calcSum += byte;
      }
      calcSum = ((~(calcSum & 0xFF)) + 1) & 0xFF;

      if (calcSum != checksum) {
        throw FormatException(
          '校验和错误 (计算:${calcSum.toRadixString(16).toUpperCase().padLeft(2, '0')}, '
          '实际:${checksum.toRadixString(16).toUpperCase().padLeft(2, '0')})',
        );
      }

      // 计算完整地址
      final fullAddress = extendedAddress + address;

      return _HexRecord(
        address: fullAddress,
        data: data,
        recordType: recordType,
      );
    } catch (e) {
      return null;
    }
  }

  /// 获取数据块列表
  ///
  /// 参数:
  /// - [blockSize]: 每个数据块的最大大小（字节）
  ///
  /// 返回:
  /// - 数据块列表，每个块包含起始地址和数据
  List<FlashBlock> getDataBlocks({int blockSize = 256}) {
    if (_dataMap.isEmpty) {
      return [];
    }

    final blocks = <FlashBlock>[];
    final addresses = _dataMap.keys.toList()..sort();

    if (addresses.isEmpty) {
      return [];
    }

    // 分块
    int currentStart = addresses[0];
    final currentData = <int>[];

    for (final addr in addresses) {
      // 如果地址不连续或超过块大小，创建新块
      if ((addr != currentStart + currentData.length) ||
          (currentData.length >= blockSize)) {
        if (currentData.isNotEmpty) {
          blocks.add(FlashBlock(
            address: currentStart,
            data: List.from(currentData),
          ));
        }
        currentStart = addr;
        currentData.clear();
      }

      currentData.add(_dataMap[addr]!);
    }

    // 添加最后一个块
    if (currentData.isNotEmpty) {
      blocks.add(FlashBlock(
        address: currentStart,
        data: List.from(currentData),
      ));
    }

    return blocks;
  }

  /// 获取固件总大小（字节）
  int getTotalSize() {
    if (minAddress == null || maxAddress == null) {
      return 0;
    }
    return maxAddress! - minAddress! + 1;
  }

  /// 获取实际数据字节数
  int getDataBytes() {
    return _dataMap.length;
  }

  /// 计算所有数据的CRC16
  ///
  /// 返回:
  /// - CRC16校验值
  int calculateCRC() {
    if (_dataMap.isEmpty) {
      return 0;
    }

    // 按地址排序获取所有数据
    final addresses = _dataMap.keys.toList()..sort();
    final allData = addresses.map((addr) => _dataMap[addr]!).toList();

    // 计算CRC16 MODBUS
    int crc = 0xFFFF;
    for (final byte in allData) {
      crc ^= byte;
      for (int i = 0; i < 8; i++) {
        if ((crc & 1) != 0) {
          crc = (crc >> 1) ^ 0xA001;
        } else {
          crc >>= 1;
        }
      }
    }
    return crc & 0xFFFF;
  }
}

/// HEX记录内部类
class _HexRecord {
  final int address;
  final List<int> data;
  final int recordType;

  _HexRecord({
    required this.address,
    required this.data,
    required this.recordType,
  });
}

/// 烧录数据块
class FlashBlock {
  /// 起始地址
  final int address;

  /// 数据内容
  final List<int> data;

  FlashBlock({
    required this.address,
    required this.data,
  });

  @override
  String toString() {
    return 'FlashBlock(address: 0x${address.toRadixString(16).toUpperCase().padLeft(8, '0')}, '
        'size: ${data.length} bytes)';
  }
}
