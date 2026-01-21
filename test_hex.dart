import 'lib/core/utils/hex_parser.dart';

void main() {
  final parser = HexParser();
  
  // 测试单行
  const line1 = '020000040000FA';
  print('测试行1: :$line1');
  
  const hexContent = '''
:020000040000FA
:10000000214601360121470136007EFE09D2194191
:00000001FF
''';

  print('\n开始解析完整HEX...');
  try {
    final result = parser.parseContent(hexContent);
    print('解析结果: $result');
    print('数据字节数: ${parser.getDataBytes()}');
  } catch (e) {
    print('错误: $e');
  }
}
