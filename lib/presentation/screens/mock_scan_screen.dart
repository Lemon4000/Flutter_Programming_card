import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/simple_mock_bluetooth_datasource.dart';
import '../providers/mock_providers.dart';
import '../../core/utils/logger.dart';

/// 模拟模式设备扫描页面
class MockScanScreen extends ConsumerStatefulWidget {
  const MockScanScreen({super.key});

  @override
  ConsumerState<MockScanScreen> createState() => _MockScanScreenState();
}

class _MockScanScreenState extends ConsumerState<MockScanScreen> {
  List<MockScanResult> _devices = [];
  bool _isScanning = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // 初始化时检查连接状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkConnectionState();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 每次页面显示时检查连接状态
    _checkConnectionState();
  }

  void _checkConnectionState() {
    final datasource = ref.read(mockBluetoothProvider);
    final isConnected = datasource.isConnected;
    final deviceId = datasource.connectedDeviceId;

    // 更新全局状态
    ref.read(connectionStateProvider.notifier).state = isConnected;
    if (deviceId != null) {
      ref.read(connectedDeviceIdProvider.notifier).state = deviceId;
    }

    AppLogger.debug('检查连接状态: isConnected=$isConnected, deviceId=$deviceId', 'MockScanScreen');
  }

  void _startScan() {
    final datasource = ref.read(mockBluetoothProvider);

    setState(() {
      _isScanning = true;
      _errorMessage = null;
      _devices = [];
    });

    datasource.scanDevices().listen(
      (devices) {
        if (mounted) {
          setState(() {
            _devices = devices;
          });
        }
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
            _errorMessage = error.toString();
            _isScanning = false;
          });
        }
      },
    );
  }

  Future<void> _stopScan() async {
    final datasource = ref.read(mockBluetoothProvider);
    await datasource.stopScan();
    if (mounted) {
      setState(() {
        _isScanning = false;
      });
    }
  }

  void _connectToDevice(MockScanResult result) async {
    final datasource = ref.read(mockBluetoothProvider);

    // 先停止扫描
    if (_isScanning) {
      await _stopScan();
      await Future.delayed(const Duration(milliseconds: 500));
    }

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
      await datasource.connect(result.device.id);

      if (!mounted) return;
      Navigator.of(context).pop(); // 关闭对话框

      // 更新全局连接状态
      ref.read(connectionStateProvider.notifier).state = true;
      ref.read(connectedDeviceIdProvider.notifier).state = result.device.id;
      ref.read(connectedDeviceNameProvider.notifier).state = result.device.name;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已连接到 ${result.device.name}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // 关闭对话框

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('连接失败: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _disconnect() async {
    final datasource = ref.read(mockBluetoothProvider);
    await datasource.disconnect();

    // 更新全局连接状态
    ref.read(connectionStateProvider.notifier).state = false;
    ref.read(connectedDeviceIdProvider.notifier).state = null;
    ref.read(connectedDeviceNameProvider.notifier).state = null;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已断开连接'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = ref.watch(connectionStateProvider);
    final connectedDeviceId = ref.watch(connectedDeviceIdProvider);

    return Column(
      children: [
        // 模拟模式提示
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: Colors.blue.shade50,
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '当前为模拟模式 - 使用虚拟设备进行测试',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // 连接状态
        if (isConnected)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.green.shade50,
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '已连接到设备',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _disconnect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('断开'),
                ),
              ],
            ),
          ),

        // 扫描控制区域
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isScanning ? _stopScan : _startScan,
                  icon: Icon(_isScanning ? Icons.stop : Icons.search),
                  label: Text(_isScanning ? '停止扫描' : '开始扫描'),
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
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
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
                        _isScanning
                            ? Icons.bluetooth_searching
                            : Icons.bluetooth,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isScanning ? '正在扫描设备...' : '点击开始扫描按钮搜索设备',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _devices.length,
                  itemBuilder: (context, index) {
                    final result = _devices[index];
                    final isThisConnected =
                        connectedDeviceId == result.device.id;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.bluetooth,
                          color: isThisConnected ? Colors.green : Colors.blue,
                        ),
                        title: Text(result.device.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ID: ${result.device.id}'),
                            Text('RSSI: ${result.rssi} dBm'),
                          ],
                        ),
                        trailing: isThisConnected
                            ? const Chip(
                                label: Text('已连接'),
                                backgroundColor: Colors.green,
                              )
                            : ElevatedButton(
                                onPressed: isConnected
                                    ? null
                                    : () => _connectToDevice(result),
                                child: const Text('连接'),
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
