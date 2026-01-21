import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// 应用标准卡片组件
/// 提供统一的卡片样式，包括圆角、阴影、边框等
class AppCard extends StatelessWidget {
  /// 卡片内容
  final Widget child;

  /// 外边距
  final EdgeInsetsGeometry? margin;

  /// 内边距
  final EdgeInsetsGeometry? padding;

  /// 圆角半径
  final double? borderRadius;

  /// 阴影模糊半径
  final double? shadowBlur;

  /// 边框颜色
  final Color? borderColor;

  /// 边框宽度
  final double? borderWidth;

  /// 背景颜色
  final Color? backgroundColor;

  /// 渐变背景
  final Gradient? gradient;

  /// 点击事件
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.borderRadius,
    this.shadowBlur,
    this.borderColor,
    this.borderWidth,
    this.backgroundColor,
    this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? AppConstants.borderRadiusLarge;
    final effectiveShadowBlur = shadowBlur ?? AppConstants.shadowBlurMedium;
    final effectivePadding = padding ?? const EdgeInsets.all(AppConstants.paddingLarge);

    Widget content = Container(
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: backgroundColor,
        gradient: gradient,
        borderRadius: BorderRadius.circular(effectiveBorderRadius),
        border: borderColor != null
            ? Border.all(
                color: borderColor!,
                width: borderWidth ?? 1.0,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: effectiveShadowBlur,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );

    if (margin != null) {
      content = Container(
        margin: margin,
        child: content,
      );
    }

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(effectiveBorderRadius),
        child: content,
      );
    }

    return content;
  }
}

/// 应用标准按钮组件
/// 提供统一的按钮样式
class AppButton extends StatelessWidget {
  /// 按钮文本
  final String text;

  /// 点击事件
  final VoidCallback? onPressed;

  /// 图标
  final IconData? icon;

  /// 按钮类型
  final AppButtonType type;

  /// 是否为全宽按钮
  final bool isFullWidth;

  /// 按钮高度
  final double? height;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.type = AppButtonType.primary,
    this.isFullWidth = false,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = height ?? AppConstants.buttonHeightLarge;

    Color backgroundColor;
    Color foregroundColor = Colors.white;

    switch (type) {
      case AppButtonType.primary:
        backgroundColor = const Color(AppConstants.primaryColorValue);
        break;
      case AppButtonType.success:
        backgroundColor = const Color(AppConstants.successColorValue);
        break;
      case AppButtonType.warning:
        backgroundColor = const Color(AppConstants.warningColorValue);
        break;
      case AppButtonType.danger:
        backgroundColor = const Color(AppConstants.errorColorValue);
        break;
    }

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      minimumSize: isFullWidth ? Size(double.infinity, effectiveHeight) : Size(120, effectiveHeight),
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingXLarge,
        vertical: AppConstants.paddingMedium,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      elevation: 2,
    );

    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: AppConstants.iconSizeMedium),
        label: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: buttonStyle,
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: buttonStyle,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// 按钮类型枚举
enum AppButtonType {
  primary,
  success,
  warning,
  danger,
}

/// 应用加载指示器
/// 提供统一的加载状态显示
class AppLoadingIndicator extends StatelessWidget {
  /// 加载提示文本
  final String? message;

  /// 指示器大小
  final double? size;

  const AppLoadingIndicator({
    super.key,
    this.message,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSize = size ?? 60.0;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: effectiveSize,
            height: effectiveSize,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppConstants.spacingXXLarge),
            Text(
              message!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 应用空状态组件
/// 提供统一的空状态显示
class AppEmptyState extends StatelessWidget {
  /// 图标
  final IconData icon;

  /// 主要文本
  final String message;

  /// 次要文本
  final String? description;

  /// 操作按钮文本
  final String? actionText;

  /// 操作按钮回调
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.description,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: AppConstants.spacingXLarge),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (description != null) ...[
            const SizedBox(height: AppConstants.spacingMedium),
            Text(
              description!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (actionText != null && onAction != null) ...[
            const SizedBox(height: AppConstants.spacingXXLarge),
            AppButton(
              text: actionText!,
              onPressed: onAction,
              icon: Icons.refresh_rounded,
            ),
          ],
        ],
      ),
    );
  }
}
