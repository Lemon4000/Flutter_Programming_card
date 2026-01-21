import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/parameter_group.dart';
import '../repositories/communication_repository.dart';
import '../repositories/config_repository.dart';

/// 读取参数用例
class ReadParametersUseCase {
  final CommunicationRepository _communicationRepository;
  final ConfigRepository _configRepository;

  ReadParametersUseCase(
    this._communicationRepository,
    this._configRepository,
  );

  /// 读取指定参数组
  ///
  /// 参数:
  /// - [group]: 参数组名称
  ///
  /// 返回:
  /// - 参数组实体，包含从设备读取的实际值
  Future<Either<Failure, ParameterGroup>> call(String group) async {
    // 先从配置加载参数定义
    final configResult = await _configRepository.loadParameterGroup(group);

    return configResult.fold(
      (failure) => Left(failure),
      (config) async {
        // 从设备读取实际值
        final readResult = await _communicationRepository.readParameters(group);

        return readResult.fold(
          (failure) => Left(failure),
          (readData) {
            // 合并配置和读取的数据
            final mergedParameters = config.parameters.map((configParam) {
              // 查找对应的读取值
              final readParam = readData.findParameter(configParam.key);
              if (readParam != null) {
                // 使用读取的值更新配置参数
                return configParam.withValue(readParam.value);
              }
              return configParam;
            }).toList();

            return Right(config.copyWith(parameters: mergedParameters));
          },
        );
      },
    );
  }

  /// 获取可用的参数组列表
  Future<Either<Failure, List<String>>> getAvailableGroups() {
    return _configRepository.listAvailableGroups();
  }
}
