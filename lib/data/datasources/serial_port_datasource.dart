import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_libserialport/flutter_libserialport.dart';

/// 串口数据源
///
/// 负责USB转串口设备的连接和数据收发
class SerialPortDatasource {
  SerialPort? _port;
  SerialPortReader? _reader;

  final _dataStreamController = StreamController<List<int>>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();

  /// 数据接收流
  Stream<List<int>> get dataStream => _dataStreamController.stream;

  /// 连接状态流
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  /// 是否已连接
  bool get isConnected => _port != null && _port!.isOpen;

  /// 获取可用的串口列表
  List<String> getAvailablePorts() {
    return SerialPort.availablePorts;
  }

  /// 连接串口
  ///
  /// 参数:
  /// - [portName]: 串口名称（如 "/dev/ttyUSB0" 或 "COM3"）
  /// - [baudRate]: 波特率（默认2000000）
  Future<void> connect(
    String portName, {
    int baudRate = 2000000,
  }) async {
    try {
      // 断开之前的连接
      if (_port != null) {
        await disconnect();
      }

      print('正在连接串口: $portName @ $baudRate bps');

      // 创建串口对象
      _port = SerialPort(portName);

      // 打开串口
      if (!_port!.openReadWrite()) {
        final error = SerialPort.lastError;
        throw Exception('无法打开串口: ${error?.message ?? "未知错误"} (errno: ${error?.errorCode ?? -1})');
      }

      print('串口已打开，正在配置参数...');

      // 配置串口参数
      final config = SerialPortConfig();
      config.baudRate = baudRate;
      config.bits = 8;
      config.stopBits = 1;
      config.parity = SerialPortParity.none;
      config.setFlowControl(SerialPortFlowControl.none);

      _port!.config = config;

      // 验证配置
      final actualConfig = _port!.config;
      print('串口配置: 波特率=${actualConfig.baudRate}, 数据位=${actualConfig.bits}, 停止位=${actualConfig.stopBits}');

      // 检查串口是否真的打开了
      if (!_port!.isOpen) {
        throw Exception('串口配置后状态异常');
      }

      // 创建读取器
      _reader = SerialPortReader(_port!);

      // 监听数据
      _reader!.stream.listen(
        (data) {
          if (data.isNotEmpty) {
            _dataStreamController.add(data);
          }
        },
        onError: (error) {
          print('串口读取错误: $error');
          _dataStreamController.addError(error);
        },
        onDone: () {
          print('串口连接断开');
          _handleDisconnection();
        },
      );

      _connectionStateController.add(true);
      print('串口连接成功: $portName @ $baudRate bps');
    } catch (e) {
      _port = null;
      _reader = null;
      rethrow;
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    try {
      _reader?.close();
      _reader = null;

      if (_port != null && _port!.isOpen) {
        _port!.close();
      }
      _port = null;

      _connectionStateController.add(false);
      print('串口已断开');
    } catch (e) {
      print('断开串口时出错: $e');
    }
  }

  /// 处理断开连接
  void _handleDisconnection() {
    _reader = null;
    _port = null;
    _connectionStateController.add(false);
  }

  /// 发送数据
  ///
  /// 参数:
  /// - [data]: 要发送的字节数据
  Future<void> write(List<int> data) async {
    if (_port == null || !_port!.isOpen) {
      throw Exception('串口未连接');
    }

    try {
      // 检查串口状态
      if (!_port!.isOpen) {
        throw Exception('串口已关闭');
      }

      final bytesWritten = _port!.write(Uint8List.fromList(data));

      if (bytesWritten < 0) {
        // 写入失败
        final error = SerialPort.lastError;
        throw Exception('串口写入失败: ${error?.message ?? "未知错误"} (errno: ${error?.errorCode ?? -1})');
      }

      if (bytesWritten != data.length) {
        throw Exception('数据发送不完整: 期望${data.length}字节，实际$bytesWritten字节');
      }

      // 等待数据发送完成
      _port!.drain();
    } catch (e) {
      print('串口发送失败: $e');
      // 如果是I/O错误，可能是设备断开，清理连接状态
      if (e.toString().contains('errno = 5') || e.toString().contains('输入/输出错误')) {
        print('检测到串口I/O错误，可能设备已断开');
        _handleDisconnection();
      }
      rethrow;
    }
  }

  /// 清理资源
  void dispose() {
    _reader?.close();
    if (_port != null && _port!.isOpen) {
      _port!.close();
    }
    _dataStreamController.close();
    _connectionStateController.close();
  }
}
