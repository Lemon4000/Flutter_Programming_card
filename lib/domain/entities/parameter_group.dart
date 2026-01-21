import 'parameter.dart';

/// 参数组实体
class ParameterGroup {
  final String name;
  final String groupId;
  final List<Parameter> parameters;

  ParameterGroup({
    required this.name,
    required this.groupId,
    required this.parameters,
  });

  /// 从JSON创建
  factory ParameterGroup.fromJson(Map<String, dynamic> json) {
    return ParameterGroup(
      name: json['name'] as String,
      groupId: json['groupId'] as String,
      parameters: (json['parameters'] as List)
          .map((p) => Parameter(
                key: p['key'] as String,
                name: p['name'] as String,
                unit: p['unit'] as String,
                min: (p['min'] as num).toDouble(),
                max: (p['max'] as num).toDouble(),
                precision: p['precision'] as int,
                defaultValue: (p['default'] as num).toDouble(),
              ))
          .toList(),
    );
  }

  /// 获取所有参数的键值对
  Map<String, double> getValues() {
    final values = <String, double>{};
    for (var param in parameters) {
      if (param.currentValue != null) {
        values[param.key] = param.currentValue!;
      }
    }
    return values;
  }

  /// 获取精度映射
  Map<String, int> getPrecisionMap() {
    final map = <String, int>{};
    for (var param in parameters) {
      map[param.key] = param.precision;
    }
    return map;
  }

  /// 创建副本
  ParameterGroup copyWith({
    String? name,
    String? groupId,
    List<Parameter>? parameters,
  }) {
    return ParameterGroup(
      name: name ?? this.name,
      groupId: groupId ?? this.groupId,
      parameters: parameters ?? this.parameters,
    );
  }
}
