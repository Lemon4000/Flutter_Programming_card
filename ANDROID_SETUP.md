# Android设备连接指南

## 当前状态
- ✅ Android手机已连接
- ❌ ADB (Android Debug Bridge) 未安装
- ❌ Flutter无法识别Android设备

## 解决方案

### 方法1：安装Android SDK Platform Tools（推荐）

```bash
# 1. 安装ADB
sudo apt update
sudo apt install android-tools-adb android-tools-fastboot

# 2. 验证安装
adb version

# 3. 启动ADB服务
adb start-server

# 4. 检查设备连接
adb devices
```

### 方法2：使用Flutter自带的Android SDK

如果你已经安装了Android Studio，Flutter应该能找到Android SDK：

```bash
# 检查Flutter配置
flutter doctor -v

# 查看Android SDK路径
flutter config --android-sdk
```

## 设置Android设备

### 1. 启用开发者选项
1. 打开手机"设置"
2. 找到"关于手机"
3. 连续点击"版本号"7次
4. 返回设置，找到"开发者选项"

### 2. 启用USB调试
1. 进入"开发者选项"
2. 开启"USB调试"
3. 开启"USB安装"（如果有）

### 3. 连接手机
1. 用USB线连接手机到电脑
2. 手机上会弹出"允许USB调试"提示
3. 勾选"始终允许"
4. 点击"允许"

### 4. 验证连接

```bash
# 安装ADB后运行
adb devices

# 应该看到类似输出：
# List of devices attached
# XXXXXXXXXX    device
```

### 5. 运行Flutter应用

```bash
# 进入项目目录
cd /home/lemon/桌面/docs/plans/flutter

# 查看设备
flutter devices

# 运行应用
flutter run
```

## 快速安装ADB

```bash
# 一键安装
sudo apt install -y android-tools-adb android-tools-fastboot

# 启动ADB
adb start-server

# 检查设备
adb devices
```

## 常见问题

### Q1: adb devices显示"unauthorized"
**解决：**
1. 断开USB连接
2. 在手机上撤销USB调试授权（开发者选项 -> 撤销USB调试授权）
3. 重新连接USB
4. 在手机上重新授权

### Q2: adb devices显示"no permissions"
**解决：**
```bash
# 添加udev规则
sudo usermod -aG plugdev $USER
sudo apt install android-sdk-platform-tools-common

# 重启ADB
adb kill-server
adb start-server
```

### Q3: flutter devices看不到Android设备
**解决：**
```bash
# 1. 确认ADB能看到设备
adb devices

# 2. 重启Flutter
flutter doctor

# 3. 如果还是不行，重启电脑
```

## 在Android上运行应用的优势

### vs Linux桌面模拟模式

| 功能 | Linux模拟 | Android真机 |
|------|----------|------------|
| 蓝牙扫描 | ❌ 模拟数据 | ✅ 真实扫描 |
| 设备连接 | ❌ 模拟连接 | ✅ 真实连接 |
| 数据通信 | ❌ 模拟数据 | ✅ 真实通信 |
| 参数读写 | ❌ 无法测试 | ✅ 完整测试 |
| 固件烧录 | ❌ 无法测试 | ✅ 完整测试 |
| UI测试 | ✅ 可以测试 | ✅ 可以测试 |

## 下一步

安装ADB后：

1. **验证连接**
   ```bash
   adb devices
   ```

2. **运行应用**
   ```bash
   cd /home/lemon/桌面/docs/plans/flutter
   flutter run
   ```

3. **测试真实蓝牙**
   - 扫描真实的蓝牙设备
   - 连接到编程卡
   - 测试参数读写
   - 测试固件烧录

## 临时方案

如果暂时无法安装ADB，可以继续在Linux上使用模拟模式开发UI：

```bash
cd /home/lemon/桌面/docs/plans/flutter
flutter run -d linux
```

但要测试完整的蓝牙功能，必须在Android设备上运行。
