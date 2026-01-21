import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/device.dart';

/// 设备仓库接口
///
/// 定义设备相关的操作
abstract class DeviceRepository {
  /// 扫描蓝牙设备
  ///
  /// 参数:
  /// - [timeout]: 扫描超时时间
  ///
  /// 返回:
  /// - 设备列表流
  Stream<Either<Failure, List<Device>>> scanDevices({
    Duration timeout = const Duration(seconds: 10),
  });

  /// 停止扫描
  Future<Either<Failure, void>> stopScan();

  /// 连接设备
  ///
  /// 参数:
  /// - [deviceId]: 设备ID
  /// - [timeout]: 连接超时时间
  Future<Either<Failure, void>> connect(
    String deviceId, {
    Duration timeout = const Duration(seconds: 15),
  });

  /// 断开连接
  Future<Either<Failure, void>> disconnect();

  /// 连接状态流
  Stream<bool> get connectionStateStream;

  /// 当前连接的设备
  Device? get connectedDevice;
}
