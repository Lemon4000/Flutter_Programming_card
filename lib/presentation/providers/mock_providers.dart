import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/simple_mock_bluetooth_datasource.dart';

/// 全局模拟蓝牙数据源Provider
final mockBluetoothProvider = Provider<SimpleMockBluetoothDatasource>((ref) {
  final datasource = SimpleMockBluetoothDatasource();

  // 当Provider被销毁时清理资源
  ref.onDispose(() {
    datasource.dispose();
  });

  return datasource;
});

/// 连接状态Provider
final connectionStateProvider = StateProvider<bool>((ref) => false);

/// 已连接设备ID Provider
final connectedDeviceIdProvider = StateProvider<String?>((ref) => null);

/// 已连接设备名称Provider
final connectedDeviceNameProvider = StateProvider<String?>((ref) => null);
