import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

/// 权限辅助类
class PermissionHelper {
  /// 请求蓝牙相关权限
  static Future<bool> requestBluetoothPermissions() async {
    if (Platform.isAndroid) {
      // Android 12+ (API 31+) 需要新的蓝牙权限
      final androidInfo = await _getAndroidVersion();

      if (androidInfo >= 31) {
        // Android 12+
        final bluetoothScan = await Permission.bluetoothScan.request();
        final bluetoothConnect = await Permission.bluetoothConnect.request();

        // 如果应用需要使用位置来扫描蓝牙设备
        final location = await Permission.locationWhenInUse.request();

        return bluetoothScan.isGranted &&
               bluetoothConnect.isGranted &&
               location.isGranted;
      } else {
        // Android 11及以下
        final bluetooth = await Permission.bluetooth.request();
        final location = await Permission.locationWhenInUse.request();

        return bluetooth.isGranted && location.isGranted;
      }
    } else if (Platform.isIOS) {
      // iOS只需要蓝牙权限
      final bluetooth = await Permission.bluetooth.request();
      return bluetooth.isGranted;
    }

    return true; // 其他平台默认允许
  }

  /// 检查蓝牙权限是否已授予
  static Future<bool> checkBluetoothPermissions() async {
    if (Platform.isAndroid) {
      final androidInfo = await _getAndroidVersion();

      if (androidInfo >= 31) {
        return await Permission.bluetoothScan.isGranted &&
               await Permission.bluetoothConnect.isGranted &&
               await Permission.locationWhenInUse.isGranted;
      } else {
        return await Permission.bluetooth.isGranted &&
               await Permission.locationWhenInUse.isGranted;
      }
    } else if (Platform.isIOS) {
      return await Permission.bluetooth.isGranted;
    }

    return true;
  }

  /// 获取Android版本
  static Future<int> _getAndroidVersion() async {
    if (!Platform.isAndroid) return 0;

    try {
      // 这里简化处理，实际应该使用device_info_plus获取
      // 暂时假设是Android 12+
      return 31;
    } catch (e) {
      return 30; // 默认返回Android 11
    }
  }

  /// 打开应用设置页面
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }
}
