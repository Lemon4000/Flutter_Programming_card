# Linux 平台 BLE 扫描问题分析报告

## 问题描述

在 Linux 平台上，应用无法扫描到 BLE（低功耗蓝牙）设备，但可以扫描到 SPP（串口配置文件/经典蓝牙）设备。

## 诊断结果

### 系统层面 ✅

1. **蓝牙适配器**：正常运行
   - 适配器地址：74:3A:F4:F1:8D:B6
   - BlueZ 版本：5.72（满足要求 ≥ 5.50）
   - 支持 LE 和 BR/EDR

2. **用户权限**：已正确配置
   - 用户在 `bluetooth` 组中
   - DBus 策略文件已创建：`/etc/dbus-1/system.d/flutter-bluetooth.conf`

3. **bluetoothctl 测试**：✅ 成功
   - LE 扫描：可以发现多个 BLE 设备（ZXD2400、Redmi Buds、EDIFIER BLE 等）
   - BR/EDR 扫描：可以发现 SPP 设备（KT6368A-SPP-2.1）

### 应用层面 ❌

**根本原因**：`flutter_blue_plus_linux` 包的实现问题

#### 问题代码位置

文件：`~/.pub-cache/hosted/pub.dev/flutter_blue_plus_linux-7.0.3/lib/flutter_blue_plus_linux.dart`

第 807-829 行的 `startScan` 方法：

```dart
@override
Future<bool> startScan(
  BmScanSettings request,
) async {
  await _initFlutterBluePlus();

  final adapter = _client.adapters.firstOrNull;

  if (adapter == null) {
    return false;
  }

  await adapter.setDiscoveryFilter(
    uuids: request.withServices.map(
      (uuid) {
        return uuid.str128;
      },
    ).toList(),
  );

  await adapter.startDiscovery();

  return true;
}
```

#### 问题分析

1. **过滤器设置不当**：
   - 当 `request.withServices` 为空时（默认情况），`setDiscoveryFilter` 会传入空的 UUID 列表
   - BlueZ 的 `setDiscoveryFilter` 在接收到空 UUID 列表时，可能会应用默认过滤规则
   - 这可能导致只扫描 BR/EDR 设备，而忽略 BLE 设备

2. **缺少传输类型过滤**：
   - BlueZ 的 `setDiscoveryFilter` 支持 `transport` 参数（`auto`、`bredr`、`le`）
   - 当前实现没有明确指定传输类型，导致可能默认为 `bredr`

3. **与 bluetoothctl 的对比**：
   - `bluetoothctl scan le`：明确指定扫描 LE 设备 → 成功
   - `bluetoothctl scan bredr`：明确指定扫描 BR/EDR 设备 → 成功
   - flutter_blue_plus：没有明确指定 → 只扫描到 BR/EDR

## 解决方案

### 方案 1：修改 flutter_blue_plus_linux 包（推荐）

需要修改 `startScan` 方法，明确指定扫描 LE 设备：

```dart
@override
Future<bool> startScan(
  BmScanSettings request,
) async {
  await _initFlutterBluePlus();

  final adapter = _client.adapters.firstOrNull;

  if (adapter == null) {
    return false;
  }

  // 明确设置为扫描 LE 设备
  await adapter.setDiscoveryFilter(
    transport: 'le',  // 添加这一行
    uuids: request.withServices.map(
      (uuid) {
        return uuid.str128;
      },
    ).toList(),
  );

  await adapter.startDiscovery();

  return true;
}
```

**实施步骤**：

1. 复制包到本地：
   ```bash
   cp -r ~/.pub-cache/hosted/pub.dev/flutter_blue_plus_linux-7.0.3 ./packages/
   ```

2. 修改 `pubspec.yaml`，使用本地包：
   ```yaml
   dependency_overrides:
     flutter_blue_plus_linux:
       path: ./packages/flutter_blue_plus_linux-7.0.3
   ```

3. 修改包代码（见上述代码）

4. 运行 `flutter pub get`

### 方案 2：向上游报告问题

1. 在 flutter_blue_plus GitHub 仓库创建 Issue
2. 提供详细的诊断信息和复现步骤
3. 等待官方修复

### 方案 3：使用替代方案（临时）

如果需要快速解决，可以考虑：

1. **直接使用 bluez.dart 包**：
   - flutter_blue_plus_linux 底层使用的就是 bluez.dart
   - 可以直接调用 bluez.dart 的 API，明确指定扫描参数

2. **使用 Platform Channel**：
   - 创建自定义的 Linux 平台通道
   - 直接调用 BlueZ D-Bus API

## 验证方法

修复后，运行以下测试：

```bash
# 1. 清理并重新构建
flutter clean
flutter pub get
flutter build linux --release

# 2. 运行应用
./run-linux.sh

# 3. 在应用中点击"开始扫描"，应该能看到 BLE 设备
```

## 相关资源

- [flutter_blue_plus GitHub](https://github.com/chipweinberger/flutter_blue_plus)
- [bluez.dart 包](https://pub.dev/packages/bluez)
- [BlueZ D-Bus API 文档](https://git.kernel.org/pub/scm/bluetooth/bluez.git/tree/doc)

## 总结

问题不在于系统配置（已完全正确），而在于 `flutter_blue_plus_linux` 包的实现缺陷。该包在调用 BlueZ 的 `setDiscoveryFilter` 时没有明确指定传输类型，导致默认只扫描 BR/EDR 设备。

**建议**：采用方案 1 进行本地修复，同时向上游报告问题。
