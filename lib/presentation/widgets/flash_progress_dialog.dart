import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/flash_progress.dart';
import '../providers/flash_providers.dart';

/// 烧录进度对话框
class FlashProgressDialog extends ConsumerStatefulWidget {
  const FlashProgressDialog({super.key});

  @override
  ConsumerState<FlashProgressDialog> createState() => _FlashProgressDialogState();
}

class _FlashProgressDialogState extends ConsumerState<FlashProgressDialog> {
  bool _showLogs = false;

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // 只监听进度，不监听日志（避免频繁重建）
    final progress = ref.watch(flashProgressProvider);

    // 使用 FlashProgress 中的 startTime 计算已用时
    final elapsed = progress.startTime != null
        ? DateTime.now().difference(progress.startTime!)
        : Duration.zero;

    // 不自动关闭对话框，让用户手动点击"完成"按钮

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 400,
          maxHeight: 600,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题
            Row(
              children: [
                Icon(
                  Icons.sync_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  '烧录进度',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 状态图标和进度
            if (progress.status == FlashStatus.completed)
              _buildSuccessState()
            else if (progress.status == FlashStatus.failed ||
                     progress.status == FlashStatus.cancelled)
              _buildFailedState(progress)
            else
              _buildProgressState(progress, elapsed),

            const SizedBox(height: 24),

            // 移除日志显示部分，避免UI重建开销

            // 底部按钮
            _buildActionButtons(progress),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle_rounded,
            size: 64,
            color: Colors.green.shade600,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '烧录成功！',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '固件已成功烧录到设备',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildFailedState(FlashProgress progress) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.error_rounded,
            size: 64,
            color: Colors.red.shade600,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '烧录失败',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.red.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          progress.message,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProgressState(FlashProgress progress, Duration elapsed) {
    return Column(
      children: [
        // 进度条
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: CircularProgressIndicator(
                value: progress.progress,
                strokeWidth: 12,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            Text(
              '${(progress.progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 状态消息
        Text(
          progress.message,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade800,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // 时间和速度信息
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem(
                Icons.access_time_rounded,
                '已用时',
                _formatDuration(elapsed),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey.shade300,
              ),
              _buildInfoItem(
                Icons.speed_rounded,
                '状态',
                progress.status.displayName,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(FlashProgress progress) {
    if (progress.status == FlashStatus.completed) {
      return ElevatedButton(
        onPressed: () => Navigator.of(context).pop(true),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          backgroundColor: Colors.green.shade600,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          '完成',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else if (progress.status == FlashStatus.failed ||
               progress.status == FlashStatus.cancelled) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('关闭'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop('retry');
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 48),
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('重试'),
            ),
          ),
        ],
      );
    } else {
      // 烧录中
      return OutlinedButton.icon(
        onPressed: () {
          // 停止烧录
          ref.read(flashProgressProvider.notifier).state =
              FlashProgress.cancelled();
          Navigator.of(context).pop(false);
        },
        icon: const Icon(Icons.stop_rounded),
        label: const Text('停止烧录'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}
