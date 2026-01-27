import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/firmware_file.dart';
import '../../data/models/flash_progress.dart';
import '../../data/services/flash_worker.dart';
import '../providers/flash_providers.dart';
import '../providers/providers.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/snackbar_helper.dart';
import '../widgets/flash_progress_dialog.dart';

/// 烧录界面
class FlashScreen extends ConsumerStatefulWidget {
  const FlashScreen({super.key});

  @override
  ConsumerState<FlashScreen> createState() => _FlashScreenState();
}

class _FlashScreenState extends ConsumerState<FlashScreen> {
  FlashWorker? _flashWorker; // 保存当前的烧录 worker 实例

  /// 选择外部固件文件
  Future<void> _pickFirmwareFile() async {
    final dataSource = ref.read(firmwareDataSourceProvider);
    final firmware = await dataSource.pickFirmwareFile();

    if (firmware != null) {
      ref.read(selectedFirmwareProvider.notifier).state = firmware;
      if (mounted) {
        SnackBarHelper.showInfo(context, '已选择: ${firmware.name}');
      }
    }
  }

  /// 开始烧录
  Future<void> _startFlashing() async {
    final selectedFirmware = ref.read(selectedFirmwareProvider);
    if (selectedFirmware == null) {
      SnackBarHelper.showWarning(context, '请先选择固件文件');
      return;
    }

    // 检查连接状态
    final isConnected = ref.read(connectionStateProvider);
    if (!isConnected) {
      SnackBarHelper.showError(context, '设备未连接，请先连接设备');
      return;
    }

    AppLogger.info('=== 开始烧录 ===', 'FlashScreen');
    AppLogger.debug('固件路径: ${selectedFirmware.path}', 'FlashScreen');
    AppLogger.debug('固件大小: ${selectedFirmware.size}', 'FlashScreen');
    AppLogger.debug('是否为 assets: ${selectedFirmware.isAsset}', 'FlashScreen');
    AppLogger.debug('连接状态: $isConnected', 'FlashScreen');

    // 重置进度和日志
    final startTime = DateTime.now();
    ref.read(flashProgressProvider.notifier).state = FlashProgress.preparing('准备烧录...');
    ref.read(flashLogsProvider.notifier).state = [];

    // 获取 communication repository 用于停止烧录
    final communicationRepo = await ref.read(communicationRepositoryProvider.future);
    
    // 设置停止烧录回调
    ref.read(abortFlashingCallbackProvider.notifier).state = () {
      communicationRepo.abortFlashing();
    };

    // 显示进度对话框
    if (!mounted) return;
    final dialogResult = showDialog<dynamic>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const FlashProgressDialog(),
    );

    // 执行烧录
    AppLogger.info('调用 flashUseCase...', 'FlashScreen');

    // 等待 UseCase 加载完成
    final flashUseCase = await ref.read(flashFirmwareUseCaseProvider.future);

    // 读取初始化配置
    final initTimeout = ref.read(initTimeoutProvider);
    final initMaxRetries = ref.read(initMaxRetriesProvider);
    final programRetryDelay = ref.read(programRetryDelayProvider);

    AppLogger.debug('初始化配置: timeout=$initTimeout ms, maxRetries=$initMaxRetries', 'FlashScreen');
    AppLogger.debug('编程重试延迟: $programRetryDelay ms', 'FlashScreen');

    final result = await flashUseCase(
      selectedFirmware.path,
      onProgress: (flashProgress) {
        // 检查 widget 是否还存在
        if (!mounted) return;

        // 直接使用完整的 FlashProgress 对象，只需要确保 startTime 被保留
        ref.read(flashProgressProvider.notifier).state = flashProgress.copyWith(
          startTime: startTime,
        );

        // 不再累积日志到数组，避免性能问题
      },
      initTimeout: initTimeout,
      initMaxRetries: initMaxRetries,
      programRetryDelay: programRetryDelay,
    );

    AppLogger.info('烧录结果: ${result.isRight() ? "成功" : "失败"}', 'FlashScreen');

    // 检查 widget 是否还存在
    if (!mounted) return;

    // 处理结果
    result.fold(
      (failure) {
        AppLogger.error('烧录失败', 'FlashScreen', failure);
        AppLogger.error('失败消息: ${failure.toUserMessage()}', 'FlashScreen');

        ref.read(flashProgressProvider.notifier).state = FlashProgress.failed(
          failure.toUserMessage(),
          startTime: startTime,  // 传递开始时间
        );
      },
      (success) {
        ref.read(flashProgressProvider.notifier).state = FlashProgress.completed(
          totalBlocks: 0,
          totalBytes: 0,
          startTime: startTime,  // 传递开始时间
        );
      },
    );

    // 等待对话框关闭
    final result2 = await dialogResult;

    // 如果用户点击了重试
    if (result2 == 'retry' && mounted) {
      _startFlashing();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedFirmware = ref.watch(selectedFirmwareProvider);
    final initTimeout = ref.watch(initTimeoutProvider);
    final initMaxRetries = ref.watch(initMaxRetriesProvider);
    final programRetryDelay = ref.watch(programRetryDelayProvider);

    return Scaffold(
      body: Column(
        children: [
          // 固件选择区（仅从文件选择）
          Expanded(
            child: _buildFirmwareSelectionSection(selectedFirmware),
          ),

          const Divider(height: 1),

          // 初始化设置区（紧凑版）
          _buildCompactInitSettingsSection(initTimeout, initMaxRetries, programRetryDelay),

          const Divider(height: 1),

          // 操作按钮区 - 使用Consumer只重建按钮部分
          Consumer(
            builder: (context, ref, child) {
              final flashProgress = ref.watch(flashProgressProvider);
              return _buildActionButtonSection(
                selectedFirmware,
                flashProgress,
              );
            },
          ),
        ],
      ),
    );
  }

  /// 构建固件选择区（仅从文件选择）
  Widget _buildFirmwareSelectionSection(FirmwareFile? selectedFirmware) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
            Theme.of(context).colorScheme.surface,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          // 标题
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.folder_open_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  '选择固件文件',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // 选中的文件信息（可滚动）
          if (selectedFirmware != null)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 2,
                  color: Colors.blue.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.blue.shade200, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.insert_drive_file,
                            color: Colors.blue,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          selectedFirmware.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '大小: ${selectedFirmware.sizeFormatted}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        if (selectedFirmware.version != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '版本: ${selectedFirmware.version}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            ref.read(selectedFirmwareProvider.notifier).state = null;
                            SnackBarHelper.showInfo(context, '已取消选择');
                          },
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: const Text('取消选择'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            // 空状态
            Expanded(
              child: Center(
                child: Icon(
                  Icons.file_upload_outlined,
                  size: 40,
                  color: Colors.grey.shade400,
                ),
              ),
            ),

          // 从文件选择按钮（固定在底部）
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _pickFirmwareFile,
              icon: const Icon(Icons.file_upload_outlined, size: 20),
              label: const Text(
                '从文件选择',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建初始化设置区（紧凑版）
  Widget _buildCompactInitSettingsSection(int initTimeout, int initMaxRetries, int programRetryDelay) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.settings, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '烧录设置',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  '初始化: ${initTimeout}ms × $initMaxRetries次 | 编程重试: ${programRetryDelay}ms',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.tune, size: 20),
            tooltip: '调整设置',
            onPressed: () {
              _showInitSettingsDialog(context, initTimeout, initMaxRetries, programRetryDelay);
            },
          ),
        ],
      ),
    );
  }

  /// 显示初始化设置对话框
  void _showInitSettingsDialog(
    BuildContext context,
    int currentTimeout,
    int currentRetries,
    int currentProgramRetryDelay,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (context, ref, child) {
          // 监听 provider 的变化，实时更新滑块
          final timeout = ref.watch(initTimeoutProvider);
          final retries = ref.watch(initMaxRetriesProvider);
          final retryDelay = ref.watch(programRetryDelayProvider);

          return AlertDialog(
            title: const Text('烧录设置'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 初始化超时
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '初始化超时',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${timeout}ms',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: timeout.toDouble(),
                    min: 10,
                    max: 200,
                    divisions: 19,
                    label: '${timeout}ms',
                    onChanged: (value) {
                      ref.read(initTimeoutProvider.notifier).state = value.toInt();
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // 初始化重试
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '初始化重试',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '$retries次',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: retries.toDouble(),
                    min: 10,
                    max: 500,
                    divisions: 49,
                    label: '$retries次',
                    onChanged: (value) {
                      ref.read(initMaxRetriesProvider.notifier).state = value.toInt();
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // 编程重试延迟
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '编程重试延迟',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${retryDelay}ms',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: retryDelay.toDouble(),
                    min: 10,
                    max: 500,
                    divisions: 49,
                    label: '${retryDelay}ms',
                    onChanged: (value) {
                      ref.read(programRetryDelayProvider.notifier).state = value.toInt();
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('关闭'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 构建操作按钮区
  Widget _buildActionButtonSection(
    FirmwareFile? selectedFirmware,
    FlashProgress progress,
  ) {
    // 根据进度状态决定按钮文本和样式
    final bool isFailed = progress.status == FlashStatus.failed ||
                          progress.status == FlashStatus.cancelled;

    String buttonText;
    IconData buttonIcon;
    Color buttonColor;

    if (isFailed) {
      buttonText = '重试';
      buttonIcon = Icons.refresh_rounded;
      buttonColor = Colors.orange.shade600;
    } else if (progress.status == FlashStatus.completed) {
      buttonText = '重新烧录';
      buttonIcon = Icons.flash_on_rounded;
      buttonColor = const Color(0xFF2196F3);
    } else {
      buttonText = '开始烧录';
      buttonIcon = Icons.flash_on_rounded;
      buttonColor = const Color(0xFF2196F3);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: selectedFirmware != null ? _startFlashing : null,
        icon: Icon(buttonIcon, size: 28),
        label: Text(
          buttonText,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 64),
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade500,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: selectedFirmware != null ? 4 : 0,
          shadowColor: buttonColor.withOpacity(0.4),
        ),
      ),
    );
  }
}
