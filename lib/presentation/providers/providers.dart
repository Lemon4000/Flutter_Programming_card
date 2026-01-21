import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/bluetooth_datasource.dart';
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

/// 蓝牙数据源 Provider
final bluetoothDatasourceProvider = Provider<BluetoothDatasource>((ref) {
  return BluetoothDatasource();
});

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

/// 设备仓库 Provider
final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  final datasource = ref.watch(bluetoothDatasourceProvider);
  return DeviceRepositoryImpl(datasource);
});

/// 配置仓库 Provider
final configRepositoryProvider = Provider<ConfigRepository>((ref) {
  return ConfigRepositoryImpl();
});

/// 通信仓库 Provider
final communicationRepositoryProvider = FutureProvider<CommunicationRepository>((ref) async {
  final datasource = ref.watch(bluetoothDatasourceProvider);
  final protocolConfig = await ref.watch(protocolConfigProvider.future);

  return CommunicationRepositoryImpl(datasource, protocolConfig, ref);
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
