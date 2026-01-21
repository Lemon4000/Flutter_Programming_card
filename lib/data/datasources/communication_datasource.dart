import 'dart:async';

/// 通信数据源接口
///
/// 定义蓝牙和串口通信的统一接口
abstract class CommunicationDatasource {
  /// 数据接收流
  Stream<List<int>> get dataStream;

  /// 连接状态流
  Stream<bool> get connectionStateStream;

  /// 是否已连接
  bool get isConnected;

  /// 发送数据
  Future<void> write(List<int> data);

  /// 断开连接
  Future<void> disconnect();

  /// 清理资源
  void dispose();
}

/// 通信类型
enum CommunicationType {
  bluetooth('蓝牙'),
  serialPort('串口');

  final String displayName;
  const CommunicationType(this.displayName);
}
