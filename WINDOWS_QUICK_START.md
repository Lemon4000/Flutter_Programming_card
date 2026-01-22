# Windows 版本快速使用指南

## ✅ 已修复问题

**蓝牙扫描错误已修复！**

之前的错误：
```
设备错误：exception 蓝牙扫描失败
unsupported operation
flutter_blue_plus is unsupported on this platform
```

现在会显示友好提示，引导您使用串口连接。

## 🚀 Windows 版本使用方法

### 方式 1：串口连接（推荐）

1. **连接设备**
   - 使用 USB 线连接设备到电脑
   - 等待驱动安装完成

2. **打开应用**
   - 运行 `programming_card_host.exe`

3. **连接串口**
   - 点击"串口"标签页
   - 点击"刷新串口列表"
   - 选择对应的 COM 口（如 COM3）
   - 设置波特率（默认 2000000）
   - 点击"连接"

4. **开始使用**
   - 连接成功后即可使用所有功能
   - 参数读写、烧录、调试等

### 方式 2：蓝牙连接（不支持）

Windows 版本**不支持蓝牙功能**。

如需使用蓝牙：
- 使用 Android APK 版本
- 或使用 iOS 版本（如果有）

## 📥 下载最新版本

访问：https://github.com/Lemon4000/Flutter_Programming_card/releases

下载文件：
- **Windows**: `ProgrammingCardHost_v1.0.0+1_Windows_x64.zip`
- **Android**: `ProgrammingCardHost_v1.0.0+1_Android.apk`
- **Linux**: `ProgrammingCardHost_v1.0.0+1_Linux_x64.tar.gz`

## 🔧 常见问题

### Q: 找不到串口？

**解决方法：**
1. 检查 USB 线是否连接
2. 检查设备是否开机
3. 安装 CH340/CP2102 驱动
4. 在设备管理器中查看 COM 口

### Q: 连接失败？

**解决方法：**
1. 确认选择了正确的 COM 口
2. 确认波特率设置正确（2000000）
3. 关闭其他占用串口的程序
4. 重新插拔 USB 线

### Q: 为什么不支持蓝牙？

**原因：**
- Flutter Blue Plus 库不支持 Windows 平台
- Windows 没有统一的蓝牙 API

**替代方案：**
- 使用串口连接（更稳定）
- 或使用 Android 版本

### Q: 如何安装串口驱动？

**CH340 驱动：**
1. 下载：http://www.wch.cn/downloads/CH341SER_EXE.html
2. 运行安装程序
3. 重启电脑

**CP2102 驱动：**
1. 下载：https://www.silabs.com/developers/usb-to-uart-bridge-vcp-drivers
2. 运行安装程序
3. 重启电脑

## 📱 Android 版本使用

如果您需要使用蓝牙功能：

1. **下载 APK**
   - 从 Releases 页面下载 Android APK

2. **安装**
   - 允许安装未知来源应用
   - 安装 APK

3. **使用蓝牙**
   - 打开应用
   - 点击"蓝牙"标签页
   - 点击"开始扫描"
   - 选择设备并连接

4. **使用 USB 串口**
   - Android 也支持 USB 串口
   - 使用 OTG 线连接设备
   - 点击"串口"标签页
   - 选择 USB 设备并连接

## 🎯 功能对比

| 功能 | Windows | Android |
|------|---------|---------|
| 串口连接 | ✅ | ✅ |
| USB 串口 | ✅ | ✅ |
| 蓝牙连接 | ❌ | ✅ |
| 参数读写 | ✅ | ✅ |
| 固件烧录 | ✅ | ✅ |
| 调试模式 | ✅ | ✅ |

## 📚 详细文档

- `WINDOWS_BLUETOOTH_LIMITATION.md` - Windows 蓝牙限制详细说明
- `USB_SERIAL_FIX.md` - Android USB 串口使用
- `AUTO_RELEASE_SUCCESS.md` - 自动构建和下载

## 💡 使用建议

### Windows 用户
- ✅ 使用串口连接
- ✅ 稳定可靠
- ✅ 速度快

### Android 用户
- ✅ 蓝牙连接方便
- ✅ USB 串口也支持
- ✅ 功能最完整

### 需要移动使用
- ✅ 使用 Android 蓝牙版本
- ✅ 无需连线
- ✅ 方便携带

## 🔄 更新说明

**最新版本**: v1.0.0

**更新内容**:
- ✅ 修复 Windows 蓝牙错误提示
- ✅ 添加友好的平台限制说明
- ✅ 完善串口连接功能
- ✅ 自动构建和发布

**下次更新**:
- 每次推送代码后约 10 分钟
- 自动创建新的 Release
- 访问 Releases 页面下载

## 📞 支持

如有问题，请：
1. 查看相关文档
2. 检查 GitHub Issues
3. 提交新的 Issue

---

**Windows 版本使用串口连接，Android 版本支持蓝牙和串口！** 🚀
