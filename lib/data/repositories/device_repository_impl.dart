import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/device.dart';
import '../../domain/repositories/device_repository.dart';
import '../datasources/bluetooth_datasource.dart';
import '../models/device_info.dart';

/// 设备仓库实现
class DeviceRepositoryImpl implements DeviceRepository {
  final BluetoothDatasource _bluetoothDatasource;
  final Map<String, BluetoothDevice> _scannedDevices = {};

  DeviceRepositoryImpl(this._bluetoothDatasource);

  @override
  Stream<Either<Failure, List<Device>>> scanDevices({
    Duration timeout = const Duration(seconds: 10),
  }) async* {
    try {
      await for (final scanResults
          in _bluetoothDatasource.scanDevices(timeout: timeout)) {
        // 缓存扫描到的设备
        for (final result in scanResults) {
          _scannedDevices[result.device.remoteId.toString()] = result.device;
        }

        // 获取已配对设备的名称映射
        final bondedNames = _bluetoothDatasource.bondedDeviceNames;

        // 转换为领域实体
        final devices = scanResults
            .map((result) {
              final deviceInfo = DeviceInfo.fromScanResult(result);
              // 如果设备名称为空，尝试从已配对设备中获取
              String finalName = deviceInfo.name;
              if (finalName == '未知设备' && bondedNames.containsKey(deviceInfo.id)) {
                finalName = bondedNames[deviceInfo.id]!;
              }
              return Device(
                id: deviceInfo.id,
                name: finalName,
                rssi: deviceInfo.rssi,
                isConnected: deviceInfo.isConnected,
              );
            })
            .toList();

        // 按信号强度排序（从强到弱）
        devices.sort((a, b) => b.rssi.compareTo(a.rssi));

        yield Right(devices);
      }
    } catch (e) {
      yield Left(DeviceFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> stopScan() async {
    try {
      await _bluetoothDatasource.stopScan();
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
      final currentDevice = _bluetoothDatasource.connectedDevice;
      if (currentDevice != null &&
          currentDevice.remoteId.toString() == deviceId) {
        return const Right(null);
      }

      // 从缓存中获取设备
      final device = _scannedDevices[deviceId];
      if (device == null) {
        return const Left(DeviceFailure('设备未找到，请先扫描'));
      }

      // 连接设备
      await _bluetoothDatasource.connect(device, timeout: timeout);
      return const Right(null);
    } catch (e) {
      return Left(ConnectionFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> disconnect() async {
    try {
      await _bluetoothDatasource.disconnect();
      return const Right(null);
    } catch (e) {
      return Left(ConnectionFailure(e.toString()));
    }
  }

  @override
  Stream<bool> get connectionStateStream {
    return _bluetoothDatasource.connectionStateStream.map(
      (state) => state == BluetoothConnectionState.connected,
    );
  }

  @override
  Device? get connectedDevice {
    final device = _bluetoothDatasource.connectedDevice;
    if (device == null) return null;

    return Device(
      id: device.remoteId.toString(),
      name: device.platformName.isEmpty ? '未知设备' : device.platformName,
      rssi: 0,
      isConnected: true,
    );
  }
}
