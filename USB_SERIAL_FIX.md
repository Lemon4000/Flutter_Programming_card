# Android USB 串口修复说明

## 问题描述

原来使用的 `flutter_libserialport` 库在 Android 平台上无法工作，会报错：
```
SerialPortError: Permission denied errno = 13
```

## 根本原因

`flutter_libserialport` 库主要为桌面平台（Linux、Windows、macOS）设计，不支持 Android 的 USB Host API。在 Android 上访问 USB 串口设备需要：
1. 使用 Android USB Host API
2. 请求用户授权访问 USB 设备
3. 正确配置 AndroidManifest.xml

参考资料：
- [GitHub Issue #26](https://github.com/jpnurmi/flutter_libserialport/issues/26)
- [GitHub Issue #4](https://github.com/jpnurmi/flutter_libserialport/issues/4)

## 解决方案

已添加 `usb_serial` 库来支持 Android USB 串口通信。

### 1. 依赖更新

在 `pubspec.yaml` 中添加：
```yaml
dependencies:
  # USB 串口通信（Android）
  usb_serial: ^0.5.2

  # 串口通信（桌面平台）
  flutter_libserialport: ^0.4.0
```

### 2. 新增文件

- `lib/data/datasources/usb_serial_datasource.dart` - Android USB 串口数据源
- `android/app/src/main/res/xml/device_filter.xml` - USB 设备过滤器配置

### 3. AndroidManifest.xml 更新

添加了：
- USB Host 权限声明
- USB 设备连接 intent-filter
- USB 设备过滤器配置

## 使用方法

### 在 Android 上使用 USB 串口

```dart
import 'package:programming_card_host/data/datasources/usb_serial_datasource.dart';

// 创建数据源
final usbSerial = UsbSerialDatasource();

// 1. 获取可用的 USB 设备列表
final devices = await usbSerial.getAvailableDevices();
if (devices.isEmpty) {
  print('未找到 USB 设备');
  return;
}

// 2. 选择设备并连接
final device = devices.first;
await usbSerial.connect(device, baudRate: 2000000);

// 3. 监听接收的数据
usbSerial.dataStream.listen((data) {
  print('收到数据: $data');
});

// 4. 发送数据
await usbSerial.write([0x01, 0x02, 0x03]);

// 5. 断开连接
await usbSerial.disconnect();

// 6. 清理资源
usbSerial.dispose();
```

### 在桌面平台使用串口

桌面平台继续使用原来的 `SerialPortDatasource`：

```dart
import 'package:programming_card_host/data/datasources/serial_port_datasource.dart';

final serialPort = SerialPortDatasource();

// 获取串口列表
final ports = serialPort.getAvailablePorts();

// 连接串口
await serialPort.connect('/dev/ttyUSB0', baudRate: 2000000);
```

### 平台检测

可以使用 `Platform` 类来检测当前平台：

```dart
import 'dart:io';

if (Platform.isAndroid) {
  // 使用 UsbSerialDatasource
  final datasource = UsbSerialDatasource();
} else {
  // 使用 SerialPortDatasource
  final datasource = SerialPortDatasource();
}
```

## 支持的 USB 转串口芯片

已在 `device_filter.xml` 中配置了常见的 USB 转串口芯片：

- **CH340/CH341** 系列（最常见）
- **FTDI** 系列（FT232、FT2232 等）
- **CP210x** 系列（Silicon Labs）
- **PL2303** 系列（Prolific）
- **CDC ACM** 设备（通用 USB 串口）

如果您的设备使用其他芯片，可以在 `device_filter.xml` 中添加对应的 VID/PID。

## 权限处理

当 USB 设备插入时：
1. Android 会自动检测设备
2. 如果设备匹配 `device_filter.xml` 中的配置，会提示用户是否允许应用访问
3. 用户授权后，应用可以访问该设备

**注意**：用户需要手动授权每个 USB 设备。如果用户拒绝授权，应用将无法访问该设备。

## 测试步骤

1. 安装依赖：
   ```bash
   flutter pub get
   ```

2. 构建并安装到 Android 设备：
   ```bash
   flutter build apk --release
   flutter install
   ```

3. 连接 USB OTG 转串口设备到 Android 设备

4. 打开应用，应该会看到 USB 权限请求对话框

5. 授权后，应用可以访问 USB 串口设备

## 故障排除

### 问题：找不到 USB 设备

**解决方案**：
- 确认 USB OTG 线正常工作
- 检查 Android 设备是否支持 USB Host 模式
- 在设置中检查是否启用了 USB 调试

### 问题：权限请求对话框不出现

**解决方案**：
- 检查 `device_filter.xml` 中是否包含您的设备 VID/PID
- 使用 `adb shell lsusb` 查看设备的 VID/PID
- 手动添加到 `device_filter.xml`

### 问题：连接后无法读写数据

**解决方案**：
- 检查波特率设置是否正确
- 确认设备驱动是否支持（某些设备可能需要特定驱动）
- 查看 logcat 日志获取详细错误信息

## 参考资料

- [usb_serial 库文档](https://pub.dev/packages/usb_serial)
- [Android USB Host API](https://developer.android.com/guide/topics/connectivity/usb/host)
- [flutter_libserialport 已知问题](https://github.com/jpnurmi/flutter_libserialport/issues)
