import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/device.dart';
import '../repositories/device_repository.dart';

/// 连接设备用例
class ConnectDeviceUseCase {
  final DeviceRepository _repository;

  ConnectDeviceUseCase(this._repository);

  /// 连接到指定设备
  ///
  /// 参数:
  /// - [deviceId]: 设备ID
  /// - [timeout]: 连接超时时间
  ///
  /// 返回:
  /// - 连接结果
  Future<Either<Failure, void>> call(
    String deviceId, {
    Duration timeout = const Duration(seconds: 15),
  }) {
    return _repository.connect(deviceId, timeout: timeout);
  }

  /// 断开连接
  Future<Either<Failure, void>> disconnect() {
    return _repository.disconnect();
  }

  /// 获取连接状态流
  Stream<bool> get connectionStateStream {
    return _repository.connectionStateStream;
  }

  /// 获取当前连接的设备
  Device? get connectedDevice {
    return _repository.connectedDevice;
  }
}
