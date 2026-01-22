import 'dart:async';
import 'dart:io' show Platform;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:universal_ble/universal_ble.dart' as uble;

/// 跨平台蓝牙数据源
///
/// 在 Windows 上使用 universal_ble，其他平台使用 flutter_blue_plus
class CrossPlatformBluetoothDatasource {
  // flutter_blue_plus 相关
  BluetoothDevice? _fbpConnectedDevice;
  BluetoothCharacteristic? _fbpTxCharacteristic;
  BluetoothCharacteristic? _fbpRxCharacteristic;

  // universal_ble 相关
  String? _ubleConnectedDeviceId;
  String? _ubleTxCharacteristicUuid;
  String? _ubleRxCharacteristicUuid;
  String? _ubleServiceUuid;

  final _dataStreamController = StreamController<List<int>>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();
  StreamSubscription? _connectionStateSubscription;
  StreamSubscription? _characteristicSubscription;

  bool _isScanning = false;

  // 目标服务和特征 UUID
  static const String serviceUuid = '0000ffe0-0000-1000-8000-00805f9b34fb';
  static const String txCharacteristicUuid = '0000ffe1-0000-1000-8000-00805f9b34fb';
  static const String rxCharacteristicUuid = '0000ffe1-0000-1000-8000-00805f9b34fb';

  /// 判断是否使用 universal_ble（Windows 平台）
  bool get _useUniversalBle => !kIsWeb && Platform.isWindows;

  /// 数据接收流
  Stream<List<int>> get dataStream => _dataStreamController.stream;

  /// 连接状态流
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  /// 是否已连接
  bool get isConnected => _fbpConnectedDevice != null || _ubleConnectedDeviceId != null;

  /// 扫描蓝牙设备
  Stream<List<ScanResult>> scanDevices({
    Duration timeout = const Duration(seconds: 10),
  }) async* {
    if (_isScanning) {
      return;
    }

    _isScanning = true;

    try {
      if (_useUniversalBle) {
        // Windows: 使用 universal_ble
        yield* _scanWithUniversalBle(timeout);
      } else {
        // 其他平台: 使用 flutter_blue_plus
        yield* _scanWithFlutterBluePlus(timeout);
      }
    } finally {
      _isScanning = false;
    }
  }

  /// 使用 universal_ble 扫描
  Stream<List<ScanResult>> _scanWithUniversalBle(Duration timeout) async* {
    final devices = <String, uble.BleDevice>{};

    try {
      await uble.UniversalBle.startScan();

      final scanSubscription = uble.UniversalBle.scanStream.listen((device) {
        if (device.name != null && device.name!.isNotEmpty) {
          devices[device.deviceId] = device;
        }
      });

      await Future.delayed(timeout);
      await scanSubscription.cancel();
      await uble.UniversalBle.stopScan();

      // 转换为 ScanResult 格式
      final scanResults = devices.values.map((device) {
        return ScanResult(
          device: BluetoothDevice(remoteId: DeviceIdentifier(device.deviceId)),
          advertisementData: AdvertisementData(
            advName: device.name ?? '',
            txPowerLevel: null,
            appearance: null,
            connectable: true,
            manufacturerData: {},
            serviceData: {},
            serviceUuids: [],
          ),
          rssi: device.rssi ?? -100,
          timeStamp: DateTime.now(),
        );
      }).toList();

      yield scanResults;
    } catch (e) {
      throw Exception('扫描失败: $e');
    }
  }

  /// 使用 flutter_blue_plus 扫描
  Stream<List<ScanResult>> _scanWithFlutterBluePlus(Duration timeout) async* {
    FlutterBluePlus.setLogLevel(LogLevel.none);

    final scanResults = <DeviceIdentifier, ScanResult>{};

    final subscription = FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        scanResults[result.device.remoteId] = result;
      }
    });

    await FlutterBluePlus.startScan(timeout: timeout);
    await Future.delayed(timeout);
    await subscription.cancel();

    yield scanResults.values.toList();
  }

  /// 停止扫描
  Future<void> stopScan() async {
    if (_isScanning) {
      if (_useUniversalBle) {
        await uble.UniversalBle.stopScan();
      } else {
        await FlutterBluePlus.stopScan();
      }
      _isScanning = false;
    }
  }

  /// 连接到设备
  Future<void> connect(String deviceId) async {
    if (_useUniversalBle) {
      await _connectWithUniversalBle(deviceId);
    } else {
      await _connectWithFlutterBluePlus(deviceId);
    }
  }

  /// 使用 universal_ble 连接
  Future<void> _connectWithUniversalBle(String deviceId) async {
    try {
      // 连接设备
      await uble.UniversalBle.connect(deviceId);

      // 发现服务
      final services = await uble.UniversalBle.discoverServices(deviceId);

      if (services.isEmpty) {
        throw Exception('设备没有可用的服务');
      }

      // 查找目标服务和特征
      bool foundService = false;
      for (final service in services) {
        if (service.uuid.toLowerCase() == serviceUuid.toLowerCase()) {
          foundService = true;
          _ubleServiceUuid = service.uuid;

          final characteristics = service.characteristics;

          if (characteristics.isEmpty) {
            throw Exception('目标服务没有特征');
          }

          for (final characteristic in characteristics) {
            final charUuid = characteristic.uuid.toLowerCase();

            if (charUuid == txCharacteristicUuid.toLowerCase()) {
              _ubleTxCharacteristicUuid = characteristic.uuid;
            }
            if (charUuid == rxCharacteristicUuid.toLowerCase()) {
              _ubleRxCharacteristicUuid = characteristic.uuid;

              // 订阅通知
              try {
                await uble.UniversalBle.setNotifiable(
                  deviceId,
                  service.uuid,
                  characteristic.uuid,
                  uble.BleInputProperty.notification,
                );
              } catch (e) {
                // 订阅失败不影响连接
              }
            }
          }
          break; // 找到目标服务后退出循环
        }
      }

      if (!foundService) {
        throw Exception('设备不支持目标服务\n需要服务 UUID: 0000FFE0');
      }

      if (_ubleTxCharacteristicUuid == null || _ubleRxCharacteristicUuid == null) {
        throw Exception('设备不支持目标特征\n需要特征 UUID: 0000FFE1');
      }

      _ubleConnectedDeviceId = deviceId;
      _connectionStateController.add(true);
    } catch (e) {
      await disconnect();
      // 提供更友好的错误信息
      if (e.toString().contains('null')) {
        throw Exception('连接失败：设备服务信息不完整\n请确认设备已开机并处于可连接状态');
      }
      rethrow;
    }
  }

  /// 使用 flutter_blue_plus 连接
  Future<void> _connectWithFlutterBluePlus(String deviceId) async {
    try {
      final device = BluetoothDevice(remoteId: DeviceIdentifier(deviceId));
      await device.connect(timeout: const Duration(seconds: 15));

      final services = await device.discoverServices();

      for (final service in services) {
        if (service.uuid.toString().toLowerCase() == serviceUuid.toLowerCase()) {
          for (final characteristic in service.characteristics) {
            final charUuid = characteristic.uuid.toString().toLowerCase();
            if (charUuid == txCharacteristicUuid.toLowerCase()) {
              _fbpTxCharacteristic = characteristic;
            }
            if (charUuid == rxCharacteristicUuid.toLowerCase()) {
              _fbpRxCharacteristic = characteristic;
              await characteristic.setNotifyValue(true);

              _characteristicSubscription = characteristic.lastValueStream.listen((value) {
                _dataStreamController.add(value);
              });
            }
          }
        }
      }

      if (_fbpTxCharacteristic == null || _fbpRxCharacteristic == null) {
        throw Exception('未找到目标特征');
      }

      _fbpConnectedDevice = device;
      _connectionStateController.add(true);

      _connectionStateSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
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
    _fbpConnectedDevice = null;
    _fbpTxCharacteristic = null;
    _fbpRxCharacteristic = null;
    _ubleConnectedDeviceId = null;
    _ubleTxCharacteristicUuid = null;
    _ubleRxCharacteristicUuid = null;
    _ubleServiceUuid = null;
    _connectionStateController.add(false);
    _characteristicSubscription?.cancel();
    _connectionStateSubscription?.cancel();
  }

  /// 断开连接
  Future<void> disconnect() async {
    if (_fbpConnectedDevice != null) {
      try {
        await _fbpConnectedDevice!.disconnect();
      } catch (e) {
        // 忽略错误
      }
    }
    if (_ubleConnectedDeviceId != null) {
      try {
        await uble.UniversalBle.disconnect(_ubleConnectedDeviceId!);
      } catch (e) {
        // 忽略错误
      }
    }
    _handleDisconnection();
  }

  /// 发送数据
  Future<void> write(List<int> data) async {
    if (_fbpConnectedDevice != null && _fbpTxCharacteristic != null) {
      await _fbpTxCharacteristic!.write(data, withoutResponse: false);
    } else if (_ubleConnectedDeviceId != null &&
               _ubleTxCharacteristicUuid != null &&
               _ubleServiceUuid != null) {
      await uble.UniversalBle.writeValue(
        _ubleConnectedDeviceId!,
        _ubleServiceUuid!,
        _ubleTxCharacteristicUuid!,
        Uint8List.fromList(data),
        uble.BleOutputProperty.withResponse,
      );
    } else {
      throw Exception('设备未连接');
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
