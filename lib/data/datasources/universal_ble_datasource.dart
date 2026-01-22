import 'dart:async';
import 'package:universal_ble/universal_ble.dart';
import 'communication_datasource.dart';

/// Universal BLE 数据源（支持 Windows）
///
/// 使用 universal_ble 库实现跨平台蓝牙支持，包括 Windows
class UniversalBleDatasource implements CommunicationDatasource {
  BleDevice? _connectedDevice;
  String? _txCharacteristicId;
  String? _rxCharacteristicId;

  final _dataStreamController = StreamController<List<int>>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();
  StreamSubscription? _connectionStateSubscription;
  StreamSubscription? _characteristicSubscription;

  // 扫描状态标志
  bool _isScanning = false;

  // 目标服务和特征 UUID
  static const String serviceUuid = '0000ffe0-0000-1000-8000-00805f9b34fb';
  static const String txCharacteristicUuid = '0000ffe1-0000-1000-8000-00805f9b34fb';
  static const String rxCharacteristicUuid = '0000ffe1-0000-1000-8000-00805f9b34fb';

  /// 数据接收流
  @override
  Stream<List<int>> get dataStream => _dataStreamController.stream;

  /// 连接状态流
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  /// 当前连接的设备
  BleDevice? get connectedDevice => _connectedDevice;

  /// 是否已连接
  @override
  bool get isConnected => _connectedDevice != null;

  /// 扫描蓝牙设备
  ///
  /// 返回扫描结果流
  Stream<List<BleDevice>> scanDevices({
    Duration timeout = const Duration(seconds: 10),
  }) async* {
    if (_isScanning) {
      return;
    }

    _isScanning = true;
    final devices = <String, BleDevice>{};

    try {
      // 开始扫描
      await UniversalBle.startScan();

      // 监听扫描结果
      final scanSubscription = UniversalBle.onScanResult.listen((device) {
        // 只添加有名称的设备
        if (device.name != null && device.name!.isNotEmpty) {
          devices[device.deviceId] = device;
        }
      });

      // 等待超时
      await Future.delayed(timeout);

      // 停止扫描
      await scanSubscription.cancel();
      await UniversalBle.stopScan();

      _isScanning = false;

      // 返回设备列表
      yield devices.values.toList();
    } catch (e) {
      _isScanning = false;
      rethrow;
    }
  }

  /// 停止扫描
  Future<void> stopScan() async {
    if (_isScanning) {
      await UniversalBle.stopScan();
      _isScanning = false;
    }
  }

  /// 连接到设备
  ///
  /// 参数:
  /// - [deviceId]: 设备 ID
  @override
  Future<void> connect(String deviceId) async {
    try {
      // 连接设备
      await UniversalBle.connect(deviceId);

      // 发现服务
      await UniversalBle.discoverServices(deviceId);

      // 获取服务列表
      final services = await UniversalBle.getServices(deviceId);

      // 查找目标服务和特征
      for (final service in services) {
        if (service.uuid.toLowerCase() == serviceUuid.toLowerCase()) {
          for (final characteristic in service.characteristics) {
            final charUuid = characteristic.uuid.toLowerCase();
            if (charUuid == txCharacteristicUuid.toLowerCase()) {
              _txCharacteristicId = characteristic.uuid;
            }
            if (charUuid == rxCharacteristicUuid.toLowerCase()) {
              _rxCharacteristicId = characteristic.uuid;

              // 订阅通知
              await UniversalBle.setNotifiable(
                deviceId,
                service.uuid,
                characteristic.uuid,
                BleInputProperty.notification,
              );

              // 监听数据
              _characteristicSubscription = UniversalBle.onValueChange.listen((event) {
                if (event.deviceId == deviceId &&
                    event.characteristicId == characteristic.uuid) {
                  _dataStreamController.add(event.value);
                }
              });
            }
          }
        }
      }

      if (_txCharacteristicId == null || _rxCharacteristicId == null) {
        throw Exception('未找到目标特征');
      }

      _connectedDevice = BleDevice(deviceId: deviceId, name: null);
      _connectionStateController.add(true);

      // 监听连接状态
      _connectionStateSubscription = UniversalBle.onConnectionChange.listen((event) {
        if (event.deviceId == deviceId && !event.isConnected) {
          _handleDisconnection();
        }
      });
    } catch (e) {
      await disconnect();
      rethrow;
    }
  }

  /// 处理断开连接
  void _handleDisconnection() {
    _connectedDevice = null;
    _txCharacteristicId = null;
    _rxCharacteristicId = null;
    _connectionStateController.add(false);
    _characteristicSubscription?.cancel();
    _connectionStateSubscription?.cancel();
  }

  /// 断开连接
  @override
  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      try {
        await UniversalBle.disconnect(_connectedDevice!.deviceId);
      } catch (e) {
        // 忽略断开连接错误
      }
      _handleDisconnection();
    }
  }

  /// 发送数据
  ///
  /// 参数:
  /// - [data]: 要发送的数据
  @override
  Future<void> write(List<int> data) async {
    if (_connectedDevice == null || _txCharacteristicId == null) {
      throw Exception('设备未连接');
    }

    try {
      await UniversalBle.writeValue(
        _connectedDevice!.deviceId,
        serviceUuid,
        _txCharacteristicId!,
        data,
        BleOutputProperty.withResponse,
      );
    } catch (e) {
      throw Exception('发送数据失败: $e');
    }
  }

  /// 释放资源
  void dispose() {
    _characteristicSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _dataStreamController.close();
    _connectionStateController.close();
  }
}
