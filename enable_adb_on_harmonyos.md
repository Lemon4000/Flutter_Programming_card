# 在鸿蒙设备上启用ADB调试模式指南

## 问题背景
- 设备：华为鸿蒙（HarmonyOS）设备
- 当前状态：设备使用HDC协议，Flutter无法识别
- 目标：切换到ADB模式，使Flutter能够识别设备

## 解决步骤

### 1. 在鸿蒙设备上启用开发者选项
1. 打开**设置**
2. 进入**关于手机**
3. 连续点击**版本号** 7次，启用开发者选项

### 2. 进入开发者选项
1. 返回**设置**主界面
2. 找到**系统和更新**或**系统**
3. 点击**开发人员选项**

### 3. 切换调试模式
在开发人员选项中查找以下选项：

#### 选项A：USB调试模式选择（如果有）
- **"USB调试模式"** 或 **"调试模式选择"**
- 选择 **"ADB调试"** 或 **"Android调试"** 模式
- 不要选择"HDC"或"鸿蒙调试"模式

#### 选项B：仅启用USB调试
- 打开 **"USB调试"** 开关
- 同时打开 **"仅充电模式下允许ADB调试"**（如果有）

#### 选项C：HDC调试（如果只有这个）
- 先启用 **"HDC调试"**
- 查找是否有 **"允许ADB调试"** 选项并启用

### 4. 重新连接设备
1. 使用USB线连接设备到电脑
2. 在电脑上运行：
```bash
adb kill-server
adb start-server
adb devices
```

### 5. 验证设备识别
如果设备被识别，运行以下命令测试Flutter：
```bash
flutter devices
```

应该能看到您的设备出现在列表中。

## 常见问题

### Q1: 找不到ADB模式选项？
**A:** 某些新型号的鸿蒙设备可能完全移除了ADB支持。这种情况下：
- 使用Windows或Mac电脑（DevEco Studio只在Windows/Mac上可用）
- 或者使用其他Android设备进行开发测试

### Q2: 启用ADB模式后仍无法识别？
**A:** 尝试以下步骤：
```bash
# 1. 检查USB连接
lsusb | grep Huawei

# 2. 重启ADB服务
adb kill-server
adb start-server

# 3. 检查设备权限
sudo adb devices

# 4. 更换USB线或USB接口
```

### Q3: 设备显示为"unauthorized"？
**A:** 在设备上：
1. 断开USB连接
2. 重新进入开发者选项
3. 撤销USB调试授权
4. 重新连接，并在设备上允许调试

## 成功标志
运行以下命令应该能看到设备：
```bash
$ adb devices
List of devices attached
HWXXXX	device    # 您的设备ID

$ flutter devices
1 found device:
Huawei • XXXXXXXX • android-arm64 • HarmonyOS XX
```

## 相关资源
- 华为开发者文档：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hdc
- Flutter设备调试：https://flutter.dev/docs/development/devices

## 下一步
设备识别成功后，可以运行：
```bash
flutter run -d <device_id>
```
