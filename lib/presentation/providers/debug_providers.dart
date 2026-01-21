import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/debug_response.dart';
import '../../data/models/firmware_file.dart';
import '../../data/services/debug_service.dart';
import '../../data/protocol/frame_builder.dart';
import '../../data/protocol/frame_parser.dart';
import 'providers.dart';

// ============================================================================
// 调试服务 Provider
// ============================================================================

/// FrameBuilder Provider
final frameBuilderProvider = Provider<FrameBuilder>((ref) {
  final protocolConfig = ref.watch(protocolConfigProvider).value;
  if (protocolConfig == null) {
    throw Exception('协议配置未加载');
  }
  return FrameBuilder(protocolConfig);
});

/// FrameParser Provider
final frameParserProvider = Provider<FrameParser>((ref) {
  final protocolConfig = ref.watch(protocolConfigProvider).value;
  if (protocolConfig == null) {
    throw Exception('协议配置未加载');
  }
  return FrameParser(protocolConfig);
});

/// 调试服务 Provider
final debugServiceProvider = Provider<DebugService>((ref) {
  return DebugService(
    bluetoothDatasource: ref.read(bluetoothDatasourceProvider),
    frameBuilder: ref.read(frameBuilderProvider),
    frameParser: ref.read(frameParserProvider),
    onLog: (msg) {
      // 调试模式的日志记录到调试日志列表
      final logs = ref.read(debugLogsProvider);
      final timestamp = DateTime.now().toString().substring(11, 23);
      final newLogs = ['[$timestamp] $msg', ...logs];
      ref.read(debugLogsProvider.notifier).state = newLogs.take(10).toList();
    },
  );
});

// ============================================================================
// 调试状态 Providers
// ============================================================================

/// 选中的调试 HEX 文件
final debugHexFileProvider = StateProvider<FirmwareFile?>((ref) => null);

/// 当前数据块索引
final debugBlockIndexProvider = StateProvider<int>((ref) => 0);

/// 擦除块数
final debugEraseBlockCountProvider = StateProvider<int>((ref) => 1);

/// 验证 CRC 值
final debugVerifyCrcProvider = StateProvider<int>((ref) => 0);

// ============================================================================
// 响应状态 Providers
// ============================================================================

/// 握手指令响应
final handshakeResponseProvider = StateProvider<DebugResponse?>((ref) => null);

/// 擦除指令响应
final eraseResponseProvider = StateProvider<DebugResponse?>((ref) => null);

/// 数据帧响应
final dataFrameResponseProvider = StateProvider<DebugResponse?>((ref) => null);

/// 验证指令响应
final verifyResponseProvider = StateProvider<DebugResponse?>((ref) => null);

// ============================================================================
// 操作日志 Provider
// ============================================================================

/// 调试操作日志（最近10条）
final debugLogsProvider = StateProvider<List<String>>((ref) {
  return [];
});

/// 添加调试日志
void addDebugLog(WidgetRef ref, String message) {
  final logs = ref.read(debugLogsProvider);
  final timestamp = DateTime.now().toString().substring(11, 23); // HH:mm:ss.SSS
  final newLogs = ['[$timestamp] $message', ...logs];
  // 只保留最近10条
  ref.read(debugLogsProvider.notifier).state = newLogs.take(10).toList();
}
