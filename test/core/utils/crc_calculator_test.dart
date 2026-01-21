import 'package:flutter_test/flutter_test.dart';
import 'package:programming_card_host/core/utils/crc_calculator.dart';

void main() {
  group('CrcCalculator', () {
    group('crc16Modbus', () {
      test('计算空数据的CRC16', () {
        final result = CrcCalculator.crc16Modbus([]);
        expect(result, equals(0xFFFF));
      });

      test('计算单字节数据的CRC16', () {
        final result = CrcCalculator.crc16Modbus([0x01]);
        expect(result, equals(0x807E)); // 32894
      });

      test('计算多字节数据的CRC16', () {
        // 测试数据: "123456789"
        final data = [0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39];
        final result = CrcCalculator.crc16Modbus(data);
        // CRC16 MODBUS标准测试向量的期望值
        expect(result, equals(0x4B37));
      });

      test('计算协议帧数据的CRC16', () {
        // 模拟一个简单的协议帧
        final data = [0xFC, 0x21, 0x52, 0x45, 0x41, 0x44, 0x3A, 0x41, 0x3B];
        final result = CrcCalculator.crc16Modbus(data);
        expect(result, isA<int>());
        expect(result, greaterThanOrEqualTo(0));
        expect(result, lessThanOrEqualTo(0xFFFF));
      });
    });

    group('sum8', () {
      test('计算空数据的SUM8', () {
        final result = CrcCalculator.sum8([]);
        expect(result, equals(0));
      });

      test('计算单字节数据的SUM8', () {
        final result = CrcCalculator.sum8([0x01]);
        expect(result, equals(0x01));
      });

      test('计算多字节数据的SUM8', () {
        final data = [0x01, 0x02, 0x03, 0x04, 0x05];
        final result = CrcCalculator.sum8(data);
        expect(result, equals(0x0F)); // 1+2+3+4+5 = 15
      });

      test('计算溢出数据的SUM8', () {
        final data = [0xFF, 0xFF, 0xFF];
        final result = CrcCalculator.sum8(data);
        expect(result, equals(0xFD)); // (255+255+255) & 0xFF = 765 & 0xFF = 253
      });
    });

    group('crc16ToBytes', () {
      test('转换CRC16为字节数组（小端序）', () {
        final bytes = CrcCalculator.crc16ToBytes(0x1234);
        expect(bytes, equals([0x34, 0x12])); // 小端序：低字节在前
      });

      test('转换0x0000', () {
        final bytes = CrcCalculator.crc16ToBytes(0x0000);
        expect(bytes, equals([0x00, 0x00]));
      });

      test('转换0xFFFF', () {
        final bytes = CrcCalculator.crc16ToBytes(0xFFFF);
        expect(bytes, equals([0xFF, 0xFF]));
      });
    });

    group('bytesToCrc16', () {
      test('从字节数组解析CRC16（小端序）', () {
        final crc = CrcCalculator.bytesToCrc16([0x34, 0x12]);
        expect(crc, equals(0x1234));
      });

      test('解析0x0000', () {
        final crc = CrcCalculator.bytesToCrc16([0x00, 0x00]);
        expect(crc, equals(0x0000));
      });

      test('解析0xFFFF', () {
        final crc = CrcCalculator.bytesToCrc16([0xFF, 0xFF]);
        expect(crc, equals(0xFFFF));
      });

      test('字节数组长度不足时抛出异常', () {
        expect(
          () => CrcCalculator.bytesToCrc16([0x34]),
          throwsArgumentError,
        );
      });
    });

    group('往返转换', () {
      test('CRC16值往返转换保持一致', () {
        const originalCrc = 0x4B37;
        final bytes = CrcCalculator.crc16ToBytes(originalCrc);
        final parsedCrc = CrcCalculator.bytesToCrc16(bytes);
        expect(parsedCrc, equals(originalCrc));
      });
    });
  });
}
