import 'package:flutter_test/flutter_test.dart';
import 'package:programming_card_host/core/utils/hex_parser.dart';

void main() {
  group('HexParser', () {
    late HexParser parser;

    setUp(() {
      parser = HexParser();
    });

    group('parseContent', () {
      test('解析简单的HEX文件', () {
        // 简单的HEX文件示例（正确的校验和）
        const hexContent = '''
:10000000000102030405060708090A0B0C0D0E0F78
:00000001FF
''';

        final result = parser.parseContent(hexContent);
        expect(result, isTrue);
        expect(parser.getDataBytes(), equals(16));
        expect(parser.minAddress, equals(0));
        expect(parser.maxAddress, equals(15));
      });

      test('解析空内容返回true', () {
        const hexContent = '';
        final result = parser.parseContent(hexContent);
        expect(result, isTrue);
        expect(parser.getDataBytes(), equals(0));
      });

      test('解析无效格式返回false', () {
        const hexContent = 'invalid hex content';
        final result = parser.parseContent(hexContent);
        expect(result, isFalse);
      });

      test('解析包含扩展线性地址的HEX文件', () {
        const hexContent = '''
:020000040000FA
:10000000000102030405060708090A0B0C0D0E0F78
:020000040001F9
:10000000101112131415161718191A1B1C1D1E1F78
:00000001FF
''';

        final result = parser.parseContent(hexContent);
        expect(result, isTrue);
        expect(parser.getDataBytes(), equals(32));
      });
    });

    group('getDataBlocks', () {
      test('获取数据块（默认256字节）', () {
        const hexContent = '''
:10000000000102030405060708090A0B0C0D0E0F78
:10001000101112131415161718191A1B1C1D1E1F68
:00000001FF
''';

        parser.parseContent(hexContent);
        final blocks = parser.getDataBlocks();

        expect(blocks, isNotEmpty);
        expect(blocks.first.address, equals(0));
        expect(blocks.first.data.length, equals(32));
      });

      test('获取数据块（自定义块大小）', () {
        const hexContent = '''
:10000000000102030405060708090A0B0C0D0E0F78
:10001000101112131415161718191A1B1C1D1E1F68
:10002000202122232425262728292A2B2C2D2E2F58
:10003000303132333435363738393A3B3C3D3E3F48
:00000001FF
''';

        parser.parseContent(hexContent);
        final blocks = parser.getDataBlocks(blockSize: 16);

        expect(blocks.length, greaterThan(1));
        for (final block in blocks) {
          expect(block.data.length, lessThanOrEqualTo(16));
        }
      });

      test('空数据返回空列表', () {
        final blocks = parser.getDataBlocks();
        expect(blocks, isEmpty);
      });
    });

    group('getTotalSize', () {
      test('计算固件总大小', () {
        const hexContent = '''
:10000000000102030405060708090A0B0C0D0E0F78
:10001000101112131415161718191A1B1C1D1E1F68
:00000001FF
''';

        parser.parseContent(hexContent);
        final totalSize = parser.getTotalSize();

        expect(totalSize, equals(32));
      });

      test('空数据返回0', () {
        final totalSize = parser.getTotalSize();
        expect(totalSize, equals(0));
      });
    });

    group('getDataBytes', () {
      test('计算实际数据字节数', () {
        const hexContent = '''
:10000000000102030405060708090A0B0C0D0E0F78
:00000001FF
''';

        parser.parseContent(hexContent);
        final dataBytes = parser.getDataBytes();

        expect(dataBytes, equals(16));
      });

      test('空数据返回0', () {
        final dataBytes = parser.getDataBytes();
        expect(dataBytes, equals(0));
      });
    });

    group('FlashBlock', () {
      test('FlashBlock toString格式正确', () {
        final block = FlashBlock(
          address: 0x1000,
          data: [0x01, 0x02, 0x03],
        );

        final str = block.toString();
        expect(str, contains('0x00001000'));
        expect(str, contains('3 bytes'));
      });
    });
  });
}
