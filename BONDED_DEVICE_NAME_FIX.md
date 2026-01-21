# 已配对设备名称显示修复

## 问题描述

运行应用后，已配对的蓝牙设备（如 LMNB 和 ThinkBook Bluetooth Mouse）在扫描列表中显示为"未知设备"，即使系统日志显示这些设备已被识别。

## 根本原因

**MAC地址格式大小写不匹配**

代码在两个地方使用 `device.remoteId.toString()` 获取设备ID：
1. 获取已配对设备时（`bluetooth_datasource.dart`）
2. 扫描设备时（`device_info.dart`）

在Linux平台上，`remoteId.toString()` 可能返回不同大小写的MAC地址：
- 已配对设备：`50:F7:ED:36:79:B4`（大写）
- 扫描结果：`50:f7:ed:36:79:b4`（小写）

这导致在 `device_repository_impl.dart:38` 中的查找失败：
```dart
if (finalName == '未知设备' && bondedNames.containsKey(deviceInfo.id)) {
  finalName = bondedNames[deviceInfo.id]!;
}
```

因为 `bondedNames` 的键是大写格式，而 `deviceInfo.id` 是小写格式，`containsKey()` 返回 `false`。

## 解决方案

**统一将所有设备ID转换为小写格式**

修改了以下文件：

### 1. `lib/data/datasources/bluetooth_datasource.dart:77`
```dart
// 修改前
final id = device.remoteId.toString();

// 修改后
final id = device.remoteId.toString().toLowerCase(); // 统一转换为小写
```

### 2. `lib/data/models/device_info.dart`

在 `fromScanResult` 方法中（第50行）：
```dart
// 修改前
id: result.device.remoteId.toString(),

// 修改后
id: result.device.remoteId.toString().toLowerCase(), // 统一转换为小写
```

在 `fromDevice` 方法中（第68行和第73行）：
```dart
// 修改前
final macAddress = device.remoteId.toString();
// ...
id: device.remoteId.toString(),

// 修改后
final macAddress = device.remoteId.toString().toLowerCase(); // 统一转换为小写
// ...
id: device.remoteId.toString().toLowerCase(), // 统一转换为小写
```

### 3. `lib/data/repositories/device_repository_impl.dart`

在设备缓存处（第26行）：
```dart
// 修改前
_scannedDevices[result.device.remoteId.toString()] = result.device;

// 修改后
_scannedDevices[result.device.remoteId.toString().toLowerCase()] = result.device; // 统一转换为小写
```

在连接检查处（第78行）：
```dart
// 修改前
if (currentDevice != null &&
    currentDevice.remoteId.toString() == deviceId) {

// 修改后
if (currentDevice != null &&
    currentDevice.remoteId.toString().toLowerCase() == deviceId.toLowerCase()) { // 统一转换为小写比较
```

在获取已连接设备处（第120行）：
```dart
// 修改前
id: device.remoteId.toString(),

// 修改后
id: device.remoteId.toString().toLowerCase(), // 统一转换为小写
```

## 验证步骤

1. **重新构建应用**：
   ```bash
   flutter build linux --release
   ```

2. **运行应用**：
   ```bash
   ./run-linux.sh
   ```

3. **测试扫描**：
   - 点击"开始扫描"按钮
   - 已配对的设备（LMNB、ThinkBook Bluetooth Mouse）应该显示正确的名称
   - 不再显示为"未知设备"

## 预期结果

✅ 已配对设备显示正确的名称（如 "LMNB"、"ThinkBook Bluetooth Mouse"）
✅ 未配对的BLE设备仍然显示为"未知设备"（这是正常的）
✅ 设备连接功能正常工作

## 技术细节

### 为什么会出现大小写不匹配？

在Linux平台上，Flutter Blue Plus使用BlueZ的D-Bus API。不同的API调用可能返回不同格式的MAC地址：
- `bondedDevices`：可能返回大写格式
- `scanResults`：可能返回小写格式

这是平台特定的行为，在其他平台（如Windows、macOS）上可能不会出现。

### 为什么选择小写？

1. **一致性**：小写是更常见的MAC地址表示格式
2. **兼容性**：大多数网络工具和协议使用小写
3. **简单性**：只需要调用 `.toLowerCase()`，不需要额外的格式化逻辑

## 相关问题

这个问题只影响已配对设备的名称显示。对于未配对的BLE设备：
- 如果设备广播了名称（`advertisementData.advName`），会正确显示
- 如果设备没有广播名称，会显示为"未知设备"（这是预期行为）

## 总结

通过统一将所有设备ID转换为小写格式，解决了已配对设备名称显示为"未知设备"的问题。这是一个简单但有效的修复，确保了设备ID在整个应用中的一致性。
