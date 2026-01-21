/// 应用常量定义
class AppConstants {
  // 私有构造函数，防止实例化
  AppConstants._();

  // ==================== UI 常量 ====================

  /// 标准圆角半径
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusXLarge = 20.0;

  /// 标准间距
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 12.0;
  static const double spacingLarge = 16.0;
  static const double spacingXLarge = 20.0;
  static const double spacingXXLarge = 24.0;

  /// 标准内边距
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 12.0;
  static const double paddingLarge = 16.0;
  static const double paddingXLarge = 20.0;

  /// 按钮高度
  static const double buttonHeightSmall = 40.0;
  static const double buttonHeightMedium = 48.0;
  static const double buttonHeightLarge = 56.0;

  /// 图标大小
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 20.0;
  static const double iconSizeLarge = 24.0;
  static const double iconSizeXLarge = 32.0;

  /// 阴影模糊半径
  static const double shadowBlurLight = 4.0;
  static const double shadowBlurMedium = 8.0;
  static const double shadowBlurHeavy = 16.0;

  // ==================== 动画常量 ====================

  /// 动画持续时间（毫秒）
  static const int animationDurationFast = 150;
  static const int animationDurationNormal = 300;
  static const int animationDurationSlow = 500;

  // ==================== 业务常量 ====================

  /// 蓝牙扫描超时时间（秒）
  static const int bluetoothScanTimeout = 30;

  /// 连接超时时间（秒）
  static const int connectionTimeout = 10;

  /// 最大重试次数
  static const int maxRetryCount = 3;

  // ==================== 颜色常量 ====================

  /// 主题色
  static const int primaryColorValue = 0xFF2196F3;

  /// 成功色
  static const int successColorValue = 0xFF4CAF50;

  /// 警告色
  static const int warningColorValue = 0xFFFF9800;

  /// 错误色
  static const int errorColorValue = 0xFFF44336;
}
