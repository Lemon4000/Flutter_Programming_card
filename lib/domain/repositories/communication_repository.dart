import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../data/models/flash_progress.dart';
import '../entities/parameter_group_entity.dart';

/// 通信仓库接口
///
/// 定义设备通信相关的操作
abstract class CommunicationRepository {
  /// 读取参数组
  ///
  /// 参数:
  /// - [group]: 参数组名称
  ///
  /// 返回:
  /// - 参数组实体
  Future<Either<Failure, ParameterGroupEntity>> readParameters(String group);

  /// 写入参数
  ///
  /// 参数:
  /// - [group]: 参数组名称
  /// - [parameters]: 要写入的参数映射
  ///
  /// 返回:
  /// - 写入是否成功
  Future<Either<Failure, bool>> writeParameters(
    String group,
    Map<String, double> parameters,
  );

  /// 烧录固件
  ///
  /// 参数:
  /// - [hexFilePath]: HEX文件路径
  /// - [onProgress]: 进度回调
  /// - [initTimeout]: 初始化超时时间（毫秒）
  /// - [initMaxRetries]: 初始化最大重试次数
  /// - [programRetryDelay]: 编程阶段重试延迟（毫秒）
  ///
  /// 返回:
  /// - 烧录是否成功
  Future<Either<Failure, bool>> flashFirmware(
    String hexFilePath, {
    void Function(FlashProgress progress)? onProgress,
    int? initTimeout,
    int? initMaxRetries,
    int? programRetryDelay,
  });

  /// 停止烧录
  void abortFlashing();

  /// 获取通信日志流
  Stream<String> get logStream;
}
