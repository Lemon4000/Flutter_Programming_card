import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../repositories/communication_repository.dart';

/// 写入参数用例
class WriteParametersUseCase {
  final CommunicationRepository _repository;

  WriteParametersUseCase(this._repository);

  /// 写入参数到设备
  ///
  /// 参数:
  /// - [group]: 参数组名称
  /// - [parameters]: 要写入的参数键值对
  ///
  /// 返回:
  /// - 写入是否成功
  Future<Either<Failure, bool>> call(
    String group,
    Map<String, double> parameters,
  ) async {
    // 验证参数
    if (parameters.isEmpty) {
      return const Left(ProtocolFailure('参数列表为空'));
    }

    // 写入参数
    return _repository.writeParameters(group, parameters);
  }
}
