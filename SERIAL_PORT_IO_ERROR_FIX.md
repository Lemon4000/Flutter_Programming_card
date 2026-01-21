# 串口I/O错误快速修复指南

## 问题描述

```
SerialPortError: 输入/输出错误, errno = 5
```

## ✅ 已修复

我已经将默认波特率从 **2000000** 降低到 **115200**，这应该能解决大多数USB转串口设备的兼容性问题。

## 🔧 修改内容

### 1. 串口连接波特率
**文件**: `lib/presentation/screens/scan_screen.dart`

```dart
// 修改前
await serialPortDatasource.connect(portName);  // 默认 2000000

// 修改后
await serialPortDatasource.connect(portName, baudRate: 115200);  // 降低到 115200
```

### 2. 增强错误处理
**文件**: `lib/data/datasources/serial_port_datasource.dart`

- ✅ 添加了详细的错误信息
- ✅ 检测I/O错误时自动清理连接
- ✅ 添加了串口状态验证
- ✅ 添加了配置信息日志

## 🚀 使用步骤

1. **重新编译应用**:
   ```bash
   flutter clean
   flutter pub get
   ./run-linux.sh
   ```

2. **运行诊断脚本**（可选）:
   ```bash
   ./diagnose-serial-port.sh
   ```

3. **连接串口**:
   - 切换到"串口"模式
   - 刷新串口列表
   - 连接设备

## 📊 波特率选择指南

根据您的设备和需求选择合适的波特率：

| 波特率 | 速度 | 兼容性 | 适用场景 |
|--------|------|--------|----------|
| 115200 | 慢 | ⭐⭐⭐⭐⭐ | 最佳兼容性（推荐） |
| 460800 | 中 | ⭐⭐⭐⭐ | 平衡选择 |
| 921600 | 快 | ⭐⭐⭐ | 高速传输 |
| 2000000 | 很快 | ⭐⭐ | 高端设备 |

### 如何修改波特率

如果需要更高速度，修改 `scan_screen.dart` 第300行：

```dart
await serialPortDatasource.connect(portName, baudRate: 921600);  // 尝试更高速度
```

## 🔍 其他可能的问题

### 1. 权限问题

```bash
# 添加用户到dialout组
sudo usermod -a -G dialout $USER

# 重新登录
logout
```

### 2. 设备被占用

```bash
# 检查占用
sudo fuser /dev/ttyUSB0

# 如果被占用，关闭占用的程序
```

### 3. USB设备不稳定

- 更换USB线缆
- 直接连接到电脑USB口（不用HUB）
- 检查USB设备驱动

### 4. 测试串口设备

```bash
# 使用minicom测试
sudo apt install minicom
sudo minicom -D /dev/ttyUSB0 -b 115200

# 按 Ctrl+A, Z, X 退出
```

## 📝 日志查看

运行应用时查看控制台输出：

```
正在连接串口: /dev/ttyUSB0 @ 115200 bps
串口已打开，正在配置参数...
串口配置: 波特率=115200, 数据位=8, 停止位=1
串口连接成功: /dev/ttyUSB0 @ 115200 bps
```

如果看到错误，会显示详细信息：
```
串口写入失败: SerialPortError: ... (errno: 5)
检测到串口I/O错误，可能设备已断开
```

## ✅ 验证修复

1. **重新运行应用**
2. **连接串口设备**
3. **进入调试页面**
4. **发送握手指令**
5. **观察是否成功**

如果仍然失败：
- 检查设备是否支持115200波特率
- 尝试使用minicom测试设备
- 查看 `dmesg` 内核日志
- 更换USB设备或线缆

## 🎯 预期结果

修复后应该看到：
```
✓ 串口连接成功
✓ 数据发送正常
✓ 可以进行烧录和调试
```

## 📞 如果问题仍然存在

1. 运行诊断脚本：`./diagnose-serial-port.sh`
2. 查看完整错误日志
3. 检查硬件连接
4. 尝试在其他电脑上测试设备

---

**修改时间**: 2026-01-21
**默认波特率**: 115200 bps
**状态**: ✅ 已修复
