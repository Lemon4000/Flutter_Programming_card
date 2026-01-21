import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/parameter_group.dart';
import '../../domain/repositories/config_repository.dart';
import '../protocol/protocol_config.dart';

class ConfigRepositoryImpl implements ConfigRepository {
  @override
  Future<Either<Failure, ProtocolConfig>> loadProtocolConfig() async {
    try {
      final jsonString = await rootBundle.loadString('assets/config/protocol.json');
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // 使用 fromJson 方法来解析配置，确保字段名称一致
      return Right(ProtocolConfig.fromJson(json));
    } catch (e) {
      return Left(ConfigFailure('加载协议配置失败: $e'));
    }
  }

  @override
  Future<Either<Failure, ParameterGroup>> loadParameterGroup(String groupId) async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/config/groups/group_${groupId.toLowerCase()}.json'
      );
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      
      return Right(ParameterGroup.fromJson(json));
    } catch (e) {
      return Left(ConfigFailure('加载参数组配置失败: $e'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> listAvailableGroups() async {
    // 简化版本，返回固定的组列表
    // 实际应用中可以通过读取assets目录来动态获取
    return const Right(['A']);
  }
}
