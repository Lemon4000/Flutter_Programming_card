import 'package:flutter/material.dart';
import '../../data/models/debug_response.dart';
import 'debug_response_view.dart';

/// 调试指令卡片组件
///
/// 通用的指令卡片，包含标题、输入区域、操作按钮和响应显示
class DebugCommandCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? inputWidget;
  final VoidCallback onSend;
  final bool isLoading;
  final DebugResponse? response;

  const DebugCommandCard({
    super.key,
    required this.title,
    required this.icon,
    this.inputWidget,
    required this.onSend,
    required this.isLoading,
    this.response,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题区域
            Row(
              children: [
                Icon(icon, size: 28, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            // 输入区域
            if (inputWidget != null) ...[
              const SizedBox(height: 16),
              inputWidget!,
            ],

            // 操作区域
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: isLoading ? null : onSend,
                  icon: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(isLoading ? '发送中...' : '发送'),
                ),
                const SizedBox(width: 12),
                // 状态指示器
                if (response != null)
                  Expanded(
                    child: Row(
                      children: [
                        _buildStatusChip(response!.status),
                      ],
                    ),
                  ),
              ],
            ),

            // 响应区域
            if (response != null)
              DebugResponseView(
                response: response,
                commandName: title,
              ),
          ],
        ),
      ),
    );
  }

  /// 构建状态标签
  Widget _buildStatusChip(DebugStatus status) {
    Color color;
    String label;

    switch (status) {
      case DebugStatus.success:
        color = Colors.green;
        label = '成功';
        break;
      case DebugStatus.timeout:
        color = Colors.orange;
        label = '超时';
        break;
      case DebugStatus.error:
        color = Colors.red;
        label = '失败';
        break;
      case DebugStatus.waiting:
        color = Colors.blue;
        label = '等待中';
        break;
    }

    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
