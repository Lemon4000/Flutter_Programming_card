import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// 设备信息模型
///
/// 封装蓝牙设备的基本信息
class DeviceInfo {
  /// 设备ID
  final String id;

  /// 设备名称
  final String name;

  /// 信号强度（RSSI）
  final int rssi;

  /// 原始蓝牙设备对象
  final BluetoothDevice device;

  /// 是否已连接
  final bool isConnected;

  const DeviceInfo({
    required this.id,
    required this.name,
    required this.rssi,
    required this.device,
    this.isConnected = false,
  });

  /// 从扫描结果创建设备信息
  factory DeviceInfo.fromScanResult(ScanResult result) {
    // 尝试从多个来源获取设备名称
    String deviceName = '';

    // 优先使用广播数据中的名称（这是最可靠的）
    if (result.advertisementData.advName.isNotEmpty) {
      deviceName = result.advertisementData.advName;
    }
    // 其次使用平台名称
    else if (result.device.platformName.isNotEmpty) {
      deviceName = result.device.platformName;
    }

    // 如果还是为空，显示为未知设备
    if (deviceName.isEmpty) {
      deviceName = '未知设备';
    }

    return DeviceInfo(
      id: result.device.remoteId.toString().toLowerCase(), // 统一转换为小写
      name: deviceName,
      rssi: result.rssi,
      device: result.device,
      isConnected: false,
    );
  }

  /// 从蓝牙设备创建设备信息
  factory DeviceInfo.fromDevice(
    BluetoothDevice device, {
    int rssi = 0,
    bool isConnected = false,
  }) {
    String deviceName = device.platformName;

    // 如果名称为空，使用 MAC 地址作为标识
    if (deviceName.isEmpty) {
      final macAddress = device.remoteId.toString().toLowerCase(); // 统一转换为小写
      deviceName = '未知设备 ($macAddress)';
    }

    return DeviceInfo(
      id: device.remoteId.toString().toLowerCase(), // 统一转换为小写
      name: deviceName,
      rssi: rssi,
      device: device,
      isConnected: isConnected,
    );
  }

  /// 复制并更新连接状态
  DeviceInfo copyWith({
    String? id,
    String? name,
    int? rssi,
    BluetoothDevice? device,
    bool? isConnected,
  }) {
    return DeviceInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      rssi: rssi ?? this.rssi,
      device: device ?? this.device,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DeviceInfo &&
        other.id == id &&
        other.name == name &&
        other.rssi == rssi &&
        other.isConnected == isConnected;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, rssi, isConnected);
  }

  @override
  String toString() {
    return 'DeviceInfo(id: $id, name: $name, rssi: $rssi, isConnected: $isConnected)';
  }
}
