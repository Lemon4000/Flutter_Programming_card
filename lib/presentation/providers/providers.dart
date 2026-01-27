import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/bluetooth_datasource.dart';
import '../../data/datasources/cross_platform_bluetooth_datasource.dart';
import '../../data/datasources/serial_port_datasource.dart';
import '../../data/datasources/cross_platform_serial_datasource.dart';
import '../../data/datasources/communication_datasource.dart';
import '../../data/protocol/protocol_config.dart';
import '../../data/repositories/communication_repository_impl.dart';
import '../../data/repositories/config_repository_impl.dart';
import '../../data/repositories/device_repository_impl.dart';
import '../../domain/repositories/communication_repository.dart';
import '../../domain/repositories/config_repository.dart';
import '../../domain/repositories/device_repository.dart';
import '../../domain/usecases/connect_device_usecase.dart';
import '../../domain/usecases/flash_firmware_usecase.dart';
import '../../domain/usecases/read_parameters_usecase.dart';
import '../../domain/usecases/scan_devices_usecase.dart';
import '../../domain/usecases/write_parameters_usecase.dart';

// ============================================================================
// 数据源 Providers
// ============================================================================

/// 蓝牙数据源 Provider（非 Windows 平台）
final bluetoothDatasourceProvider = Provider<BluetoothDatasource>((ref) {
  return BluetoothDatasource();
});

/// 跨平台蓝牙数据源 Provider（包括 Windows）
final crossPlatformBluetoothDatasourceProvider = Provider<CrossPlatformBluetoothDatasource>((ref) {
  return CrossPlatformBluetoothDatasource();
});

/// 串口数据源 Provider（桌面平台）
final serialPortDatasourceProvider = Provider<SerialPortDatasource>((ref) {
  return SerialPortDatasource();
});

/// 跨平台串口数据源 Provider（用于扫描界面）
final crossPlatformSerialDatasourceProvider = Provider<CrossPlatformSerialDatasource>((ref) {
  return CrossPlatformSerialDatasource();
});

/// 当前通信类型 Provider
final communicationTypeProvider = StateProvider<CommunicationType>((ref) {
  return CommunicationType.bluetooth;
});

/// 选中的串口名称 Provider
final selectedSerialPortProvider = StateProvider<String?>((ref) => null);

/// 串口波特率 Provider
final serialPortBaudRateProvider = StateProvider<int>((ref) => 115200);

/// 协议配置 Provider
final protocolConfigProvider = FutureProvider<ProtocolConfig>((ref) async {
  final configRepo = ref.watch(configRepositoryProvider);
  final result = await configRepo.loadProtocolConfig();

  return result.fold(
    (failure) => throw Exception(failure.message),
    (config) => config,
  );
});

// ============================================================================
// 仓库 Providers
// ============================================================================

/// 设备仓库 Provider（根据平台选择蓝牙实现）
final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  // Windows 使用跨平台蓝牙（universal_ble）
  // 其他平台使用原生蓝牙（flutter_blue_plus）
  if (!kIsWeb && Platform.isWindows) {
    final datasource = ref.watch(crossPlatformBluetoothDatasourceProvider);
    return DeviceRepositoryImpl.crossPlatform(datasource);
  } else {
    final datasource = ref.watch(bluetoothDatasourceProvider);
    return DeviceRepositoryImpl.bluetooth(datasource);
  }
});

/// 配置仓库 Provider
final configRepositoryProvider = Provider<ConfigRepository>((ref) {
  return ConfigRepositoryImpl();
});

/// 通信仓库 Provider
final communicationRepositoryProvider = FutureProvider<CommunicationRepository>((ref) async {
  final communicationType = ref.watch(communicationTypeProvider);
  final protocolConfig = await ref.watch(protocolConfigProvider.future);

  if (communicationType == CommunicationType.bluetooth) {
    // Windows 使用跨平台蓝牙（universal_ble）
    // 其他平台使用原生蓝牙（flutter_blue_plus）
    if (!kIsWeb && Platform.isWindows) {
      final datasource = ref.watch(crossPlatformBluetoothDatasourceProvider);
      return CommunicationRepositoryImpl.crossPlatformBluetooth(datasource, protocolConfig, ref);
    } else {
      final datasource = ref.watch(bluetoothDatasourceProvider);
      return CommunicationRepositoryImpl.bluetooth(datasource, protocolConfig, ref);
    }
  } else {
    // 使用跨平台串口数据源
    final datasource = ref.watch(crossPlatformSerialDatasourceProvider);
    return CommunicationRepositoryImpl.crossPlatformSerial(datasource, protocolConfig, ref);
  }
});

// ============================================================================
// 用例 Providers
// ============================================================================

/// 扫描设备用例 Provider
final scanDevicesUseCaseProvider = Provider<ScanDevicesUseCase>((ref) {
  final repository = ref.watch(deviceRepositoryProvider);
  return ScanDevicesUseCase(repository);
});

/// 连接设备用例 Provider
final connectDeviceUseCaseProvider = Provider<ConnectDeviceUseCase>((ref) {
  final repository = ref.watch(deviceRepositoryProvider);
  return ConnectDeviceUseCase(repository);
});

/// 读取参数用例 Provider
final readParametersUseCaseProvider = FutureProvider<ReadParametersUseCase>((ref) async {
  final commRepo = await ref.watch(communicationRepositoryProvider.future);
  final configRepo = ref.watch(configRepositoryProvider);
  return ReadParametersUseCase(commRepo, configRepo);
});

/// 写入参数用例 Provider
final writeParametersUseCaseProvider = FutureProvider<WriteParametersUseCase>((ref) async {
  final repository = await ref.watch(communicationRepositoryProvider.future);
  return WriteParametersUseCase(repository);
});

/// 烧录固件用例 Provider
final flashFirmwareUseCaseProvider = FutureProvider<FlashFirmwareUseCase>((ref) async {
  final repository = await ref.watch(communicationRepositoryProvider.future);
  return FlashFirmwareUseCase(repository);
});

// ============================================================================
// 状态管理 Providers
// ============================================================================

/// 连接状态 Provider
final connectionStateProvider = StateProvider<bool>((ref) => false);

/// 已连接设备ID Provider
final connectedDeviceIdProvider = StateProvider<String?>((ref) => null);

/// 已连接设备名称 Provider
final connectedDeviceNameProvider = StateProvider<String?>((ref) => null);
