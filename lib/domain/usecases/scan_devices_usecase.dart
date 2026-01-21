import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/device.dart';
import '../repositories/device_repository.dart';

/// 扫描设备用例
class ScanDevicesUseCase {
  final DeviceRepository _repository;

  ScanDevicesUseCase(this._repository);

  /// 执行扫描
  ///
  /// 参数:
  /// - [timeout]: 扫描超时时间
  ///
  /// 返回:
  /// - 设备列表流
  Stream<Either<Failure, List<Device>>> call({
    Duration timeout = const Duration(seconds: 10),
  }) {
    return _repository.scanDevices(timeout: timeout);
  }

  /// 停止扫描
  Future<Either<Failure, void>> stop() {
    return _repository.stopScan();
  }
}
