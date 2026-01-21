import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/device.dart';
import '../providers/providers.dart';
import '../../core/utils/permission_helper.dart';

/// 设备扫描页面
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  List<Device> _devices = [];
  bool _isScanning = false;
  String? _errorMessage;

  /// 对设备列表排序
  /// 1. 含有 "CYW" 和 "Surpass" 的设备置顶（不需要连续）
  /// 2. 其他设备按信号强度排序
  List<Device> _sortDevices(List<Device> devices) {
    final sortedDevices = List<Device>.from(devices);
    sortedDevices.sort((a, b) {
      // 检查是否包含 "CYW" 和 "Surpass"（不区分大小写，不需要连续）
      final aNameUpper = a.name.toUpperCase();
      final bNameUpper = b.name.toUpperCase();

      final aIsCYW = aNameUpper.contains('CYW') && aNameUpper.contains('SURPASS');
      final bIsCYW = bNameUpper.contains('CYW') && bNameUpper.contains('SURPASS');

      // 如果一个是 CYW Surpass，另一个不是，CYW Surpass 排前面
      if (aIsCYW && !bIsCYW) return -1;
      if (!aIsCYW && bIsCYW) return 1;

      // 如果都是或都不是 CYW Surpass，按信号强度排序（信号强度越高越靠前）
      return b.rssi.compareTo(a.rssi);
    });
    return sortedDevices;
  }

  void _startScan() async {
    // 防止重复扫描
    if (_isScanning) {
      return;
    }

    // 检查平台支持
    if (!kIsWeb && Platform.isLinux) {
      setState(() {
        _errorMessage = '提示：Linux桌面版本的蓝牙功能可能受限。建议在Android或iOS设备上测试完整功能。';
      });
    }

    // 请求蓝牙权限
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final hasPermission = await PermissionHelper.requestBluetoothPermissions();
      if (!hasPermission) {
        if (mounted) {
          setState(() {
            _errorMessage = '需要蓝牙和位置权限才能扫描设备。请在设置中授予权限。';
            _isScanning = false;
          });

          // 显示权限说明对话框
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('需要权限'),
              content: const Text(
                '扫描蓝牙设备需要以下权限：\n\n'
                '• 蓝牙权限：用于扫描和连接蓝牙设备\n'
                '• 位置权限：Android系统要求，用于蓝牙扫描\n\n'
                '请在设置中授予这些权限。',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    PermissionHelper.openAppSettings();
                  },
                  child: const Text('打开设置'),
                ),
              ],
            ),
          );
        }
        return;
      }
    }

    setState(() {
      _isScanning = true;
      if (_errorMessage?.contains('Linux') != true) {
        _errorMessage = null;
      }
      _devices = [];
    });

    final scanUseCase = ref.read(scanDevicesUseCaseProvider);

    try {
      scanUseCase().listen(
        (result) {
          result.fold(
            (failure) {
              if (mounted) {
                setState(() {
                  // 特殊处理扫描注册失败错误
                  if (failure.toString().contains('REGISTRATION_FAILED') ||
                      failure.toString().contains('扫描失败')) {
                    _errorMessage = '蓝牙扫描启动失败。请稍后重试或重启蓝牙。';
                  } else {
                    _errorMessage = failure.toUserMessage();
                  }
                  _isScanning = false;
                });
              }
            },
            (devices) {
              if (mounted) {
                setState(() {
                  // 对设备列表排序：CYW Surpass 设备置顶，其他按信号强度排序
                  _devices = _sortDevices(devices);
                });
              }
            },
          );
        },
        onDone: () {
          if (mounted) {
            setState(() {
              _isScanning = false;
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _errorMessage = '扫描出错: ${error.toString()}';
              _isScanning = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '启动扫描失败: ${e.toString()}';
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _stopScan() async {
    final scanUseCase = ref.read(scanDevicesUseCaseProvider);
    await scanUseCase.stop();

    if (mounted) {
      setState(() {
        _isScanning = false;
      });
    }
  }

  void _connectToDevice(Device device) async {
    // 先停止扫描
    if (_isScanning) {
      await _stopScan();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    final connectUseCase = ref.read(connectDeviceUseCaseProvider);

    // 显示连接对话框
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('正在连接...'),
          ],
        ),
      ),
    );

    try {
      // 添加超时处理
      final result = await connectUseCase(device.id, timeout: const Duration(seconds: 10))
          .timeout(const Duration(seconds: 12));

      if (!mounted) return;
      Navigator.of(context).pop(); // 关闭对话框

      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.toUserMessage()),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        },
        (_) {
          // 更新全局连接状态
          ref.read(connectionStateProvider.notifier).state = true;
          ref.read(connectedDeviceIdProvider.notifier).state = device.id;
          ref.read(connectedDeviceNameProvider.notifier).state = device.name;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已连接到 ${device.name}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // 关闭对话框

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('连接超时: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 扫描控制区域
        Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                Theme.of(context).colorScheme.surface,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isScanning ? _stopScan : _startScan,
                      icon: Icon(_isScanning ? Icons.stop : Icons.bluetooth_searching),
                      label: Text(
                        _isScanning ? '停止扫描' : '开始扫描',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: _isScanning
                            ? Colors.red.shade400
                            : Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: _isScanning ? 0 : 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 添加说明文字
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Colors.blue.shade700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '提示：设备按信号强度排序。"未知设备"表示设备未广播名称，请尝试连接后查看。',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade800,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 错误信息
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
              color: _errorMessage!.contains('提示')
                  ? Colors.orange.shade50
                  : Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _errorMessage!.contains('提示')
                              ? Icons.warning
                              : Icons.error,
                          color: _errorMessage!.contains('提示')
                              ? Colors.orange
                              : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: _errorMessage!.contains('提示')
                                  ? Colors.orange.shade900
                                  : Colors.red.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // 如果是扫描失败错误，显示解决建议
                    if (_errorMessage!.contains('扫描启动失败') ||
                        _errorMessage!.contains('REGISTRATION_FAILED'))
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          '💡 解决方法：\n'
                          '1. 关闭并重新打开手机蓝牙\n'
                          '2. 等待 5-10 秒后再次扫描\n'
                          '3. 如果问题持续，请重启应用',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

        // 设备列表
        Expanded(
          child: _devices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isScanning ? Icons.bluetooth_searching : Icons.bluetooth_disabled,
                        size: 80,
                        color: _isScanning ? Theme.of(context).colorScheme.primary : Colors.grey.shade400,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _isScanning ? '正在扫描设备...' : '点击开始扫描按钮搜索设备',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_isScanning) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _devices.length,
                  itemBuilder: (context, index) {
                    final device = _devices[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Card(
                        elevation: 0,
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: device.isConnected
                                ? Colors.green.withOpacity(0.3)
                                : Colors.grey.shade200,
                            width: 1.5,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: device.isConnected
                                  ? Colors.green.withOpacity(0.1)
                                  : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              device.isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                              color: device.isConnected
                                  ? Colors.green.shade700
                                  : Theme.of(context).colorScheme.primary,
                              size: 28,
                            ),
                          ),
                          title: Text(
                            device.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              // 只在名称不包含MAC地址时才显示MAC地址
                              if (!device.name.contains(device.id))
                                Row(
                                  children: [
                                    Icon(Icons.fingerprint, size: 14, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        device.id,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontFamily: 'monospace',
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    device.rssi > -70
                                        ? Icons.signal_cellular_alt
                                        : device.rssi > -85
                                            ? Icons.signal_cellular_alt_2_bar
                                            : Icons.signal_cellular_alt_1_bar,
                                    size: 14,
                                    color: device.rssi > -70
                                        ? Colors.green
                                        : device.rssi > -85
                                            ? Colors.orange
                                            : Colors.red,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${device.rssi} dBm',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: device.rssi > -70
                                          ? Colors.green
                                          : device.rssi > -85
                                              ? Colors.orange
                                              : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: device.isConnected
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.green.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle, size: 16, color: Colors.white),
                                      SizedBox(width: 4),
                                      Text(
                                        '已连接',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Tooltip(
                                  message: '连接到 ${device.name}',
                                  child: ElevatedButton(
                                    onPressed: () => _connectToDevice(device),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: const Text(
                                      '连接',
                                      style: TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
