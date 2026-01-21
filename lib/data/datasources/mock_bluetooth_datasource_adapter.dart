import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'simple_mock_bluetooth_datasource.dart';

/// 模拟蓝牙数据源适配器
///
/// 将SimpleMockBluetoothDatasource适配为BluetoothDatasource接口
class MockBluetoothDatasourceAdapter {
  final SimpleMockBluetoothDatasource _mock = SimpleMockBluetoothDatasource();
  final Map<String, BluetoothDevice> _deviceCache = {};

  /// 数据接收流
  Stream<List<int>> get dataStream => _mock.dataStream;

  /// 当前连接的设备
  BluetoothDevice? get connectedDevice {
    final deviceId = _mock.connectedDeviceId;
    if (deviceId == null) return null;
    return _deviceCache[deviceId];
  }

  /// 是否已连接
  bool get isConnected => _mock.isConnected;

  /// 扫描蓝牙设备
  Stream<List<ScanResult>> scanDevices({
    Duration timeout = const Duration(seconds: 10),
  }) async* {
    await for (final mockResults in _mock.scanDevices(timeout: timeout)) {
      // 转换为ScanResult
      // 注意：由于ScanResult构造函数限制，我们需要创建假的BluetoothDevice
      // 这里我们直接返回空列表，并在UI层使用模拟数据
      yield [];
    }
  }

  /// 停止扫描
  Future<void> stopScan() => _mock.stopScan();

  /// 连接设备
  Future<void> connect(
    BluetoothDevice device, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final deviceId = device.remoteId.toString();
    _deviceCache[deviceId] = device;
    await _mock.connect(deviceId, timeout: timeout);
  }

  /// 断开连接
  Future<void> disconnect() => _mock.disconnect();

  /// 发送数据
  Future<void> write(
    List<int> data, {
    bool withoutResponse = false,
  }) =>
      _mock.write(data, withoutResponse: withoutResponse);

  /// 获取连接状态流
  Stream<BluetoothConnectionState> get connectionStateStream {
    return Stream.periodic(const Duration(seconds: 1), (_) {
      return _mock.getConnectionState()
          ? BluetoothConnectionState.connected
          : BluetoothConnectionState.disconnected;
    });
  }

  /// 释放资源
  void dispose() => _mock.dispose();
}
