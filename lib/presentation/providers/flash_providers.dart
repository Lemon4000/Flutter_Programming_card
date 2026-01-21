import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/firmware_datasource.dart';
import '../../data/models/firmware_file.dart';
import '../../data/models/flash_progress.dart';

/// 固件数据源 Provider
final firmwareDataSourceProvider = Provider<FirmwareDataSource>((ref) {
  return FirmwareDataSource();
});

/// 预设固件列表 Provider
final presetFirmwaresProvider = FutureProvider<List<FirmwareFile>>((ref) async {
  final dataSource = ref.read(firmwareDataSourceProvider);
  return await dataSource.loadPresetFirmwares();
});

/// 当前选中的固件 Provider
final selectedFirmwareProvider = StateProvider<FirmwareFile?>((ref) => null);

/// 烧录进度 Provider
final flashProgressProvider = StateProvider<FlashProgress>((ref) {
  return FlashProgress.idle();
});

/// 是否显示详细信息 Provider
final showFlashDetailProvider = StateProvider<bool>((ref) => false);

/// 烧录日志 Provider
final flashLogsProvider = StateProvider<List<String>>((ref) => []);

/// 初始化超时时间（毫秒）Provider
final initTimeoutProvider = StateProvider<int>((ref) => 50);

/// 初始化最大重试次数 Provider
final initMaxRetriesProvider = StateProvider<int>((ref) => 100);

/// 编程阶段重试延迟（毫秒）Provider
final programRetryDelayProvider = StateProvider<int>((ref) => 50);

