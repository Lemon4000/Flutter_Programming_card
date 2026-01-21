import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/log_provider.dart';

/// 日志条目
class LogEntry {
  final DateTime timestamp;
  final String direction; // 'TX' 或 'RX'
  final List<int> data;

  LogEntry({
    required this.timestamp,
    required this.direction,
    required this.data,
  });

  /// 转换为HEX格式
  String toHex() {
    return data.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');
  }

  /// 转换为ASCII格式
  String toAscii() {
    return data.map((b) {
      if (b >= 32 && b <= 126) {
        return String.fromCharCode(b);
      } else {
        return '.';
      }
    }).join('');
  }

  /// 格式化时间戳
  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}.'
        '${(timestamp.millisecond ~/ 10).toString().padLeft(2, '0')}';
  }
}

/// 日志显示模式
enum LogDisplayMode {
  hex,
  ascii,
  both,
}

/// 通信日志页面
class LogScreen extends ConsumerStatefulWidget {
  const LogScreen({super.key});

  @override
  ConsumerState<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends ConsumerState<LogScreen> {
  LogDisplayMode _displayMode = LogDisplayMode.hex;
  bool _autoScroll = true;
  bool _showTx = true;  // 显示发送数据
  bool _showRx = true;  // 显示接收数据
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 清除所有日志
  void _clearLogs() {
    ref.read(logProvider.notifier).clearLogs();
  }

  @override
  Widget build(BuildContext context) {
    final logState = ref.watch(logProvider);

    // 根据筛选条件过滤日志
    final filteredLogs = logState.logs.where((log) {
      if (!_showTx && log.direction == 'TX') return false;
      if (!_showRx && log.direction == 'RX') return false;
      return true;
    }).toList();

    // 自动滚动到底部
    if (_autoScroll && filteredLogs.isNotEmpty && _scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }

    return Scaffold(
      body: Column(
        children: [
          // 工具栏 - 美化版
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // 第一行：显示模式切换
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<LogDisplayMode>(
                        segments: const [
                          ButtonSegment(
                            value: LogDisplayMode.hex,
                            label: Text('HEX'),
                            icon: Icon(Icons.code, size: 16),
                          ),
                          ButtonSegment(
                            value: LogDisplayMode.ascii,
                            label: Text('ASCII'),
                            icon: Icon(Icons.text_fields, size: 16),
                          ),
                          ButtonSegment(
                            value: LogDisplayMode.both,
                            label: Text('混合'),
                            icon: Icon(Icons.view_column, size: 16),
                          ),
                        ],
                        selected: {_displayMode},
                        onSelectionChanged: (Set<LogDisplayMode> newSelection) {
                          setState(() {
                            _displayMode = newSelection.first;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 第二行：紧凑型控制栏
                Row(
                  children: [
                    // 左侧：筛选和控制
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // TX 筛选
                          _buildAnimatedFilterChip(
                            label: 'TX',
                            icon: Icons.upload,
                            selected: _showTx,
                            color: const Color(0xFF2196F3),
                            onTap: () => setState(() => _showTx = !_showTx),
                          ),

                          // RX 筛选
                          _buildAnimatedFilterChip(
                            label: 'RX',
                            icon: Icons.download,
                            selected: _showRx,
                            color: const Color(0xFF4CAF50),
                            onTap: () => setState(() => _showRx = !_showRx),
                          ),

                          // 日志记录开关
                          _buildAnimatedFilterChip(
                            label: logState.isLoggingEnabled ? '记录中' : '已暂停',
                            icon: logState.isLoggingEnabled ? Icons.pause : Icons.play_arrow,
                            selected: logState.isLoggingEnabled,
                            color: logState.isLoggingEnabled ? const Color(0xFFFF5722) : const Color(0xFF607D8B),
                            onTap: () => ref.read(logProvider.notifier).toggleLogging(),
                          ),

                          // 自动滚动
                          _buildAnimatedFilterChip(
                            label: '自动滚动',
                            icon: Icons.vertical_align_bottom,
                            selected: _autoScroll,
                            color: const Color(0xFF9C27B0),
                            onTap: () => setState(() => _autoScroll = !_autoScroll),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // 右侧：日志数量和清除
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 日志数量徽章（带动画）
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(
                              scale: animation,
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            key: ValueKey('${filteredLogs.length}/${logState.logs.length}'),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primaryContainer,
                                  Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.format_list_numbered,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${filteredLogs.length}/${logState.logs.length}',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // 清除按钮（带脉冲动画）
                        _buildClearButton(logState.logs.isNotEmpty),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 日志列表
          Expanded(
            child: filteredLogs.isEmpty
                ? Center(
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutBack,
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        final clampedValue = value.clamp(0.0, 1.0);
                        return Transform.scale(
                          scale: clampedValue,
                          child: Opacity(
                            opacity: clampedValue,
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 2000),
                            tween: Tween(begin: 0.0, end: 1.0),
                            builder: (context, value, child) {
                              return Transform.rotate(
                                angle: value * 2 * 3.14159,
                                child: child,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.blue.shade50,
                                    Colors.purple.shade50,
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withValues(alpha: 0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.article_outlined,
                                size: 72,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.grey.shade100,
                                  Colors.grey.shade50,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              logState.logs.isEmpty ? '暂无通信日志' : '无匹配的日志',
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  logState.logs.isEmpty ? Icons.info_outline : Icons.filter_alt_outlined,
                                  size: 16,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  logState.logs.isEmpty
                                      ? '连接设备后开始通信即可看到日志'
                                      : '请调整筛选条件',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: filteredLogs.length,
                    itemBuilder: (context, index) {
                      final log = filteredLogs[index];
                      return _buildLogItem(log, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// 构建动画筛选芯片
  Widget _buildAnimatedFilterChip({
    required String label,
    required IconData icon,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: selected ? 1.0 : 0.0),
      builder: (context, value, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOutCubic,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(24),
              splashColor: color.withValues(alpha: 0.3),
              highlightColor: color.withValues(alpha: 0.1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  gradient: selected
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withValues(alpha: 0.2),
                            color.withValues(alpha: 0.1),
                          ],
                        )
                      : null,
                  color: selected ? null : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: selected ? color : Colors.grey.shade300,
                    width: selected ? 2.5 : 1.5,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: color.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                            spreadRadius: 2,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // 背景光晕效果
                        if (selected)
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  color.withValues(alpha: 0.3),
                                  color.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        // 图标
                        AnimatedRotation(
                          duration: const Duration(milliseconds: 400),
                          turns: value * 0.5,
                          child: AnimatedScale(
                            duration: const Duration(milliseconds: 300),
                            scale: selected ? 1.1 : 1.0,
                            child: Icon(
                              selected ? Icons.check_circle_rounded : icon,
                              size: 17,
                              color: selected ? color : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 7),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                        color: selected ? color : Colors.grey.shade700,
                        letterSpacing: selected ? 0.5 : 0,
                      ),
                      child: Text(label),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建清除按钮
  Widget _buildClearButton(bool hasLogs) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1500),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, pulseValue, child) {
        return AnimatedScale(
          duration: const Duration(milliseconds: 200),
          scale: hasLogs ? 1.0 : 0.85,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: hasLogs ? 1.0 : 0.4,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: hasLogs ? _clearLogs : null,
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 脉冲光晕效果（仅在有日志时显示）
                    if (hasLogs)
                      Transform.scale(
                        scale: 1.0 + (pulseValue * 0.3),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.red.withValues(alpha: 0.2 * (1 - pulseValue)),
                                Colors.red.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    // 按钮主体
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        gradient: hasLogs
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.red.shade400,
                                  Colors.red.shade600,
                                  Colors.red.shade700,
                                ],
                              )
                            : LinearGradient(
                                colors: [
                                  Colors.grey.shade300,
                                  Colors.grey.shade400,
                                ],
                              ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: hasLogs
                            ? [
                                BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                  spreadRadius: 0,
                                ),
                                BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                  spreadRadius: 2,
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: AnimatedRotation(
                        duration: const Duration(milliseconds: 300),
                        turns: hasLogs ? 0 : 0.125,
                        child: const Icon(
                          Icons.delete_sweep_rounded,
                          size: 22,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogItem(LogEntry log, int index) {
    final isTx = log.direction == 'TX';
    final color = isTx ? const Color(0xFF2196F3) : const Color(0xFF4CAF50);

    return TweenAnimationBuilder<double>(
      key: ValueKey('${log.timestamp.millisecondsSinceEpoch}_${log.direction}'),
      duration: Duration(milliseconds: 300 + (index % 5) * 50),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        // 确保 value 在有效范围内
        final clampedValue = value.clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(0, 20 * (1 - clampedValue)),
          child: Opacity(
            opacity: clampedValue,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.08),
              color.withValues(alpha: 0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.5),
              blurRadius: 8,
              offset: const Offset(-2, -2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            splashColor: color.withValues(alpha: 0.2),
            highlightColor: color.withValues(alpha: 0.1),
            onTap: () {
              // 可选：点击展开详情或复制
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: color,
                      width: 5,
                    ),
                  ),
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 头部：时间戳和方向
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isTx
                                  ? [const Color(0xFF2196F3), const Color(0xFF1565C0)]
                                  : [const Color(0xFF4CAF50), const Color(0xFF2E7D32)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isTx ? Icons.arrow_upward : Icons.arrow_downward,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                log.direction,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 13,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                log.formattedTime,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.grey.shade200,
                                Colors.grey.shade100,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.data_usage_rounded,
                                size: 12,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${log.data.length}',
                                style: TextStyle(
                                  color: Colors.grey.shade800,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              Text(
                                ' B',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 数据内容
                    if (_displayMode == LogDisplayMode.hex || _displayMode == LogDisplayMode.both)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.grey.shade50,
                              Colors.grey.shade100,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: SelectableText(
                          log.toHex(),
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                            height: 1.4,
                          ),
                        ),
                      ),

                    if (_displayMode == LogDisplayMode.both)
                      const SizedBox(height: 8),

                    if (_displayMode == LogDisplayMode.ascii || _displayMode == LogDisplayMode.both)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: SelectableText(
                          log.toAscii(),
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: _displayMode == LogDisplayMode.both
                                ? Colors.grey.shade700
                                : Colors.grey.shade900,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

