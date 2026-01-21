import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../data/models/flash_progress.dart';
import '../repositories/communication_repository.dart';

/// 烧录固件用例
class FlashFirmwareUseCase {
  final CommunicationRepository _repository;

  FlashFirmwareUseCase(this._repository);

  /// 烧录固件到设备
  ///
  /// 参数:
  /// - [hexFilePath]: HEX文件路径
  /// - [onProgress]: 进度回调函数，传递完整的FlashProgress对象
  /// - [initTimeout]: 初始化超时时间（毫秒）
  /// - [initMaxRetries]: 初始化最大重试次数
  /// - [programRetryDelay]: 编程阶段重试延迟（毫秒）
  ///
  /// 返回:
  /// - 烧录是否成功
  Future<Either<Failure, bool>> call(
    String hexFilePath, {
    void Function(FlashProgress progress)? onProgress,
    int? initTimeout,
    int? initMaxRetries,
    int? programRetryDelay,
  }) async {
    // 验证文件扩展名
    if (!hexFilePath.toLowerCase().endsWith('.hex')) {
      return const Left(FileFailure('文件格式错误，必须是.hex文件'));
    }

    // 对于非 assets 文件，验证文件存在
    if (!hexFilePath.startsWith('assets/')) {
      final file = File(hexFilePath);
      if (!await file.exists()) {
        return const Left(FileFailure('HEX文件不存在'));
      }
    }

    // 执行烧录
    return _repository.flashFirmware(
      hexFilePath,
      onProgress: onProgress,
      initTimeout: initTimeout,
      initMaxRetries: initMaxRetries,
      programRetryDelay: programRetryDelay,
    );
  }

  /// 获取通信日志流
  Stream<String> get logStream => _repository.logStream;
}
