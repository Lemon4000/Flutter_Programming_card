# Android USB 串口修复完成

## 问题

在 Android 手机上运行应用时，获取串口列表失败，报错：
```
SerialPortError: Permission denied errno = 13
```

## 根本原因

`flutter_libserialport` 库不支持 Android 平台的 USB Host API。该库主要为桌面平台（Linux、Windows、macOS）设计，在 Android 上无法访问 USB 串口设备。

## 解决方案

创建了跨平台串口数据源适配器，在 Android 上使用 `usb_serial` 库，在桌面平台继续使用 `flutter_libserialport`。

### 修改的文件

1. **pubspec.yaml**
   - 添加 `usb_serial: ^0.5.2` 依赖

2. **新增文件**
   - `lib/data/datasources/usb_serial_datasource.dart` - Android USB 串口数据源
   - `lib/data/datasources/cross_platform_serial_datasource.dart` - 跨平台适配器
   - `android/app/src/main/res/xml/device_filter.xml` - USB 设备过滤器

3. **android/app/src/main/AndroidManifest.xml**
   - 添加 USB Host 权限
   - 添加 USB 设备连接 intent-filter
   - 添加 USB 设备过滤器配置

4. **lib/presentation/providers/providers.dart**
   - 添加 `crossPlatformSerialDatasourceProvider`

5. **lib/presentation/screens/scan_screen.dart**
   - 更新串口列表加载逻辑使用跨平台数据源
   - 更新串口连接逻辑
   - 更新 UI 显示设备信息

## 使用方法

### 在 Android 上

1. 连接 USB OTG 转串口设备到 Android 手机
2. 打开应用
3. 切换到"串口"模式
4. 点击"刷新串口列表"
5. 系统会弹出 USB 权限请求对话框
6. 点击"允许"授权应用访问 USB 设备
7. 选择设备并点击"连接"

### 在桌面平台上

桌面平台的使用方式保持不变，继续使用 `flutter_libserialport`。

## 支持的 USB 转串口芯片

已在 `device_filter.xml` 中配置了常见的 USB 转串口芯片：

- CH340/CH341 系列（最常见）
- FTDI 系列（FT232、FT2232 等）
- CP210x 系列（Silicon Labs）
- PL2303 系列（Prolific）
- CDC ACM 设备（通用 USB 串口）

## 测试

1. 构建成功：✅
   ```
   ✓ Built build/app/outputs/flutter-apk/app-release.apk (23.0MB)
   ```

2. 下一步：在 Android 设备上测试
   - 安装 APK
   - 连接 USB OTG 转串口设备
   - 测试设备列表获取
   - 测试设备连接
   - 测试数据收发

## 参考文档

详细的使用说明和故障排除请参考：`USB_SERIAL_FIX.md`
