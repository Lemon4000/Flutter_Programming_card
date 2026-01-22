import 'dart:async';
import 'dart:io';
import 'package:usb_serial/usb_serial.dart';
import 'serial_port_datasource.dart';
import 'usb_serial_datasource.dart';

/// 串口设备信息（统一接口）
class SerialDeviceInfo {
  final String id;
  final String name;
  final dynamic nativeDevice; // UsbDevice 或 String (端口名)

  SerialDeviceInfo({
    required this.id,
    required this.name,
    required this.nativeDevice,
  });
}

/// 跨平台串口数据源适配器
///
/// 在 Android 上使用 UsbSerialDatasource
/// 在桌面平台使用 SerialPortDatasource
class CrossPlatformSerialDatasource {
  SerialPortDatasource? _desktopDatasource;
  UsbSerialDatasource? _androidDatasource;

  final _dataStreamController = StreamController<List<int>>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();

  /// 数据接收流
  Stream<List<int>> get dataStream => _dataStreamController.stream;

  /// 连接状态流
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  /// 是否已连接
  bool get isConnected {
    if (Platform.isAndroid) {
      return _androidDatasource?.isConnected ?? false;
    } else {
      return _desktopDatasource?.isConnected ?? false;
    }
  }

  /// 获取可用的串口设备列表
  Future<List<SerialDeviceInfo>> getAvailableDevices() async {
    if (Platform.isAndroid) {
      // Android: 使用 USB Serial
      final usbSerial = UsbSerialDatasource();
      final devices = await usbSerial.getAvailableDevices();

      return devices.map((device) {
        return SerialDeviceInfo(
          id: device.deviceId.toString(),
          name: '${device.manufacturerName ?? "USB"} ${device.productName ?? "Serial"} (VID:${device.vid} PID:${device.pid})',
          nativeDevice: device,
        );
      }).toList();
    } else {
      // 桌面平台: 使用 libserialport
      final serialPort = SerialPortDatasource();
      final ports = serialPort.getAvailablePorts();

      return ports.map((portName) {
        return SerialDeviceInfo(
          id: portName,
          name: portName,
          nativeDevice: portName,
        );
      }).toList();
    }
  }

  /// 连接串口设备
  ///
  /// 参数:
  /// - [device]: 设备信息对象
  /// - [baudRate]: 波特率（默认2000000）
  Future<void> connect(
    SerialDeviceInfo device, {
    int baudRate = 2000000,
  }) async {
    try {
      // 断开之前的连接
      await disconnect();

      if (Platform.isAndroid) {
        // Android: 使用 USB Serial
        _androidDatasource = UsbSerialDatasource();

        // 监听数据流
        _androidDatasource!.dataStream.listen(
          (data) => _dataStreamController.add(data),
          onError: (error) => _dataStreamController.addError(error),
        );

        // 监听连接状态
        _androidDatasource!.connectionStateStream.listen(
          (state) => _connectionStateController.add(state),
        );

        // 连接设备
        await _androidDatasource!.connect(
          device.nativeDevice as UsbDevice,
          baudRate: baudRate,
        );
      } else {
        // 桌面平台: 使用 libserialport
        _desktopDatasource = SerialPortDatasource();

        // 监听数据流
        _desktopDatasource!.dataStream.listen(
          (data) => _dataStreamController.add(data),
          onError: (error) => _dataStreamController.addError(error),
        );

        // 监听连接状态
        _desktopDatasource!.connectionStateStream.listen(
          (state) => _connectionStateController.add(state),
        );

        // 连接设备
        await _desktopDatasource!.connect(
          device.nativeDevice as String,
          baudRate: baudRate,
        );
      }
    } catch (e) {
      _androidDatasource = null;
      _desktopDatasource = null;
      rethrow;
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    try {
      if (_androidDatasource != null) {
        await _androidDatasource!.disconnect();
        _androidDatasource = null;
      }

      if (_desktopDatasource != null) {
        await _desktopDatasource!.disconnect();
        _desktopDatasource = null;
      }
    } catch (e) {
      print('断开串口时出错: $e');
    }
  }

  /// 发送数据
  ///
  /// 参数:
  /// - [data]: 要发送的字节数据
  Future<void> write(List<int> data) async {
    if (Platform.isAndroid) {
      if (_androidDatasource == null) {
        throw Exception('串口未连接');
      }
      await _androidDatasource!.write(data);
    } else {
      if (_desktopDatasource == null) {
        throw Exception('串口未连接');
      }
      await _desktopDatasource!.write(data);
    }
  }

  /// 清理资源
  void dispose() {
    _androidDatasource?.dispose();
    _desktopDatasource?.dispose();
    _dataStreamController.close();
    _connectionStateController.close();
  }
}
