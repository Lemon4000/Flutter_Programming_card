import 'lib/core/utils/hex_parser.dart';

void main() {
  print('=== 测试实际的 HEX 文件内容 ===\n');

  final parser = HexParser();

  // 修复后的文件内容
  const hexContent = '''
:020000040000FA
:10000000C02000209100000893000008950000081F
:1000100097000008990000080000000000000000A0
:100020000000000000000000000000009B0000082D
:100030009D0000080000000000000000000000001B
:00000001FF
''';

  print('开始解析...\n');
  final result = parser.parseContent(hexContent);

  print('\n解析结果: $result');
  if (result) {
    print('数据字节数: ${parser.getDataBytes()}');
    print('地址范围: 0x${parser.minAddress?.toRadixString(16)} - 0x${parser.maxAddress?.toRadixString(16)}');
  }
}
