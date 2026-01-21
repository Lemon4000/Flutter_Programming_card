/// 参数实体
///
/// 领域层的参数模型
class ParameterEntity {
  /// 参数键
  final String key;

  /// 参数名称
  final String name;

  /// 参数单位
  final String unit;

  /// 最小值
  final double min;

  /// 最大值
  final double max;

  /// 精度
  final int precision;

  /// 当前值
  final double value;

  const ParameterEntity({
    required this.key,
    required this.name,
    required this.unit,
    required this.min,
    required this.max,
    required this.precision,
    required this.value,
  });

  /// 复制并更新值
  ParameterEntity copyWith({
    String? key,
    String? name,
    String? unit,
    double? min,
    double? max,
    int? precision,
    double? value,
  }) {
    return ParameterEntity(
      key: key ?? this.key,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      min: min ?? this.min,
      max: max ?? this.max,
      precision: precision ?? this.precision,
      value: value ?? this.value,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ParameterEntity &&
        other.key == key &&
        other.name == name &&
        other.unit == unit &&
        other.min == min &&
        other.max == max &&
        other.precision == precision &&
        other.value == value;
  }

  @override
  int get hashCode {
    return Object.hash(key, name, unit, min, max, precision, value);
  }

  @override
  String toString() {
    return 'ParameterEntity(key: $key, name: $name, value: $value)';
  }
}

/// 参数组实体
///
/// 领域层的参数组模型
class ParameterGroupEntity {
  /// 组名
  final String group;

  /// 显示名称
  final String displayName;

  /// 参数列表
  final List<ParameterEntity> parameters;

  const ParameterGroupEntity({
    required this.group,
    required this.displayName,
    required this.parameters,
  });

  /// 复制并更新参数列表
  ParameterGroupEntity copyWith({
    String? group,
    String? displayName,
    List<ParameterEntity>? parameters,
  }) {
    return ParameterGroupEntity(
      group: group ?? this.group,
      displayName: displayName ?? this.displayName,
      parameters: parameters ?? this.parameters,
    );
  }

  /// 根据键查找参数
  ParameterEntity? findParameter(String key) {
    try {
      return parameters.firstWhere((p) => p.key == key);
    } catch (e) {
      return null;
    }
  }

  /// 更新参数值
  ParameterGroupEntity updateParameter(String key, double value) {
    final updatedParameters = parameters.map((p) {
      if (p.key == key) {
        return p.copyWith(value: value);
      }
      return p;
    }).toList();

    return copyWith(parameters: updatedParameters);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ParameterGroupEntity &&
        other.group == group &&
        other.displayName == displayName &&
        _listEquals(other.parameters, parameters);
  }

  @override
  int get hashCode {
    return Object.hash(group, displayName, Object.hashAll(parameters));
  }

  @override
  String toString() {
    return 'ParameterGroupEntity(group: $group, displayName: $displayName, parameters: ${parameters.length})';
  }

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
