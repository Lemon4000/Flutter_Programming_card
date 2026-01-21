/// 参数数据模型
///
/// 表示单个参数的配置和当前值
class Parameter {
  /// 参数键（如"A0", "A1"）
  final String key;

  /// 参数名称
  final String name;

  /// 参数单位
  final String unit;

  /// 最小值
  final double min;

  /// 最大值
  final double max;

  /// 精度（小数位数）
  final int precision;

  /// 当前值
  final double value;

  /// 是否已修改
  final bool isModified;

  const Parameter({
    required this.key,
    required this.name,
    required this.unit,
    required this.min,
    required this.max,
    required this.precision,
    required this.value,
    this.isModified = false,
  });

  /// 从JSON创建参数
  factory Parameter.fromJson(Map<String, dynamic> json) {
    return Parameter(
      key: json['key'] as String,
      name: json['name'] as String,
      unit: json['unit'] as String? ?? '',
      min: (json['min'] as num).toDouble(),
      max: (json['max'] as num).toDouble(),
      precision: json['precision'] as int? ?? 2,
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      isModified: json['isModified'] as bool? ?? false,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'name': name,
      'unit': unit,
      'min': min,
      'max': max,
      'precision': precision,
      'value': value,
      'isModified': isModified,
    };
  }

  /// 复制并更新值
  Parameter copyWith({
    String? key,
    String? name,
    String? unit,
    double? min,
    double? max,
    int? precision,
    double? value,
    bool? isModified,
  }) {
    return Parameter(
      key: key ?? this.key,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      min: min ?? this.min,
      max: max ?? this.max,
      precision: precision ?? this.precision,
      value: value ?? this.value,
      isModified: isModified ?? this.isModified,
    );
  }

  /// 验证值是否在有效范围内
  bool isValueValid(double testValue) {
    return testValue >= min && testValue <= max;
  }

  /// 格式化值为字符串
  String formatValue() {
    return value.toStringAsFixed(precision);
  }

  /// 格式化值并添加单位
  String formatValueWithUnit() {
    final formattedValue = formatValue();
    return unit.isEmpty ? formattedValue : '$formattedValue $unit';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Parameter &&
        other.key == key &&
        other.name == name &&
        other.unit == unit &&
        other.min == min &&
        other.max == max &&
        other.precision == precision &&
        other.value == value &&
        other.isModified == isModified;
  }

  @override
  int get hashCode {
    return Object.hash(
      key,
      name,
      unit,
      min,
      max,
      precision,
      value,
      isModified,
    );
  }

  @override
  String toString() {
    return 'Parameter(key: $key, name: $name, value: $value, unit: $unit, isModified: $isModified)';
  }
}

/// 参数组模型
///
/// 表示一组相关的参数
class ParameterGroup {
  /// 组名（如"A", "B"）
  final String group;

  /// 组显示名称
  final String displayName;

  /// 参数列表
  final List<Parameter> parameters;

  const ParameterGroup({
    required this.group,
    required this.displayName,
    required this.parameters,
  });

  /// 从JSON创建参数组
  factory ParameterGroup.fromJson(Map<String, dynamic> json) {
    final parametersJson = json['parameters'] as List<dynamic>;
    final parameters = parametersJson
        .map((p) => Parameter.fromJson(p as Map<String, dynamic>))
        .toList();

    return ParameterGroup(
      group: json['group'] as String,
      displayName: json['displayName'] as String,
      parameters: parameters,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'group': group,
      'displayName': displayName,
      'parameters': parameters.map((p) => p.toJson()).toList(),
    };
  }

  /// 复制并更新参数列表
  ParameterGroup copyWith({
    String? group,
    String? displayName,
    List<Parameter>? parameters,
  }) {
    return ParameterGroup(
      group: group ?? this.group,
      displayName: displayName ?? this.displayName,
      parameters: parameters ?? this.parameters,
    );
  }

  /// 根据键查找参数
  Parameter? findParameter(String key) {
    try {
      return parameters.firstWhere((p) => p.key == key);
    } catch (e) {
      return null;
    }
  }

  /// 更新参数值
  ParameterGroup updateParameter(String key, double value) {
    final updatedParameters = parameters.map((p) {
      if (p.key == key) {
        return p.copyWith(value: value, isModified: true);
      }
      return p;
    }).toList();

    return copyWith(parameters: updatedParameters);
  }

  /// 重置所有修改标记
  ParameterGroup resetModified() {
    final resetParameters = parameters.map((p) {
      return p.copyWith(isModified: false);
    }).toList();

    return copyWith(parameters: resetParameters);
  }

  /// 获取所有已修改的参数
  List<Parameter> getModifiedParameters() {
    return parameters.where((p) => p.isModified).toList();
  }

  /// 检查是否有修改
  bool get hasModifications {
    return parameters.any((p) => p.isModified);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ParameterGroup &&
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
    return 'ParameterGroup(group: $group, displayName: $displayName, parameters: ${parameters.length})';
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
