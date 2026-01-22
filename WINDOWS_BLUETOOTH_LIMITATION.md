# Windows 版本蓝牙限制说明

## 问题描述

在 Windows EXE 版本中，点击"蓝牙"标签页并开始扫描时，会出现以下错误：

```
设备错误：exception 蓝牙扫描失败
unsupported operation
flutter_blue_plus is unsupported on this platform
```

## 原因

`flutter_blue_plus` 库不支持 Windows 桌面平台。该库仅支持：
- ✅ Android
- ✅ iOS
- ✅ macOS
- ✅ Linux（部分支持）
- ❌ Windows（不支持）

## 解决方案

### 已实施的修复

在 Windows 版本中，当用户尝试使用蓝牙功能时：

1. **阻止扫描操作**
   - 检测到 Windows 平台时，不执行蓝牙扫描
   - 显示友好的错误提示

2. **显示提示对话框**
   ```
   Windows 桌面版本不支持蓝牙功能。

   请使用以下方式连接设备：
   • 串口连接：点击"串口"标签页
   • 蓝牙连接：在 Android 或 iOS 设备上使用
   ```

3. **引导用户使用串口**
   - 提示用户切换到"串口"标签页
   - 串口功能在 Windows 上完全支持

## 平台功能对比

| 功能 | Windows | Linux | Android | iOS |
|------|---------|-------|---------|-----|
| 蓝牙扫描 | ❌ | ⚠️ | ✅ | ✅ |
| 蓝牙连接 | ❌ | ⚠️ | ✅ | ✅ |
| 串口连接 | ✅ | ✅ | ✅ | ❌ |
| USB 串口 | ✅ | ✅ | ✅ | ❌ |

说明：
- ✅ 完全支持
- ⚠️ 部分支持（可能不稳定）
- ❌ 不支持

## 使用建议

### Windows 用户

**推荐方式：使用串口连接**

1. 将设备通过 USB 连接到电脑
2. 打开应用程序
3. 点击"串口"标签页
4. 点击"刷新串口列表"
5. 选择对应的 COM 口
6. 点击"连接"

**如需使用蓝牙：**
- 使用 Android 版本（APK）
- 使用 iOS 版本（如果有）

### Linux 用户

蓝牙功能可能不稳定，建议：
1. 优先使用串口连接
2. 如需使用蓝牙，请确保系统蓝牙服务正常运行

### Android/iOS 用户

- ✅ 蓝牙功能完全支持
- ✅ USB 串口支持（Android）
- 推荐使用蓝牙连接，体验最佳

## 技术细节

### 为什么 Windows 不支持蓝牙？

1. **Flutter Blue Plus 限制**
   - 该库基于平台特定的蓝牙 API
   - Windows 没有统一的蓝牙 API 支持
   - 需要使用 Windows Bluetooth API，但库未实现

2. **替代方案**
   - Windows 上可以使用串口（COM 口）
   - 串口通信更稳定可靠
   - 支持所有 USB 转串口设备

### 代码修改

在 `lib/presentation/screens/scan_screen.dart` 中添加了平台检查：

```dart
// 检查平台支持 - Windows 不支持蓝牙
if (!kIsWeb && Platform.isWindows) {
  setState(() {
    _errorMessage = 'Windows 桌面版本不支持蓝牙功能。\n请使用串口连接或在 Android/iOS 设备上使用蓝牙功能。';
    _isScanning = false;
  });

  // 显示提示对话框
  showDialog(...);
  return;
}
```

## 常见问题

### Q: Windows 版本能否支持蓝牙？

A: 目前不支持。需要等待 `flutter_blue_plus` 库添加 Windows 支持，或使用其他蓝牙库。

### Q: 串口连接和蓝牙连接有什么区别？

A:
- **串口连接**：通过 USB 线连接，更稳定，速度快
- **蓝牙连接**：无线连接，方便移动，但可能受信号影响

### Q: 如何在 Windows 上使用蓝牙功能？

A: 有以下选择：
1. 使用 Android 模拟器运行 APK 版本
2. 使用 Android 手机/平板运行 APK 版本
3. 等待未来版本支持 Windows 蓝牙

### Q: 串口连接需要什么硬件？

A:
- USB 转串口线（如 CH340、CP2102、FTDI）
- 或设备本身支持 USB 串口模式

## 相关文档

- `USB_SERIAL_FIX.md` - Android USB 串口修复
- `COMMUNICATION_REPOSITORY_FIX.md` - 通信仓库集成
- `AUTO_RELEASE_SUCCESS.md` - 自动构建和发布

## 更新日志

- **2026-01-22**: 添加 Windows 平台蓝牙限制检查和友好提示
- **2026-01-21**: 实现跨平台串口支持（Android + 桌面）
- **2026-01-17**: 初始版本，支持 Android 蓝牙

## 总结

- ✅ Windows 版本已修复蓝牙错误提示
- ✅ 用户会看到清晰的说明和替代方案
- ✅ 串口功能在 Windows 上完全可用
- ✅ Android/iOS 版本蓝牙功能正常

**Windows 用户请使用串口连接，Android/iOS 用户可以使用蓝牙连接。**
