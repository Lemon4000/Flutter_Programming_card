import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// 模拟蓝牙数据源
///
/// 用于在没有真实蓝牙设备的情况下测试应用
class MockBluetoothDatasource {
  BluetoothDevice? _connectedDevice;
  final _dataStreamController = StreamController<List<int>>.broadcast();

  /// 数据接收流
  Stream<List<int>> get dataStream => _dataStreamController.stream;

  /// 当前连接的设备
  BluetoothDevice? get connectedDevice => _connectedDevice;

  /// 是否已连接
  bool get isConnected => _connectedDevice != null;

  /// 扫描蓝牙设备（模拟）
  Stream<List<ScanResult>> scanDevices({
    Duration timeout = const Duration(seconds: 10),
  }) async* {
    // 模拟扫描延迟
    await Future.delayed(const Duration(seconds: 1));

    // 创建模拟设备列表
    final mockDevices = [
      _createMockScanResult('编程卡-001', 'AA:BB:CC:DD:EE:01', -45),
      _createMockScanResult('编程卡-002', 'AA:BB:CC:DD:EE:02', -60),
      _createMockScanResult('编程卡-003', 'AA:BB:CC:DD:EE:03', -75),
    ];

    // 逐个返回设备（模拟发现过程）
    for (int i = 0; i < mockDevices.length; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      yield mockDevices.sublist(0, i + 1);
    }

    // 保持扫描状态直到超时
    await Future.delayed(timeout);
  }

  /// 创建模拟扫描结果
  ScanResult _createMockScanResult(String name, String id, int rssi) {
    // 注意：这里无法真正创建ScanResult，因为它的构造函数是私有的
    // 我们需要使用不同的方法
    throw UnimplementedError('需要使用不同的模拟方式');
  }

  /// 停止扫描
  Future<void> stopScan() async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// 连接设备（模拟）
  Future<void> connect(
    BluetoothDevice device, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    // 模拟连接延迟
    await Future.delayed(const Duration(seconds: 2));

    // 模拟连接成功
    _connectedDevice = device;

    // 模拟接收数据
    _simulateDataReception();
  }

  /// 断开连接
  Future<void> disconnect() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _connectedDevice = null;
  }

  /// 发送数据（模拟）
  Future<void> write(
    List<int> data, {
    bool withoutResponse = false,
  }) async {
    if (_connectedDevice == null) {
      throw Exception('未连接设备');
    }

    // 模拟发送延迟
    await Future.delayed(const Duration(milliseconds: 100));

    // 模拟响应
    _simulateResponse(data);
  }

  /// 获取连接状态流
  Stream<BluetoothConnectionState> get connectionStateStream {
    return Stream.periodic(const Duration(seconds: 1), (_) {
      return _connectedDevice != null
          ? BluetoothConnectionState.connected
          : BluetoothConnectionState.disconnected;
    });
  }

  /// 模拟数据接收
  void _simulateDataReception() {
    // 定期发送模拟数据
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_connectedDevice == null) {
        timer.cancel();
        return;
      }

      // 模拟接收到的数据帧
      final mockData = [
        0xFC, // 前导码
        0x40, 0x52, 0x45, 0x41, 0x44, 0x3A, // @READ:
        0x41, 0x30, 0x3A, 0x32, 0x35, 0x2E, 0x30, 0x30, // A0:25.00
        0x3B, // ;
        0x12, 0x34, // CRC (示例)
      ];

      _dataStreamController.add(mockData);
    });
  }

  /// 模拟响应
  void _simulateResponse(List<int> requestData) {
    // 根据请求类型生成不同的响应
    Future.delayed(const Duration(milliseconds: 200), () {
      // 模拟读取响应
      final mockResponse = [
        0xFC, // 前导码
        0x40, 0x52, 0x45, 0x41, 0x44, 0x3A, // @READ:
        0x41, 0x30, 0x3A, 0x32, 0x35, 0x2E, 0x30, 0x30, 0x2C, // A0:25.00,
        0x41, 0x31, 0x3A, 0x36, 0x30, 0x2E, 0x30, 0x30, // A1:60.00
        0x3B, // ;
        0x12, 0x34, // CRC (示例)
      ];

      _dataStreamController.add(mockResponse);
    });
  }

  /// 释放资源
  void dispose() {
    _dataStreamController.close();
  }
}
