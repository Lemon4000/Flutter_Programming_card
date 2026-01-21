import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../data/protocol/protocol_config.dart';
import '../entities/parameter_group.dart';

abstract class ConfigRepository {
  /// 加载协议配置
  Future<Either<Failure, ProtocolConfig>> loadProtocolConfig();

  /// 加载参数组配置
  Future<Either<Failure, ParameterGroup>> loadParameterGroup(String groupId);

  /// 列出可用的参数组
  Future<Either<Failure, List<String>>> listAvailableGroups();
}
