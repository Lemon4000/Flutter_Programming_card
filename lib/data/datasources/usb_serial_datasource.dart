import 'dart:async';
import 'dart:typed_data';
import 'package:usb_serial/usb_serial.dart';
import 'package:usb_serial/transaction.dart';

/// USB 串口数据源（Android 平台）
///
/// 使用 usb_serial 库支持 Android USB OTG 转串口设备
class UsbSerialDatasource {
  UsbPort? _port;
  StreamSubscription<String>? _subscription;
  Transaction<String>? _transaction;

  final _dataStreamController = StreamController<List<int>>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();

  /// 数据接收流
  Stream<List<int>> get dataStream => _dataStreamController.stream;

  /// 连接状态流
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  /// 是否已连接
  bool get isConnected => _port != null;

  /// 获取可用的 USB 串口设备列表
  Future<List<UsbDevice>> getAvailableDevices() async {
    try {
      final devices = await UsbSerial.listDevices();
      print('找到 ${devices.length} 个 USB 设备');
      for (var device in devices) {
        print('设备: ${device.deviceName}, VID: ${device.vid}, PID: ${device.pid}');
      }
      return devices;
    } catch (e) {
      print('获取 USB 设备列表失败: $e');
      return [];
    }
  }

  /// 连接 USB 串口设备
  ///
  /// 参数:
  /// - [device]: USB 设备对象
  /// - [baudRate]: 波特率（默认2000000）
  Future<void> connect(
    UsbDevice device, {
    int baudRate = 2000000,
  }) async {
    try {
      // 断开之前的连接
      if (_port != null) {
        await disconnect();
      }

      print('正在连接 USB 设备: ${device.deviceName} @ $baudRate bps');

      // 创建端口
      _port = await device.create();
      if (_port == null) {
        throw Exception('无法创建 USB 端口');
      }

      // 打开端口
      final openResult = await _port!.open();
      if (!openResult) {
        _port = null;
        throw Exception('无法打开 USB 端口');
      }

      print('USB 端口已打开，正在配置参数...');

      // 配置串口参数
      await _port!.setDTR(true);
      await _port!.setRTS(true);
      await _port!.setPortParameters(
        baudRate,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );

      print('USB 串口配置完成: $baudRate bps, 8N1');

      // 创建事务处理器（用于接收数据）
      _transaction = Transaction.stringTerminated(
        _port!.inputStream!,
        Uint8List.fromList([]), // 不使用终止符，接收所有数据
      );

      // 监听数据
      _subscription = _transaction!.stream.listen(
        (data) {
          if (data.isNotEmpty) {
            // 将字符串转换为字节列表
            final bytes = data.codeUnits;
            _dataStreamController.add(bytes);
          }
        },
        onError: (error) {
          print('USB 串口读取错误: $error');
          _dataStreamController.addError(error);
        },
        onDone: () {
          print('USB 串口连接断开');
          _handleDisconnection();
        },
      );

      _connectionStateController.add(true);
      print('USB 串口连接成功: ${device.deviceName} @ $baudRate bps');
    } catch (e) {
      _port = null;
      _transaction = null;
      _subscription = null;
      rethrow;
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    try {
      await _subscription?.cancel();
      _subscription = null;
      _transaction = null;

      if (_port != null) {
        await _port!.close();
      }
      _port = null;

      _connectionStateController.add(false);
      print('USB 串口已断开');
    } catch (e) {
      print('断开 USB 串口时出错: $e');
    }
  }

  /// 处理断开连接
  void _handleDisconnection() {
    _subscription = null;
    _transaction = null;
    _port = null;
    _connectionStateController.add(false);
  }

  /// 发送数据
  ///
  /// 参数:
  /// - [data]: 要发送的字节数据
  Future<void> write(List<int> data) async {
    if (_port == null) {
      throw Exception('USB 串口未连接');
    }

    try {
      await _port!.write(Uint8List.fromList(data));
    } catch (e) {
      print('USB 串口发送失败: $e');
      // 如果是I/O错误，可能是设备断开
      if (e.toString().contains('IOException') || e.toString().contains('disconnected')) {
        print('检测到 USB 设备断开');
        _handleDisconnection();
      }
      rethrow;
    }
  }

  /// 清理资源
  void dispose() {
    _subscription?.cancel();
    _port?.close();
    _dataStreamController.close();
    _connectionStateController.close();
  }
}
