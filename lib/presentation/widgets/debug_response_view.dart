import 'package:flutter/material.dart';
import '../../data/models/debug_response.dart';

/// 调试响应显示组件
///
/// 支持简洁和详细两种显示模式
class DebugResponseView extends StatefulWidget {
  final DebugResponse? response;
  final String commandName;

  const DebugResponseView({
    super.key,
    required this.response,
    required this.commandName,
  });

  @override
  State<DebugResponseView> createState() => _DebugResponseViewState();
}

class _DebugResponseViewState extends State<DebugResponseView> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.response == null) {
      return const SizedBox.shrink();
    }

    final response = widget.response!;

    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 简洁模式显示
            _buildCompactView(response),

            // 展开/收起按钮
            if (response.rawData != null)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                label: Text(_isExpanded ? '收起详情' : '展开详情'),
              ),

            // 详细模式显示
            if (_isExpanded && response.rawData != null)
              _buildDetailedView(response),
          ],
        ),
      ),
    );
  }

  /// 构建简洁视图
  Widget _buildCompactView(DebugResponse response) {
    return Row(
      children: [
        // 状态图标
        _buildStatusIcon(response.status),
        const SizedBox(width: 8),

        // 消息和耗时
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                response.message,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(response.status),
                ),
              ),
              Text(
                '耗时: ${response.elapsed.inMilliseconds}ms',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建详细视图
  Widget _buildDetailedView(DebugResponse response) {
    // 格式化时间为 HH:mm:ss.SSS
    String formatTime(DateTime time) {
      return '${time.hour.toString().padLeft(2, '0')}:'
          '${time.minute.toString().padLeft(2, '0')}:'
          '${time.second.toString().padLeft(2, '0')}.'
          '${time.millisecond.toString().padLeft(3, '0')}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),

        // 原始数据
        if (response.rawData != null) ...[
          const Text(
            '原始数据 (HEX):',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              response.rawDataHex ?? '',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // 解析结果
        if (response.parsedData != null) ...[
          const Text(
            '解析结果:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          ...response.parsedData!.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Row(
                children: [
                  Text(
                    '• ${entry.key}: ',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  Text(
                    entry.value.toString(),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
        ],

        // 时间信息
        const Text(
          '时间信息:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        if (response.sendTime != null)
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: Text(
              '• 发送时间: ${formatTime(response.sendTime!)}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        if (response.receiveTime != null)
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: Text(
              '• 接收时间: ${formatTime(response.receiveTime!)}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            '• 耗时: ${response.elapsed.inMilliseconds}ms',
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  /// 构建状态图标
  Widget _buildStatusIcon(DebugStatus status) {
    switch (status) {
      case DebugStatus.success:
        return const Icon(Icons.check_circle, color: Colors.green, size: 24);
      case DebugStatus.timeout:
        return const Icon(Icons.access_time, color: Colors.orange, size: 24);
      case DebugStatus.error:
        return const Icon(Icons.error, color: Colors.red, size: 24);
      case DebugStatus.waiting:
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
    }
  }

  /// 获取状态颜色
  Color _getStatusColor(DebugStatus status) {
    switch (status) {
      case DebugStatus.success:
        return Colors.green;
      case DebugStatus.timeout:
        return Colors.orange;
      case DebugStatus.error:
        return Colors.red;
      case DebugStatus.waiting:
        return Colors.blue;
    }
  }
}
