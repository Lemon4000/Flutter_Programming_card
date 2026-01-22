import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// 蓝牙数据源
///
/// 负责蓝牙设备的扫描、连接和数据收发
class BluetoothDatasource {
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _txCharacteristic;
  BluetoothCharacteristic? _rxCharacteristic;

  final _dataStreamController = StreamController<List<int>>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();
  StreamSubscription? _connectionStateSubscription;

  // 缓存已配对设备的名称
  Map<String, String> _bondedDeviceNames = {};
  
  // 扫描状态标志
  bool _isScanning = false;

  // 构造函数 - 禁用 Flutter Blue Plus 日志
  BluetoothDatasource() {
    // 设置日志级别为 NONE (0) 以禁用所有日志
    FlutterBluePlus.setLogLevel(LogLevel.none);
  }

  /// 数据接收流
  Stream<List<int>> get dataStream => _dataStreamController.stream;

  /// 连接状态流
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  /// 当前连接的设备
  BluetoothDevice? get connectedDevice => _connectedDevice;

  /// 是否已连接
  bool get isConnected => _connectedDevice != null;

  /// 获取已配对设备的名称映射
  Map<String, String> get bondedDeviceNames => _bondedDeviceNames;

  /// 扫描蓝牙设备
  ///
  /// 参数:
  /// - [timeout]: 扫描超时时间
  ///
  /// 返回:
  /// - 扫描结果流
  Stream<List<ScanResult>> scanDevices({
    Duration timeout = const Duration(seconds: 10),
  }) async* {
    try {
      // 防止重复扫描
      if (_isScanning) {
        print('扫描已在进行中，跳过');
        return;
      }
      
      print('开始新的扫描...');
      _isScanning = true;
      
      // 检查蓝牙是否可用
      final isSupported = await FlutterBluePlus.isSupported;
      if (!isSupported) {
        throw Exception('设备不支持蓝牙');
      }

      // 检查蓝牙是否开启
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        throw Exception('蓝牙未开启');
      }

      // 检查当前是否正在扫描
      try {
        final isScanning = await FlutterBluePlus.isScanning.first.timeout(
          const Duration(seconds: 2),
        );
        print('FlutterBluePlus 当前扫描状态: $isScanning');
        
        if (isScanning) {
          print('检测到正在扫描，强制停止...');
          await FlutterBluePlus.stopScan();
          await Future.delayed(const Duration(milliseconds: 1000));
          print('强制停止完成');
        }
      } catch (e) {
        print('检查扫描状态失败: $e');
      }
      
      // 重要：先停止之前可能存在的扫描，避免资源冲突
      try {
        print('停止之前的扫描...');
        await FlutterBluePlus.stopScan();
        // 等待更长时间，确保扫描完全停止
        await Future.delayed(const Duration(milliseconds: 1000));
        print('之前的扫描已停止');
      } catch (e) {
        print('停止之前的扫描时出错（可忽略）: $e');
      }

      // 获取系统已配对的设备（这些设备有缓存的名称）
      try {
        final bondedDevices = await FlutterBluePlus.bondedDevices;
        _bondedDeviceNames.clear();
        for (var device in bondedDevices) {
          final id = device.remoteId.toString().toLowerCase(); // 统一转换为小写
          final name = device.platformName;
          if (name.isNotEmpty) {
            _bondedDeviceNames[id] = name;
            print('已配对设备: $name ($id)');
          }
        }
      } catch (e) {
        print('获取已配对设备失败: $e');
        // 继续执行，不影响扫描
      }

      // 开始扫描 - 不使用超时，由外部控制停止
      print('启动蓝牙扫描（无超时限制，由用户控制停止）');
      await FlutterBluePlus.startScan(
        // 移除 timeout 参数，让扫描持续进行直到手动停止
        androidUsesFineLocation: true,
      );
      print('蓝牙扫描已启动');

      // 返回扫描结果流
      try {
        await for (final results in FlutterBluePlus.scanResults) {
          if (!_isScanning) {
            print('扫描已被外部停止，退出扫描循环');
            break;
          }
          yield results;
        }
      } catch (e) {
        print('扫描结果流异常: $e');
        rethrow;
      }
      
      print('扫描结果流结束');
    } on Exception catch (e) {
      print('扫描过程中出错: $e');
      rethrow;
    } catch (e) {
      print('扫描过程中出现未知错误: $e');
      throw Exception('蓝牙扫描失败: $e');
    } finally {
      print('扫描清理开始...');
      _isScanning = false;
      
      // 确保扫描被停止
      try {
        print('finally: 调用 FlutterBluePlus.stopScan()');
        await FlutterBluePlus.stopScan();
        print('finally: 扫描已停止');
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        print('finally: 停止扫描时出错: $e');
      }
      
      print('扫描清理完成');
    }
  }

  /// 停止扫描
  Future<void> stopScan() async {
    print('stopScan() 被调用，当前状态: _isScanning=$_isScanning');
    
    if (!_isScanning) {
      print('扫描未在进行中，跳过停止操作');
      return;
    }
    
    try {
      _isScanning = false;
      print('调用 FlutterBluePlus.stopScan()');
      await FlutterBluePlus.stopScan();
      print('扫描已停止');
      
      // 检查蓝牙适配器状态
      try {
        final adapterState = await FlutterBluePlus.adapterState.first.timeout(
          const Duration(seconds: 2),
        );
        print('蓝牙适配器状态: $adapterState');
      } catch (e) {
        print('获取蓝牙适配器状态失败: $e');
      }
      
      // 等待更长时间，确保扫描完全停止
      await Future.delayed(const Duration(milliseconds: 1000));
      print('等待完成，扫描应该已完全停止');
    } catch (e) {
      print('停止扫描时出错: $e');
      print('错误堆栈: ${StackTrace.current}');
      // 即使出错，也标记为未扫描
      _isScanning = false;
    }
  }

  /// 连接设备
  ///
  /// 参数:
  /// - [device]: 要连接的蓝牙设备
  /// - [timeout]: 连接超时时间
  Future<void> connect(
    BluetoothDevice device, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      // 断开之前的连接
      if (_connectedDevice != null) {
        await disconnect();
      }

      // 监听连接状态变化
      _connectionStateSubscription?.cancel();
      _connectionStateSubscription = device.connectionState.listen(
        (state) {
          if (state == BluetoothConnectionState.disconnected) {
            _handleDisconnection();
          } else if (state == BluetoothConnectionState.connected) {
            _connectionStateController.add(true);
          }
        },
        onError: (error) {
          print('连接状态监听错误: $error');
          _handleDisconnection();
        },
      );

      // 连接设备
      await device.connect(timeout: timeout, autoConnect: false);
      _connectedDevice = device;

      // 发现服务和特征值
      final services = await device.discoverServices();

      // 查找TX和RX特征值
      for (final service in services) {
        for (final characteristic in service.characteristics) {
          // TX特征值（写入）- 上位机写入，设备接收
          if (characteristic.properties.write ||
              characteristic.properties.writeWithoutResponse) {
            _txCharacteristic = characteristic;
          }

          // RX特征值（通知）- 设备发送，上位机接收
          if (characteristic.properties.notify ||
              characteristic.properties.indicate) {
            _rxCharacteristic = characteristic;

            // 启用通知
            await characteristic.setNotifyValue(true);

            // 监听数据
            characteristic.lastValueStream.listen(
              (data) {
                if (data.isNotEmpty) {
                  _dataStreamController.add(data);
                }
              },
              onError: (error) {
                print('接收数据出错: $error');
                _dataStreamController.addError(error);
              },
            );
          }
        }
      }

      // 检查是否找到必要的特征值
      if (_txCharacteristic == null) {
        throw Exception('未找到TX特征值（可写入的特征值）');
      }

      if (_rxCharacteristic == null) {
        throw Exception('未找到RX特征值（可通知的特征值）');
      }
    } catch (e) {
      _connectedDevice = null;
      _txCharacteristic = null;
      _rxCharacteristic = null;
      rethrow;
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    try {
      if (_rxCharacteristic != null) {
        await _rxCharacteristic!.setNotifyValue(false);
      }

      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
      }
    } finally {
      _connectionStateSubscription?.cancel();
      _connectionStateSubscription = null;
      _connectedDevice = null;
      _txCharacteristic = null;
      _rxCharacteristic = null;
      _connectionStateController.add(false);
    }
  }

  /// 处理断开连接
  void _handleDisconnection() {
    _connectionStateSubscription?.cancel();
    _connectionStateSubscription = null;
    _connectedDevice = null;
    _txCharacteristic = null;
    _rxCharacteristic = null;
    _connectionStateController.add(false);
  }

  /// 清理资源
  void dispose() {
    _connectionStateSubscription?.cancel();
    _dataStreamController.close();
    _connectionStateController.close();
  }

  /// 发送数据
  ///
  /// 参数:
  /// - [data]: 要发送的字节数据
  /// - [withoutResponse]: 是否不等待响应
  /// - [allowChunking]: 是否允许分片发送（默认true）
  Future<void> write(
    List<int> data, {
    bool withoutResponse = false,
    bool allowChunking = true,
  }) async {
    if (_txCharacteristic == null) {
      throw Exception('未连接设备或未找到TX特征值');
    }

    // 发送缓冲区大小限制 - 调整为512字节以支持烧录功能
    const maxTxBufferSize = 512;
    if (data.length > maxTxBufferSize) {
      throw Exception('发送数据超过限制（${maxTxBufferSize}字节），当前大小：${data.length}字节');
    }

    try {
      // 根据特征值的属性选择合适的写入方式
      final useWithoutResponse = withoutResponse ||
          (_txCharacteristic!.properties.writeWithoutResponse &&
           !_txCharacteristic!.properties.write);

      // BLE MTU 限制，单次最大发送 500 字节（保守值）
      const maxChunkSize = 500;

      // 如果不允许分片或数据小于限制，直接发送
      if (!allowChunking || data.length <= maxChunkSize) {
        await _txCharacteristic!.write(
          data,
          withoutResponse: useWithoutResponse,
        );
      } else {
        // 数据超过限制，分片发送
        int offset = 0;

        while (offset < data.length) {
          final end = (offset + maxChunkSize < data.length)
              ? offset + maxChunkSize
              : data.length;
          final chunk = data.sublist(offset, end);

          await _txCharacteristic!.write(
            chunk,
            withoutResponse: useWithoutResponse,
          );

          // 优化：减少分片之间的延迟到10ms，加快传输速度
          if (end < data.length) {
            await Future.delayed(const Duration(milliseconds: 10));
          }

          offset = end;
        }
      }
    } catch (e) {
      print('✗ 数据发送失败: $e');
      rethrow;
    }
  }
}
