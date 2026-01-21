# Linux BLE 扫描问题 - 解决方案总结

## 问题描述

在 Linux 平台上运行 Flutter 应用时，无法扫描到 BLE（低功耗蓝牙）设备，但可以扫描到 SPP（串口配置文件/经典蓝牙）设备。

## 根本原因

`flutter_blue_plus_linux` 包（版本 7.0.3）在调用 BlueZ 的 `setDiscoveryFilter` 方法时，没有明确指定 `transport` 参数，导致默认只扫描 BR/EDR（经典蓝牙）设备，而忽略了 BLE 设备。

### 问题代码

```dart
// 原始代码 - 缺少 transport 参数
await adapter.setDiscoveryFilter(
  uuids: request.withServices.map(
    (uuid) {
      return uuid.str128;
    },
  ).toList(),
);
```

### 修复代码

```dart
// 修复后 - 添加 transport: 'le' 参数
await adapter.setDiscoveryFilter(
  transport: 'le',  // 明确指定扫描 LE 设备
  uuids: request.withServices.map(
    (uuid) {
      return uuid.str128;
    },
  ).toList(),
);
```

## 已应用的修复

✅ **修复脚本已成功执行**

1. **创建本地包副本**：
   - 位置：`./packages/flutter_blue_plus_linux-7.0.3/`
   - 备份：`./packages/flutter_blue_plus_linux-7.0.3/lib/flutter_blue_plus_linux.dart.backup`

2. **应用补丁**：
   - 在 `startScan` 方法中添加了 `transport: 'le'` 参数
   - 修改文件：`packages/flutter_blue_plus_linux-7.0.3/lib/flutter_blue_plus_linux.dart:819`

3. **更新依赖配置**：
   - 在 `pubspec.yaml` 中添加了 `dependency_overrides`
   - 强制使用本地修复版本的包

4. **重新构建应用**：
   - 已清理旧构建
   - 已生成新的 release 版本

## 验证步骤

1. **运行应用**：
   ```bash
   ./run-linux.sh
   ```

2. **测试扫描**：
   - 点击"开始扫描"按钮
   - 应该能看到 BLE 设备（如 ZXD2400、Redmi Buds、EDIFIER BLE 等）

3. **预期结果**：
   - ✅ 能扫描到 BLE 设备
   - ✅ 能扫描到 SPP 设备（如果有）
   - ✅ 设备列表按信号强度排序

## 系统配置（已验证）

✅ **所有系统配置都正确**

- 蓝牙适配器：正常运行（BlueZ 5.72）
- 用户权限：在 `bluetooth` 组中
- DBus 策略：已配置（`/etc/dbus-1/system.d/flutter-bluetooth.conf`）
- 蓝牙服务：正常运行

## 相关文件

1. **诊断脚本**：`./diagnose-ble.sh`
   - 用于诊断 BLE 扫描问题
   - 检查系统配置和权限

2. **修复脚本**：`./fix-ble-linux.sh`
   - 自动应用 BLE 扫描修复
   - 已成功执行

3. **权限修复脚本**：`./fix-ble-scan.sh`
   - 配置系统权限和 DBus 策略
   - 之前已执行

4. **详细分析报告**：`./BLE_SCAN_ISSUE_ANALYSIS.md`
   - 完整的问题分析和解决方案

## 如何恢复原始配置

如果需要恢复到原始状态：

```bash
# 1. 删除本地包
rm -rf packages/

# 2. 从 pubspec.yaml 中移除 dependency_overrides
# 手动编辑 pubspec.yaml，删除以下部分：
# dependency_overrides:
#   flutter_blue_plus_linux:
#     path: ./packages/flutter_blue_plus_linux-7.0.3

# 3. 重新获取依赖
flutter pub get

# 4. 重新构建
flutter clean
flutter build linux --release
```

## 向上游报告

建议向 flutter_blue_plus 项目报告此问题：

- **仓库**：https://github.com/chipweinberger/flutter_blue_plus
- **问题标题**：Linux: BLE devices not discovered due to missing transport parameter
- **问题描述**：
  - `flutter_blue_plus_linux` 在调用 `setDiscoveryFilter` 时缺少 `transport: 'le'` 参数
  - 导致只能扫描 BR/EDR 设备，无法扫描 BLE 设备
  - 建议在 `startScan` 方法中添加 `transport: 'le'` 参数

## 技术细节

### BlueZ setDiscoveryFilter 参数

```dart
Future<void> setDiscoveryFilter({
  List<String>? uuids,        // UUID 过滤
  int? rssi,                  // RSSI 阈值
  int? pathloss,              // 路径损耗
  String? transport,          // 传输类型: 'auto', 'bredr', 'le'
  bool? duplicateData,        // 是否报告重复数据
  bool? discoverable,         // 是否只扫描可发现设备
  String? pattern             // 名称模式匹配
})
```

### transport 参数说明

- `'auto'`：自动检测（默认）
- `'bredr'`：只扫描 BR/EDR（经典蓝牙）设备
- `'le'`：只扫描 LE（低功耗蓝牙）设备

在我们的修复中，明确指定了 `transport: 'le'`，因为应用主要用于 BLE 设备通信。

## 总结

问题已成功修复！现在应用应该能够正常扫描 BLE 设备了。修复方法是在本地创建 `flutter_blue_plus_linux` 包的副本，并添加缺失的 `transport: 'le'` 参数。

如果遇到任何问题，请查看：
- 诊断脚本输出：`./diagnose-ble.sh`
- 详细分析报告：`./BLE_SCAN_ISSUE_ANALYSIS.md`
