import 'dart:async';
import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/device.dart';
import '../../domain/repositories/device_repository.dart';
import '../datasources/bluetooth_datasource.dart';
import '../datasources/cross_platform_bluetooth_datasource.dart';
import '../models/device_info.dart';

/// 设备仓库实现
class DeviceRepositoryImpl implements DeviceRepository {
  final BluetoothDatasource? _bluetoothDatasource;
  final CrossPlatformBluetoothDatasource? _crossPlatformBluetoothDatasource;
  final Map<String, BluetoothDevice> _scannedDevices = {};

  // 缓存设备名称，避免名称丢失
  final Map<String, String> _deviceNameCache = {};

  // SharedPreferences 键
  static const String _deviceNameCacheKey = 'device_name_cache';

  // 是否已加载缓存
  bool _cacheLoaded = false;

  DeviceRepositoryImpl.bluetooth(this._bluetoothDatasource)
      : _crossPlatformBluetoothDatasource = null {
    _loadDeviceNameCache();
  }

  DeviceRepositoryImpl.crossPlatform(this._crossPlatformBluetoothDatasource)
      : _bluetoothDatasource = null {
    _loadDeviceNameCache();
  }

  /// 获取当前使用的数据源（用于空安全检查）
  dynamic get _currentDatasource => _crossPlatformBluetoothDatasource ?? _bluetoothDatasource;
  
  /// 从持久化存储加载设备名称缓存
  Future<void> _loadDeviceNameCache() async {
    if (_cacheLoaded) {
      print('缓存已加载，跳过');
      return;
    }
    
    print('开始加载设备名称缓存...');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      print('SharedPreferences 实例获取成功');
      
      final cacheJson = prefs.getString(_deviceNameCacheKey);
      print('缓存JSON: $cacheJson');
      
      if (cacheJson != null) {
        final Map<String, dynamic> cacheMap = json.decode(cacheJson);
        print('解析缓存成功，包含 ${cacheMap.length} 个条目');
        
        _deviceNameCache.clear();
        cacheMap.forEach((key, value) {
          if (value is String) {
            _deviceNameCache[key] = value;
            print('  加载: $key -> $value');
          }
        });
        print('已加载设备名称缓存: ${_deviceNameCache.length} 个设备');
      } else {
        print('缓存为空，这是首次运行');
      }
      
      _cacheLoaded = true;
    } catch (e) {
      print('加载设备名称缓存失败: $e');
      print('错误堆栈: ${StackTrace.current}');
      _cacheLoaded = true;
    }
  }
  
  /// 保存设备名称缓存到持久化存储
  Future<void> _saveDeviceNameCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = json.encode(_deviceNameCache);
      await prefs.setString(_deviceNameCacheKey, cacheJson);
      print('已保存设备名称缓存: ${_deviceNameCache.length} 个设备');
    } catch (e) {
      print('保存设备名称缓存失败: $e');
    }
  }

  @override
  Stream<Either<Failure, List<Device>>> scanDevices({
    Duration timeout = const Duration(seconds: 10),
  }) async* {
    // 确保缓存已加载
    if (!_cacheLoaded) {
      await _loadDeviceNameCache();
    }

    print('开始扫描，当前缓存中有 ${_deviceNameCache.length} 个设备名称');
    if (_deviceNameCache.isNotEmpty) {
      print('缓存内容: $_deviceNameCache');
    }

    try {
      bool cacheUpdated = false;

      // 选择数据源
      final scanStream = _crossPlatformBluetoothDatasource != null
          ? _crossPlatformBluetoothDatasource!.scanDevices(timeout: timeout)
          : _bluetoothDatasource!.scanDevices(timeout: timeout);

      await for (final scanResults in scanStream) {
        // 缓存扫描到的设备
        for (final result in scanResults) {
          _scannedDevices[result.device.remoteId.toString().toLowerCase()] = result.device; // 统一转换为小写
        }

        // 获取已配对设备的名称映射（仅 flutter_blue_plus 支持）
        final bondedNames = _bluetoothDatasource?.bondedDeviceNames ?? {};

        // 转换为领域实体
        final devices = scanResults
            .map((result) {
              final deviceInfo = DeviceInfo.fromScanResult(result);
              final deviceId = deviceInfo.id;
              
              // 获取设备名称，优先级：
              // 1. 当前扫描结果中的名称（如果不是"未知设备"）
              // 2. 缓存中的名称
              // 3. 已配对设备的名称
              // 4. "未知设备"
              String finalName = deviceInfo.name;
              
              // 调试：打印当前状态
              print('设备 $deviceId: 扫描名称=$finalName, 缓存=${_deviceNameCache[deviceId]}');
              
              // 如果当前扫描到了有效名称，更新缓存
              if (finalName != '未知设备') {
                if (_deviceNameCache[deviceId] != finalName) {
                  print('更新缓存: $deviceId -> $finalName');
                  _deviceNameCache[deviceId] = finalName;
                  cacheUpdated = true;
                }
              }
              // 如果当前名称是"未知设备"，尝试从缓存获取
              else if (_deviceNameCache.containsKey(deviceId)) {
                finalName = _deviceNameCache[deviceId]!;
                print('从缓存恢复名称: $deviceId -> $finalName');
              }
              // 如果缓存中也没有，尝试从已配对设备获取
              else if (bondedNames.containsKey(deviceId)) {
                finalName = bondedNames[deviceId]!;
                print('从已配对设备获取名称: $deviceId -> $finalName');
                _deviceNameCache[deviceId] = finalName; // 同时更新缓存
                cacheUpdated = true;
              }
              else {
                print('设备 $deviceId 无可用名称，显示为未知设备');
              }
              
              return Device(
                id: deviceId,
                name: finalName,
                rssi: deviceInfo.rssi,
                isConnected: deviceInfo.isConnected,
              );
            })
            // 过滤掉未知设备，只显示有名称的设备
            .where((device) => device.name != '未知设备')
            .toList();

        // 按信号强度排序（从强到弱）
        devices.sort((a, b) => b.rssi.compareTo(a.rssi));

        yield Right(devices);
        
        // 如果缓存有更新，保存到持久化存储
        if (cacheUpdated) {
          _saveDeviceNameCache();
        }
      }
    } catch (e) {
      yield Left(DeviceFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> stopScan() async {
    try {
      if (_crossPlatformBluetoothDatasource != null) {
        await _crossPlatformBluetoothDatasource!.stopScan();
      } else if (_bluetoothDatasource != null) {
        await _bluetoothDatasource!.stopScan();
      }
      return const Right(null);
    } catch (e) {
      return Left(DeviceFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> connect(
    String deviceId, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      // 检查是否已连接到该设备
      final currentDevice = _bluetoothDatasource?.connectedDevice;
      if (currentDevice != null &&
          currentDevice.remoteId.toString().toLowerCase() == deviceId.toLowerCase()) { // 统一转换为小写比较
        return const Right(null);
      }

      // 从缓存中获取设备
      final device = _scannedDevices[deviceId];
      if (device == null) {
        return const Left(DeviceFailure('设备未找到，请先扫描'));
      }

      // 连接设备
      await _bluetoothDatasource!.connect(device, timeout: timeout);
      return const Right(null);
    } catch (e) {
      return Left(ConnectionFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> disconnect() async {
    try {
      await _bluetoothDatasource!.disconnect();
      return const Right(null);
    } catch (e) {
      return Left(ConnectionFailure(e.toString()));
    }
  }

  @override
  Stream<bool> get connectionStateStream {
    return _bluetoothDatasource!.connectionStateStream.map(
      (state) => state == BluetoothConnectionState.connected,
    );
  }

  @override
  Device? get connectedDevice {
    final device = _bluetoothDatasource?.connectedDevice;
    if (device == null) return null;

    return Device(
      id: device.remoteId.toString().toLowerCase(), // 统一转换为小写
      name: device.platformName.isEmpty ? '未知设备' : device.platformName,
      rssi: 0,
      isConnected: true,
    );
  }
}
