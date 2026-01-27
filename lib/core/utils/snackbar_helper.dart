import 'package:flutter/material.dart';

/// SnackBar 工具类
///
/// 统一管理应用中的 SnackBar 显示，避免队列堵塞
class SnackBarHelper {
  /// 显示成功提示
  ///
  /// [context] - BuildContext
  /// [message] - 提示消息
  /// [duration] - 显示时长（默认 1 秒）
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 1),
  }) {
    _show(
      context,
      message,
      backgroundColor: Colors.green,
      icon: Icons.check_circle,
      duration: duration,
    );
  }

  /// 显示错误提示
  ///
  /// [context] - BuildContext
  /// [message] - 错误消息
  /// [duration] - 显示时长（默认 1.5 秒）
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    _show(
      context,
      message,
      backgroundColor: Colors.red,
      icon: Icons.error,
      duration: duration,
    );
  }

  /// 显示警告提示
  ///
  /// [context] - BuildContext
  /// [message] - 警告消息
  /// [duration] - 显示时长（默认 1.5 秒）
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    _show(
      context,
      message,
      backgroundColor: Colors.orange,
      icon: Icons.warning,
      duration: duration,
    );
  }

  /// 显示信息提示
  ///
  /// [context] - BuildContext
  /// [message] - 信息消息
  /// [duration] - 显示时长（默认 1 秒）
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 1),
  }) {
    _show(
      context,
      message,
      backgroundColor: Colors.blue,
      icon: Icons.info,
      duration: duration,
    );
  }

  /// 内部方法：显示 SnackBar
  static void _show(
    BuildContext context,
    String message, {
    required Color backgroundColor,
    required IconData icon,
    required Duration duration,
  }) {
    // 先清除当前显示的 SnackBar，避免队列堵塞
    ScaffoldMessenger.of(context).clearSnackBars();

    // 显示新的 SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 6,
      ),
    );
  }

  /// 清除所有 SnackBar
  static void clearAll(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
  }
}
