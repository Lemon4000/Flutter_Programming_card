import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/models/firmware_file.dart';
import '../providers/debug_providers.dart';
import '../providers/providers.dart';
import '../widgets/debug_command_card.dart';

/// 调试页面
///
/// 提供手动发送协议指令和查看响应的功能
class DebugScreen extends ConsumerStatefulWidget {
  const DebugScreen({super.key});

  @override
  ConsumerState<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends ConsumerState<DebugScreen> {
  bool _isHandshakeLoading = false;
  bool _isEraseLoading = false;
  bool _isDataFrameLoading = false;
  bool _isVerifyLoading = false;

  @override
  Widget build(BuildContext context) {
    final isConnected = ref.watch(bluetoothDatasourceProvider).isConnected;
    final hexFile = ref.watch(debugHexFileProvider);
    final blockIndex = ref.watch(debugBlockIndexProvider);
    final eraseBlockCount = ref.watch(debugEraseBlockCountProvider);
    final verifyCrc = ref.watch(debugVerifyCrcProvider);

    final handshakeResponse = ref.watch(handshakeResponseProvider);
    final eraseResponse = ref.watch(eraseResponseProvider);
    final dataFrameResponse = ref.watch(dataFrameResponseProvider);
    final verifyResponse = ref.watch(verifyResponseProvider);

    final debugLogs = ref.watch(debugLogsProvider);

    return Scaffold(
      body: Column(
        children: [
          // 连接状态栏
          _buildConnectionBar(isConnected),

          // 主内容区域
          Expanded(
            child: !isConnected
                ? _buildNotConnectedView()
                : SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),

                        // 握手指令卡片
                        DebugCommandCard(
                          title: '握手指令',
                          icon: Icons.handshake,
                          onSend: _sendHandshake,
                          isLoading: _isHandshakeLoading,
                          response: handshakeResponse,
                        ),

                        // 擦除指令卡片
                        DebugCommandCard(
                          title: '擦除指令',
                          icon: Icons.delete_sweep,
                          inputWidget: _buildEraseInput(eraseBlockCount),
                          onSend: _sendErase,
                          isLoading: _isEraseLoading,
                          response: eraseResponse,
                        ),

                        // 数据帧卡片
                        DebugCommandCard(
                          title: '数据帧',
                          icon: Icons.data_array,
                          inputWidget: _buildDataFrameInput(hexFile, blockIndex),
                          onSend: hexFile != null ? _sendDataFrame : () {},
                          isLoading: _isDataFrameLoading,
                          response: dataFrameResponse,
                        ),

                        // 验证指令卡片
                        DebugCommandCard(
                          title: '验证指令',
                          icon: Icons.verified,
                          inputWidget: _buildVerifyInput(verifyCrc),
                          onSend: _sendVerify,
                          isLoading: _isVerifyLoading,
                          response: verifyResponse,
                        ),

                        // 操作日志
                        _buildLogsSection(debugLogs),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// 构建连接状态栏
  Widget _buildConnectionBar(bool isConnected) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isConnected ? Colors.green[50] : Colors.red[50],
        border: Border(
          bottom: BorderSide(
            color: isConnected ? Colors.green : Colors.red,
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
            color: isConnected ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(
            isConnected ? '设备已连接' : '设备未连接',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isConnected ? Colors.green[900] : Colors.red[900],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建未连接视图
  Widget _buildNotConnectedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bluetooth_disabled,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '请先连接设备',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '在"设备"标签中扫描并连接设备',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建擦除输入区域
  Widget _buildEraseInput(int blockCount) {
    return Row(
      children: [
        const Text('擦除块数:'),
        const SizedBox(width: 12),
        Expanded(
          child: Slider(
            value: blockCount.toDouble(),
            min: 1,
            max: 100,
            divisions: 99,
            label: blockCount.toString(),
            onChanged: (value) {
              ref.read(debugEraseBlockCountProvider.notifier).state = value.toInt();
            },
          ),
        ),
        SizedBox(
          width: 60,
          child: Text(
            blockCount.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  /// 构建数据帧输入区域
  Widget _buildDataFrameInput(FirmwareFile? hexFile, int blockIndex) {
    final dataBlocks = hexFile?.dataBlocks ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 文件选择
        Row(
          children: [
            Expanded(
              child: Text(
                hexFile != null ? hexFile.name : '未选择文件',
                style: TextStyle(
                  color: hexFile != null ? Colors.black : Colors.grey,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _pickHexFile,
              icon: const Icon(Icons.folder_open, size: 18),
              label: const Text('选择 HEX'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),

        // 数据块选择
        if (hexFile != null && dataBlocks.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('数据块:'),
              const SizedBox(width: 12),
              Expanded(
                child: Slider(
                  value: blockIndex.toDouble(),
                  min: 0,
                  max: (dataBlocks.length - 1).toDouble(),
                  divisions: dataBlocks.length - 1,
                  label: '$blockIndex / ${dataBlocks.length - 1}',
                  onChanged: (value) {
                    ref.read(debugBlockIndexProvider.notifier).state = value.toInt();
                  },
                ),
              ),
              SizedBox(
                width: 80,
                child: Text(
                  '$blockIndex / ${dataBlocks.length - 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          // 显示当前块信息
          if (blockIndex < dataBlocks.length) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '地址: 0x${dataBlocks[blockIndex].address.toRadixString(16).toUpperCase().padLeft(8, '0')}',
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                  Text(
                    '大小: ${dataBlocks[blockIndex].data.length} 字节',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],

          // 连续发送按钮
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: ref.watch(isContinuousSendingProvider)
                      ? null
                      : _sendAllDataFrames,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: Text('连续发送全部 (${dataBlocks.length} 块)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              if (ref.watch(isContinuousSendingProvider)) ...[
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _stopContinuousSending,
                  icon: const Icon(Icons.stop, size: 18),
                  label: const Text('停止'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  /// 构建验证输入区域
  Widget _buildVerifyInput(int crc) {
    return Row(
      children: [
        const Text('CRC 值 (HEX):'),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            decoration: const InputDecoration(
              hintText: '输入 4 位十六进制 CRC',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Fa-f]')),
              LengthLimitingTextInputFormatter(4),
            ],
            onChanged: (value) {
              if (value.length == 4) {
                final crcValue = int.tryParse(value, radix: 16);
                if (crcValue != null) {
                  ref.read(debugVerifyCrcProvider.notifier).state = crcValue;
                }
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '0x${crc.toRadixString(16).toUpperCase().padLeft(4, '0')}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
        ),
      ],
    );
  }

  /// 构建日志区域
  Widget _buildLogsSection(List<String> logs) {
    if (logs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '操作日志',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    ref.read(debugLogsProvider.notifier).state = [];
                  },
                  child: const Text('清空'),
                ),
              ],
            ),
            const Divider(),
            ...logs.map((log) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    log,
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  /// 选择 HEX 文件
  Future<void> _pickHexFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['hex'],
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final name = result.files.single.name;

        // 加载 HEX 文件
        final hexFile = await FirmwareFile.fromHexFile(path, name);

        ref.read(debugHexFileProvider.notifier).state = hexFile;
        ref.read(debugBlockIndexProvider.notifier).state = 0;

        addDebugLog(ref, '已加载 HEX 文件: $name (${hexFile.dataBlocks?.length ?? 0} 个数据块)');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载 HEX 文件失败: $e')),
        );
      }
    }
  }

  /// 发送握手指令
  Future<void> _sendHandshake() async {
    setState(() => _isHandshakeLoading = true);
    addDebugLog(ref, '发送握手指令');

    try {
      final debugService = ref.read(debugServiceProvider);
      final response = await debugService.sendHandshake();

      ref.read(handshakeResponseProvider.notifier).state = response;
      addDebugLog(ref, '握手响应: ${response.message}');
    } catch (e) {
      addDebugLog(ref, '握手异常: $e');
    } finally {
      if (mounted) {
        setState(() => _isHandshakeLoading = false);
      }
    }
  }

  /// 发送擦除指令
  Future<void> _sendErase() async {
    final blockCount = ref.read(debugEraseBlockCountProvider);

    setState(() => _isEraseLoading = true);
    addDebugLog(ref, '发送擦除指令: $blockCount 块');

    try {
      final debugService = ref.read(debugServiceProvider);
      final response = await debugService.sendErase(blockCount: blockCount);

      ref.read(eraseResponseProvider.notifier).state = response;
      addDebugLog(ref, '擦除响应: ${response.message}');
    } catch (e) {
      addDebugLog(ref, '擦除异常: $e');
    } finally {
      if (mounted) {
        setState(() => _isEraseLoading = false);
      }
    }
  }

  /// 发送数据帧
  Future<void> _sendDataFrame() async {
    final hexFile = ref.read(debugHexFileProvider);
    final blockIndex = ref.read(debugBlockIndexProvider);
    final dataBlocks = hexFile?.dataBlocks;

    if (hexFile == null || dataBlocks == null || blockIndex >= dataBlocks.length) {
      return;
    }

    final block = dataBlocks[blockIndex];

    setState(() => _isDataFrameLoading = true);
    addDebugLog(ref, '发送数据帧: 块 $blockIndex, 地址 0x${block.address.toRadixString(16).toUpperCase()}');

    try {
      final debugService = ref.read(debugServiceProvider);
      final response = await debugService.sendDataFrame(
        address: block.address,
        data: block.data,
      );

      ref.read(dataFrameResponseProvider.notifier).state = response;
      addDebugLog(ref, '数据帧响应: ${response.message}');
    } catch (e) {
      addDebugLog(ref, '数据帧异常: $e');
    } finally {
      if (mounted) {
        setState(() => _isDataFrameLoading = false);
      }
    }
  }

  /// 发送验证指令
  Future<void> _sendVerify() async {
    final crc = ref.read(debugVerifyCrcProvider);

    setState(() => _isVerifyLoading = true);
    addDebugLog(ref, '发送验证指令: CRC 0x${crc.toRadixString(16).toUpperCase().padLeft(4, '0')}');

    try {
      final debugService = ref.read(debugServiceProvider);
      final response = await debugService.sendVerify(totalCrc: crc);

      ref.read(verifyResponseProvider.notifier).state = response;
      addDebugLog(ref, '验证响应: ${response.message}');
    } catch (e) {
      addDebugLog(ref, '验证异常: $e');
    } finally {
      if (mounted) {
        setState(() => _isVerifyLoading = false);
      }
    }
  }

  /// 连续发送全部数据帧
  Future<void> _sendAllDataFrames() async {
    final hexFile = ref.read(debugHexFileProvider);
    final dataBlocks = hexFile?.dataBlocks;

    if (hexFile == null || dataBlocks == null || dataBlocks.isEmpty) {
      return;
    }

    final sendInterval = ref.read(sendIntervalProvider);
    
    // 标记为正在连续发送
    ref.read(isContinuousSendingProvider.notifier).state = true;
    setState(() => _isDataFrameLoading = true);

    try {
      final debugService = ref.read(debugServiceProvider);

      // 从当前块开始发送到最后一块
      final startIndex = ref.read(debugBlockIndexProvider);
      
      for (int i = startIndex; i < dataBlocks.length; i++) {
        // 检查是否被停止
        if (!ref.read(isContinuousSendingProvider)) {
          addDebugLog(ref, '连续发送已停止');
          break;
        }

        // 更新当前块索引
        ref.read(debugBlockIndexProvider.notifier).state = i;

        final block = dataBlocks[i];
        addDebugLog(ref, '发送数据帧: 块 $i/${dataBlocks.length - 1}, 地址 0x${block.address.toRadixString(16).toUpperCase()}');

        try {
          // 只发送数据，等待写入完成（不等待响应）
          await debugService.sendDataFrameOnly(
            address: block.address,
            data: block.data,
          );
        } catch (e) {
          addDebugLog(ref, '数据帧发送失败: $e');
          // 继续发送下一块
        }

        // 等待发送间隔（除了最后一块）
        if (i < dataBlocks.length - 1) {
          await Future.delayed(Duration(milliseconds: sendInterval));
        }
      }

      addDebugLog(ref, '连续发送完成');
    } catch (e) {
      addDebugLog(ref, '连续发送异常: $e');
    } finally {
      ref.read(isContinuousSendingProvider.notifier).state = false;
      if (mounted) {
        setState(() => _isDataFrameLoading = false);
      }
    }
  }

  /// 停止连续发送
  void _stopContinuousSending() {
    ref.read(isContinuousSendingProvider.notifier).state = false;
    addDebugLog(ref, '请求停止连续发送');
  }
}
