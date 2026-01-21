import 'protocol_config.dart';
import '../../core/utils/crc_calculator.dart';

/// 解析后的参数数据
class ParsedParameterData {
  final Map<String, double> values;

  ParsedParameterData(this.values);

  /// 根据键查找参数值
  double? getValue(String key) {
    return values[key];
  }
}

/// 解析后的烧录响应
class ParsedFlashResponse {
  final bool success;
  final int? crc;
  final String? message;

  ParsedFlashResponse({
    required this.success,
    this.crc,
    this.message,
  });
}

/// 解析后的初始化响应
class ParsedInitResponse {
  final bool success;
  ParsedInitResponse(this.success);
}

/// 解析后的擦除响应
class ParsedEraseResponse {
  final bool success;
  ParsedEraseResponse(this.success);
}

/// 解析后的编程响应
class ParsedProgramResponse {
  final bool success;
  final List<int> replyCrc;  // 2字节原始CRC
  ParsedProgramResponse({required this.success, required this.replyCrc});
}

/// 解析后的校验响应
class ParsedVerifyResponse {
  final bool success;
  final List<int> replyCrc;  // 2字节原始CRC
  ParsedVerifyResponse({required this.success, required this.replyCrc});
}

/// 协议帧解析器
class FrameParser {
  final ProtocolConfig config;

  FrameParser(this.config);

  /// 解析参数读取响应
  /// 
  /// 格式: [前导码]#A0:14.00,A1:60.00;[校验值]
  /// 
  /// 返回: ParsedParameterData 或 null（解析失败）
  ParsedParameterData? parseParameterResponse(List<int> frame) {
    try {
      // 1. 检查前导码
      final preambleBytes = config.getPreambleBytes();
      if (frame.length < preambleBytes.length + 3) {
        return null; // 帧太短
      }

      for (int i = 0; i < preambleBytes.length; i++) {
        if (frame[i] != preambleBytes[i]) {
          return null; // 前导码不匹配
        }
      }

      // 2. 提取载荷（去掉前导码和校验值）
      final checksumLength = config.checksumType == ChecksumType.crc16Modbus ? 2 : 1;
      final payloadBytes = frame.sublist(
        preambleBytes.length,
        frame.length - checksumLength,
      );
      final checksumBytes = frame.sublist(frame.length - checksumLength);

      // 3. 验证校验值
      if (!CrcCalculator.verifyChecksum(
        payloadBytes,
        checksumBytes,
        config.checksumType.value,
      )) {
        return null; // 校验失败
      }

      // 4. 解析载荷
      final payload = String.fromCharCodes(payloadBytes);
      
      // 检查起始符
      if (!payload.startsWith(config.rxStart)) {
        return null;
      }

      // 移除起始符和结束符
      final content = payload.substring(1, payload.length - 1);

      // 解析参数: A0:14.00,A1:60.00
      final values = <String, double>{};
      final parts = content.split(',');
      
      for (var part in parts) {
        final keyValue = part.split(':');
        if (keyValue.length == 2) {
          final key = keyValue[0].trim();
          final value = double.tryParse(keyValue[1].trim());
          if (value != null) {
            values[key] = value;
          }
        }
      }

      return ParsedParameterData(values);
    } catch (e) {
      return null;
    }
  }

  /// 解析烧录响应
  /// 
  /// 格式: [前导码]#OK:CRC0xABCD;[校验值] 或 #ERROR:message;
  ParsedFlashResponse? parseFlashResponse(List<int> frame) {
    try {
      // 1. 检查前导码
      final preambleBytes = config.getPreambleBytes();
      if (frame.length < preambleBytes.length + 3) {
        return null;
      }

      for (int i = 0; i < preambleBytes.length; i++) {
        if (frame[i] != preambleBytes[i]) {
          return null;
        }
      }

      // 2. 提取载荷
      final checksumLength = config.checksumType == ChecksumType.crc16Modbus ? 2 : 1;
      final payloadBytes = frame.sublist(
        preambleBytes.length,
        frame.length - checksumLength,
      );
      final checksumBytes = frame.sublist(frame.length - checksumLength);

      // 3. 验证校验值
      if (!CrcCalculator.verifyChecksum(
        payloadBytes,
        checksumBytes,
        config.checksumType.value,
      )) {
        return null;
      }

      // 4. 解析载荷
      final payload = String.fromCharCodes(payloadBytes);
      
      if (!payload.startsWith(config.rxStart)) {
        return null;
      }

      final content = payload.substring(1, payload.length - 1);

      // 解析响应
      if (content.startsWith('OK')) {
        // 成功响应: OK:CRC0xABCD
        int? crc;
        if (content.contains('CRC')) {
          final crcMatch = RegExp(r'CRC0x([0-9A-Fa-f]+)').firstMatch(content);
          if (crcMatch != null) {
            crc = int.tryParse(crcMatch.group(1)!, radix: 16);
          }
        }
        return ParsedFlashResponse(success: true, crc: crc);
      } else if (content.startsWith('ERROR')) {
        // 错误响应: ERROR:message
        final message = content.substring(6);
        return ParsedFlashResponse(success: false, message: message);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// 查找完整帧
  ///
  /// 从缓冲区中查找并提取完整的帧
  /// 返回: (帧数据, 剩余缓冲区)
  (List<int>?, List<int>) findCompleteFrame(List<int> buffer) {
    // 优化：移除调试日志以提升性能
    final preambleBytes = config.getRxPreambleBytes();  // 使用接收前导码

    // 如果没有前导码，直接查找起始符
    if (preambleBytes.isEmpty) {
      return _findFrameWithoutPreamble(buffer);
    }

    // 查找前导码
    int startIndex = -1;
    for (int i = 0; i <= buffer.length - preambleBytes.length; i++) {
      bool match = true;
      for (int j = 0; j < preambleBytes.length; j++) {
        if (buffer[i + j] != preambleBytes[j]) {
          match = false;
          break;
        }
      }
      if (match) {
        startIndex = i;
        break;
      }
    }

    if (startIndex == -1) {
      // 没找到前导码，清空缓冲区
      return (null, []);
    }

    // 查找结束符 ';'
    int endIndex = -1;
    for (int i = startIndex + preambleBytes.length; i < buffer.length; i++) {
      if (buffer[i] == ';'.codeUnitAt(0)) {
        endIndex = i;
        break;
      }
    }

    if (endIndex == -1) {
      // 没找到结束符，保留从前导码开始的数据
      return (null, buffer.sublist(startIndex));
    }

    // 计算帧长度（包括校验值）
    final checksumLength = config.checksumType == ChecksumType.crc16Modbus ? 2 : 1;
    final frameEnd = endIndex + 1 + checksumLength;

    if (frameEnd > buffer.length) {
      // 数据不完整，保留
      return (null, buffer.sublist(startIndex));
    }

    // 提取完整帧
    final frame = buffer.sublist(startIndex, frameEnd);
    final remaining = buffer.sublist(frameEnd);

    return (frame, remaining);
  }

  /// 无前导码时查找帧
  (List<int>?, List<int>) _findFrameWithoutPreamble(List<int> buffer) {
    // 优化：移除调试日志以提升性能
    // 查找起始符（# 或 !）
    final rxStart = config.rxStart.codeUnitAt(0);
    final txStart = config.txStart.codeUnitAt(0);

    int startIndex = -1;
    for (int i = 0; i < buffer.length; i++) {
      if (buffer[i] == rxStart || buffer[i] == txStart) {
        startIndex = i;
        break;
      }
    }

    if (startIndex == -1) {
      return (null, []);
    }

    // 尝试解析帧头，判断是否包含二进制数据
    // 检查是否是 #HEX:REPLY 格式（包含2字节二进制CRC）
    if (startIndex + 13 <= buffer.length) {
      try {
        final possiblePrefix = String.fromCharCodes(buffer.sublist(startIndex, startIndex + 10));
        if (possiblePrefix == '${config.rxStart}HEX:REPLY') {
          // 这是 REPLY 格式，固定长度13字节 + 校验值
          final checksumLength = config.checksumType == ChecksumType.crc16Modbus ? 2 : 1;
          final frameEnd = startIndex + 13 + checksumLength;

          if (frameEnd <= buffer.length) {
            final frame = buffer.sublist(startIndex, frameEnd);
            final remaining = buffer.sublist(frameEnd);
            return (frame, remaining);
          } else {
            return (null, buffer.sublist(startIndex));
          }
        }
      } catch (e) {
        // 继续使用默认逻辑
      }
    }

    // 对于其他格式（不包含二进制数据），查找结束符 ';'
    int endIndex = -1;
    for (int i = startIndex + 1; i < buffer.length; i++) {
      if (buffer[i] == ';'.codeUnitAt(0)) {
        endIndex = i;
        break;
      }
    }

    if (endIndex == -1) {
      return (null, buffer.sublist(startIndex));
    }

    // 计算帧长度（包括校验值）
    final checksumLength = config.checksumType == ChecksumType.crc16Modbus ? 2 : 1;
    final frameEnd = endIndex + 1 + checksumLength;

    if (frameEnd > buffer.length) {
      return (null, buffer.sublist(startIndex));
    }

    // 提取完整帧（不包含前导码）
    final frame = buffer.sublist(startIndex, frameEnd);
    final remaining = buffer.sublist(frameEnd);

    return (frame, remaining);
  }

  /// 解析初始化响应
  ///
  /// 格式: [前导码]#HEX;[校验值] 或 #HEX;[校验值]（无前导码）
  ParsedInitResponse? parseInitResponse(List<int> frame) {
    try {
      // 优化：移除调试日志以提升性能
      // 1. 检查前导码
      final preambleBytes = config.getRxPreambleBytes();  // 使用接收前导码

      if (frame.length < preambleBytes.length + 3) {
        return null;
      }

      // 验证前导码（如果有）
      for (int i = 0; i < preambleBytes.length; i++) {
        if (frame[i] != preambleBytes[i]) {
          return null;
        }
      }

      // 2. 提取载荷
      final checksumLength = config.checksumType == ChecksumType.crc16Modbus ? 2 : 1;

      final payloadBytes = frame.sublist(
        preambleBytes.length,
        frame.length - checksumLength,
      );
      final checksumBytes = frame.sublist(frame.length - checksumLength);

      // 3. 验证校验值
      if (!CrcCalculator.verifyChecksum(
        payloadBytes,
        checksumBytes,
        config.checksumType.value,
      )) {
        return null;
      }

      // 4. 解析载荷
      final payload = String.fromCharCodes(payloadBytes);

      if (!payload.startsWith(config.rxStart)) {
        return null;
      }

      // 检查格式: #HEX;
      final expected = '${config.rxStart}HEX;';
      if (payload == expected) {
        return ParsedInitResponse(true);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// 解析擦除响应
  ///
  /// 格式: [前导码]#HEX:ERASE;[校验值]
  ParsedEraseResponse? parseEraseResponse(List<int> frame) {
    try {
      // 1. 检查前导码
      final preambleBytes = config.getPreambleBytes();
      if (frame.length < preambleBytes.length + 3) {
        return null;
      }

      for (int i = 0; i < preambleBytes.length; i++) {
        if (frame[i] != preambleBytes[i]) {
          return null;
        }
      }

      // 2. 提取载荷
      final checksumLength = config.checksumType == ChecksumType.crc16Modbus ? 2 : 1;
      final payloadBytes = frame.sublist(
        preambleBytes.length,
        frame.length - checksumLength,
      );
      final checksumBytes = frame.sublist(frame.length - checksumLength);

      // 3. 验证校验值
      if (!CrcCalculator.verifyChecksum(
        payloadBytes,
        checksumBytes,
        config.checksumType.value,
      )) {
        return null;
      }

      // 4. 解析载荷
      final payload = String.fromCharCodes(payloadBytes);

      if (!payload.startsWith(config.rxStart)) {
        return null;
      }

      // 检查格式: #HEX:ERASE;
      if (payload == '${config.rxStart}HEX:ERASE;') {
        return ParsedEraseResponse(true);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// 解析编程响应
  ///
  /// 格式: [前导码]#HEX:REPLY[2字节CRC];[校验值]
  /// 注意: 2字节CRC是原始二进制（小端序）
  ParsedProgramResponse? parseProgramResponse(List<int> frame) {
    try {
      // 1. 检查前导码
      final preambleBytes = config.getPreambleBytes();
      if (frame.length < preambleBytes.length + 3) {
        return null;
      }

      for (int i = 0; i < preambleBytes.length; i++) {
        if (frame[i] != preambleBytes[i]) {
          return null;
        }
      }

      // 2. 提取载荷
      final checksumLength = config.checksumType == ChecksumType.crc16Modbus ? 2 : 1;
      final payloadBytes = frame.sublist(
        preambleBytes.length,
        frame.length - checksumLength,
      );
      final checksumBytes = frame.sublist(frame.length - checksumLength);

      // 3. 验证校验值
      if (!CrcCalculator.verifyChecksum(
        payloadBytes,
        checksumBytes,
        config.checksumType.value,
      )) {
        return null;
      }

      // 4. 检查长度（#HEX:REPLY + 2字节 + ;）
      // #HEX:REPLY = 10字节, 2字节CRC, ; = 1字节, 总共13字节
      if (payloadBytes.length != 13) {
        return null;
      }

      // 5. 检查前缀
      final prefix = String.fromCharCodes(payloadBytes.sublist(0, 10));
      if (prefix != '${config.rxStart}HEX:REPLY') {
        return null;
      }

      // 6. 提取2字节CRC（固定偏移 10:12）
      final replyCrc = payloadBytes.sublist(10, 12);

      // 7. 检查结束符
      if (payloadBytes[12] != ';'.codeUnitAt(0)) {
        return null;
      }

      return ParsedProgramResponse(success: true, replyCrc: replyCrc);
    } catch (e) {
      return null;
    }
  }

  /// 解析校验响应
  ///
  /// 格式: [前导码]#HEX:REPLY[2字节CRC];[校验值]
  /// 注意: 接受小端或大端任一形式
  ParsedVerifyResponse? parseVerifyResponse(List<int> frame) {
    try {
      // 1. 检查前导码
      final preambleBytes = config.getPreambleBytes();
      if (frame.length < preambleBytes.length + 3) {
        return null;
      }

      for (int i = 0; i < preambleBytes.length; i++) {
        if (frame[i] != preambleBytes[i]) {
          return null;
        }
      }

      // 2. 提取载荷
      final checksumLength = config.checksumType == ChecksumType.crc16Modbus ? 2 : 1;
      final payloadBytes = frame.sublist(
        preambleBytes.length,
        frame.length - checksumLength,
      );
      final checksumBytes = frame.sublist(frame.length - checksumLength);

      // 3. 验证校验值
      if (!CrcCalculator.verifyChecksum(
        payloadBytes,
        checksumBytes,
        config.checksumType.value,
      )) {
        return null;
      }

      // 4. 检查长度（#HEX:REPLY + 2字节 + ;）
      if (payloadBytes.length != 13) {
        return null;
      }

      // 5. 检查前缀
      final prefix = String.fromCharCodes(payloadBytes.sublist(0, 10));
      if (prefix != '${config.rxStart}HEX:REPLY') {
        return null;
      }

      // 6. 提取2字节CRC（固定偏移 10:12）
      final replyCrc = payloadBytes.sublist(10, 12);

      // 7. 检查结束符
      if (payloadBytes[12] != ';'.codeUnitAt(0)) {
        return null;
      }

      return ParsedVerifyResponse(success: true, replyCrc: replyCrc);
    } catch (e) {
      return null;
    }
  }
}
