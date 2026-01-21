/// 参数实体
class Parameter {
  final String key;
  final String name;
  final String unit;
  final double min;
  final double max;
  final int precision;
  final double defaultValue;
  double? currentValue;

  Parameter({
    required this.key,
    required this.name,
    required this.unit,
    required this.min,
    required this.max,
    required this.precision,
    required this.defaultValue,
    this.currentValue,
  });

  /// 验证值是否在范围内
  bool isValid(double value) {
    return value >= min && value <= max;
  }

  /// 格式化显示值
  String formatValue(double value) {
    return value.toStringAsFixed(precision);
  }

  Parameter copyWith({
    String? key,
    String? name,
    String? unit,
    double? min,
    double? max,
    int? precision,
    double? defaultValue,
    double? currentValue,
  }) {
    return Parameter(
      key: key ?? this.key,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      min: min ?? this.min,
      max: max ?? this.max,
      precision: precision ?? this.precision,
      defaultValue: defaultValue ?? this.defaultValue,
      currentValue: currentValue ?? this.currentValue,
    );
  }

  /// 使用新值创建副本
  Parameter withValue(double value) {
    return copyWith(currentValue: value);
  }
}
