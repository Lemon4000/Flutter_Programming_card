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

  // 目标服务和特征 UUID（支持多种常见的蓝牙串口服务）
  static const List<String> serviceUuids = [
    '0000ffe0-0000-1000-8000-00805f9b34fb', // 常见的蓝牙串口服务 UUID
    '0000fff0-0000-1000-8000-00805f9b34fb', // 另一种常见的蓝牙串口服务 UUID
  ];
  static const List<String> characteristicUuids = [
    '0000ffe1-0000-1000-8000-00805f9b34fb',
    '0000fff1-0000-1000-8000-00805f9b34fb',
    '0000fff2-0000-1000-8000-00805f9b34fb',
  ];

  /// 判断是否使用 universal_ble（Windows 平台）
  bool get _useUniversalBle => !kIsWeb && Platform.isWindows;

  /// 数据接收流
  Stream<List<int>> get dataStream => _dataStreamController.stream;

  /// 连接状态流
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  /// 是否已连接
  bool get isConnected => _fbpConnectedDevice != null || _ubleConnectedDeviceId != null;

  /// 已连接设备的 ID
  String? get connectedDeviceId {
    if (_ubleConnectedDeviceId != null) {
      return _ubleConnectedDeviceId;
    }
    if (_fbpConnectedDevice != null) {
      return _fbpConnectedDevice!.remoteId.toString();
    }
    return null;
  }

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
    try {
      FlutterBluePlus.setLogLevel(LogLevel.none);

      // 检查蓝牙是否支持
      final isSupported = await FlutterBluePlus.isSupported;
      if (!isSupported) {
        throw Exception('设备不支持蓝牙');
      }

      // 检查蓝牙是否开启
      try {
        final adapterState = await FlutterBluePlus.adapterState.first.timeout(
          const Duration(seconds: 2),
        );
        if (adapterState != BluetoothAdapterState.on) {
          throw Exception('蓝牙未开启');
        }
      } catch (e) {
        if (e.toString().contains('Bad state')) {
          throw Exception('无法获取蓝牙状态，请确保蓝牙已开启');
        }
        rethrow;
      }

      // 检查当前是否正在扫描
      try {
        final isScanning = await FlutterBluePlus.isScanning.first.timeout(
          const Duration(seconds: 2),
        );
        if (isScanning) {
          await FlutterBluePlus.stopScan();
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } catch (e) {
        // 忽略检查扫描状态的错误
      }

      final scanResults = <DeviceIdentifier, ScanResult>{};

      final subscription = FlutterBluePlus.scanResults.listen((results) {
        for (final result in results) {
          scanResults[result.device.remoteId] = result;
        }
      });

      await FlutterBluePlus.startScan(
        timeout: timeout,
        androidUsesFineLocation: true,
      );
      await Future.delayed(timeout);
      await subscription.cancel();

      yield scanResults.values.toList();
    } catch (e) {
      throw Exception('蓝牙扫描失败: $e');
    }
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

      // 收集所有服务 UUID 用于调试
      final discoveredServiceUuids = services.map((s) => s.uuid.toLowerCase()).toList();
      
      // 查找目标服务和特征
      bool foundService = false;
      for (final service in services) {
        final serviceUuidLower = service.uuid.toLowerCase();
        
        // 检查是否匹配任何支持的服务 UUID
        final isTargetService = serviceUuids.any((targetUuid) {
          final targetLower = targetUuid.toLowerCase();
          return serviceUuidLower == targetLower || 
                 serviceUuidLower.contains(targetLower.substring(4, 8)); // 提取短格式如 "ffe0" 或 "fff0"
        });
        
        if (isTargetService) {
          foundService = true;
          _ubleServiceUuid = service.uuid;

          final characteristics = service.characteristics;

          if (characteristics.isEmpty) {
            throw Exception('目标服务没有特征');
          }

          for (final characteristic in characteristics) {
            final charUuid = characteristic.uuid.toLowerCase();

            // 检查是否匹配任何支持的特征 UUID
            final isTargetCharacteristic = characteristicUuids.any((targetUuid) {
              final targetLower = targetUuid.toLowerCase();
              return charUuid == targetLower || 
                     charUuid.contains(targetLower.substring(4, 8)); // 提取短格式
            });

            if (isTargetCharacteristic) {
              // 根据特征属性分配 TX 和 RX
              final properties = characteristic.properties;
              
              // 检查是否支持写入
              final supportsWrite = properties.contains(uble.CharacteristicProperty.write) ||
                                   properties.contains(uble.CharacteristicProperty.writeWithoutResponse);
              
              // 检查是否支持通知
              final supportsNotify = properties.contains(uble.CharacteristicProperty.notify) ||
                                    properties.contains(uble.CharacteristicProperty.indicate);
              
              // 如果支持写入，用作 TX（发送）
              if (supportsWrite) {
                _ubleTxCharacteristicUuid = characteristic.uuid;
              }
              
              // 如果支持通知或指示，用作 RX（接收）
              if (supportsNotify) {
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
          }
          break; // 找到目标服务后退出循环
        }
      }

      if (!foundService) {
        // 显示设备实际支持的服务
        final supportedServices = discoveredServiceUuids.join(', ');
        throw Exception('设备不支持目标服务\n'
            '需要: FFE0 或 FFF0\n'
            '设备支持: $supportedServices');
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
      print('🔵 [CrossPlatform] 开始连接设备: $deviceId');
      final device = BluetoothDevice(remoteId: DeviceIdentifier(deviceId));

      print('🔵 [CrossPlatform] 正在连接...');

      // 尝试连接，捕获 "Bad state" 错误并重试
      int retryCount = 0;
      const maxRetries = 3;
      bool connected = false;

      while (!connected && retryCount < maxRetries) {
        try {
          await device.connect(timeout: const Duration(seconds: 15));
          connected = true;
          print('🔵 [CrossPlatform] 连接成功！');
        } catch (e) {
          retryCount++;
          if (e.toString().contains('Bad state')) {
            print('⚠️ [CrossPlatform] 连接遇到 Bad state 错误，重试 $retryCount/$maxRetries');
            if (retryCount < maxRetries) {
              await Future.delayed(Duration(milliseconds: 500 * retryCount));
              continue;
            }
          }
          rethrow;
        }
      }

      if (!connected) {
        throw Exception('连接失败：已重试 $maxRetries 次');
      }

      print('🔵 [CrossPlatform] 开始发现服务...');

      final services = await device.discoverServices();
      print('🔵 [CrossPlatform] 发现 ${services.length} 个服务');

      for (final service in services) {
        final serviceUuidStr = service.uuid.toString().toLowerCase();
        print('🔵 [CrossPlatform] 检查服务: $serviceUuidStr');

        // 检查是否匹配任何支持的服务 UUID
        final isTargetService = serviceUuids.any((targetUuid) {
          final targetLower = targetUuid.toLowerCase();
          return serviceUuidStr == targetLower ||
                 serviceUuidStr.contains(targetLower.substring(4, 8));
        });

        if (isTargetService) {
          print('🔵 [CrossPlatform] 找到目标服务: $serviceUuidStr');
          for (final characteristic in service.characteristics) {
            final charUuid = characteristic.uuid.toString().toLowerCase();
            print('🔵 [CrossPlatform] 检查特征: $charUuid');

            // 检查是否匹配任何支持的特征 UUID
            final isTargetCharacteristic = characteristicUuids.any((targetUuid) {
              final targetLower = targetUuid.toLowerCase();
              return charUuid == targetLower ||
                     charUuid.contains(targetLower.substring(4, 8));
            });

            if (isTargetCharacteristic) {
              print('🔵 [CrossPlatform] 找到目标特征: $charUuid');
              // 根据特征属性分配 TX 和 RX
              final properties = characteristic.properties;

              // 如果支持写入，用作 TX（发送）
              if (properties.write || properties.writeWithoutResponse) {
                _fbpTxCharacteristic = characteristic;
                print('🔵 [CrossPlatform] 设置 TX 特征: $charUuid');
              }

              // 如果支持通知或指示，用作 RX（接收）
              if (properties.notify || properties.indicate) {
                _fbpRxCharacteristic = characteristic;
                print('🔵 [CrossPlatform] 设置 RX 特征: $charUuid');
                await characteristic.setNotifyValue(true);

                _characteristicSubscription = characteristic.lastValueStream.listen((value) {
                  _dataStreamController.add(value);
                });
              }
            }
          }
        }
      }

      if (_fbpTxCharacteristic == null || _fbpRxCharacteristic == null) {
        print('❌ [CrossPlatform] 未找到目标特征 - TX: ${_fbpTxCharacteristic != null}, RX: ${_fbpRxCharacteristic != null}');
        throw Exception('未找到目标特征');
      }

      print('✅ [CrossPlatform] 连接成功！');
      _fbpConnectedDevice = device;
      _connectionStateController.add(true);

      // 连接成功后才开始监听连接状态变化
      _connectionStateSubscription?.cancel();
      _connectionStateSubscription = device.connectionState.listen((state) {
        print('🔵 [CrossPlatform] 连接状态变化: $state');
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnection();
        }
      });
    } catch (e) {
      print('❌ [CrossPlatform] 连接失败: $e');
      print('❌ [CrossPlatform] 错误类型: ${e.runtimeType}');
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
