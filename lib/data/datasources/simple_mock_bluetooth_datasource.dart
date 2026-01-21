import 'dart:async';

/// 模拟设备信息
class MockDeviceInfo {
  final String id;
  final String name;
  final int rssi;

  const MockDeviceInfo({
    required this.id,
    required this.name,
    required this.rssi,
  });
}

/// 模拟扫描结果
class MockScanResult {
  final MockDeviceInfo device;
  final int rssi;

  const MockScanResult({
    required this.device,
    required this.rssi,
  });
}

/// 简化的模拟蓝牙数据源
///
/// 用于在没有真实蓝牙设备的情况下测试应用
class SimpleMockBluetoothDatasource {
  MockDeviceInfo? _connectedDevice;
  final _dataStreamController = StreamController<List<int>>.broadcast();
  Timer? _dataTimer;

  /// 数据接收流
  Stream<List<int>> get dataStream => _dataStreamController.stream;

  /// 当前连接的设备ID
  String? get connectedDeviceId => _connectedDevice?.id;

  /// 是否已连接
  bool get isConnected => _connectedDevice != null;

  /// 扫描蓝牙设备（模拟）
  Stream<List<MockScanResult>> scanDevices({
    Duration timeout = const Duration(seconds: 10),
  }) async* {
    print('[Mock] 开始扫描设备...');

    // 模拟扫描延迟
    await Future.delayed(const Duration(seconds: 1));

    // 创建模拟设备列表
    final mockDevices = [
      const MockScanResult(
        device: MockDeviceInfo(
          id: 'mock-device-001',
          name: '编程卡-001',
          rssi: -45,
        ),
        rssi: -45,
      ),
      const MockScanResult(
        device: MockDeviceInfo(
          id: 'mock-device-002',
          name: '编程卡-002',
          rssi: -60,
        ),
        rssi: -60,
      ),
      const MockScanResult(
        device: MockDeviceInfo(
          id: 'mock-device-003',
          name: '编程卡-003',
          rssi: -75,
        ),
        rssi: -75,
      ),
    ];

    // 逐个返回设备（模拟发现过程）
    for (int i = 0; i < mockDevices.length; i++) {
      await Future.delayed(const Duration(milliseconds: 800));
      print('[Mock] 发现设备: ${mockDevices[i].device.name}');
      yield mockDevices.sublist(0, i + 1);
    }

    print('[Mock] 扫描完成，共发现 ${mockDevices.length} 个设备');
  }

  /// 停止扫描
  Future<void> stopScan() async {
    print('[Mock] 停止扫描');
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// 连接设备（模拟）
  Future<void> connect(
    String deviceId, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    print('[Mock] 正在连接设备: $deviceId');

    // 模拟连接延迟
    await Future.delayed(const Duration(seconds: 2));

    // 查找设备
    final deviceName = deviceId.contains('001')
        ? '编程卡-001'
        : deviceId.contains('002')
            ? '编程卡-002'
            : '编程卡-003';

    // 模拟连接成功
    _connectedDevice = MockDeviceInfo(
      id: deviceId,
      name: deviceName,
      rssi: -50,
    );

    print('[Mock] 连接成功: $deviceName');

    // 开始模拟数据接收
    _startDataSimulation();
  }

  /// 断开连接
  Future<void> disconnect() async {
    print('[Mock] 断开连接: ${_connectedDevice?.name}');

    await Future.delayed(const Duration(milliseconds: 500));

    _dataTimer?.cancel();
    _dataTimer = null;
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

    print('[Mock] 发送数据: ${data.length} 字节');

    // 模拟发送延迟
    await Future.delayed(const Duration(milliseconds: 100));

    // 模拟响应
    _simulateResponse(data);
  }

  /// 获取连接状态
  bool getConnectionState() {
    return _connectedDevice != null;
  }

  /// 开始模拟数据接收
  void _startDataSimulation() {
    // 定期发送模拟数据
    _dataTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_connectedDevice == null) {
        timer.cancel();
        return;
      }

      print('[Mock] 模拟接收数据');

      // 模拟接收到的数据帧 (@READ:A0:25.00;)
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
    Future.delayed(const Duration(milliseconds: 200), () {
      print('[Mock] 发送模拟响应');

      // 模拟读取响应 (@READ:A0:25.00,A1:60.00;)
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
    _dataTimer?.cancel();
    _dataStreamController.close();
  }
}
