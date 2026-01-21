# 连接状态保持 - 测试指南

## 已实现的修复

### 1. 全局状态管理
创建了 `mock_providers.dart`，包含：
- `mockBluetoothProvider` - 全局蓝牙数据源（单例）
- `connectionStateProvider` - 连接状态
- `connectedDeviceIdProvider` - 已连接设备ID
- `connectedDeviceNameProvider` - 已连接设备名称

### 2. 顶部状态栏
在主界面的AppBar中添加了连接状态显示：
- 未连接：只显示"编程卡上位机"
- 已连接：显示"编程卡上位机" + 绿色标签（蓝牙图标 + 设备名称）

### 3. 页面状态同步
在 `MockScanScreen` 中：
- `initState()` - 初始化时检查连接状态
- `didChangeDependencies()` - 每次页面显示时检查连接状态
- 使用 `ref.watch()` 监听全局状态变化

## 测试步骤

### 测试1：基本连接
1. 打开应用（设备页面）
2. 点击"开始扫描"
3. 等待发现3个模拟设备
4. 点击任意设备的"连接"按钮
5. 等待2秒连接完成

**预期结果：**
- ✅ 显示"已连接到 编程卡-XXX"的绿色提示
- ✅ 顶部出现绿色连接标签
- ✅ 设备页面顶部显示绿色状态栏
- ✅ 已连接的设备显示"已连接"标签

### 测试2：切换页面保持连接
1. 在设备页面连接到设备（参考测试1）
2. 点击底部导航栏的"参数"标签
3. 观察顶部标题栏
4. 点击底部导航栏的"烧录"标签
5. 观察顶部标题栏
6. 点击底部导航栏的"日志"标签
7. 观察顶部标题栏
8. 返回"设备"标签

**预期结果：**
- ✅ 在所有页面，顶部都显示绿色连接标签
- ✅ 返回设备页面时，仍显示绿色连接状态栏
- ✅ 已连接的设备仍显示"已连接"标签
- ✅ 终端日志持续显示"[Mock] 模拟接收数据"（每5秒一次）

### 测试3：断开连接
1. 在任意页面（连接状态下）
2. 返回设备页面
3. 点击绿色状态栏中的"断开"按钮

**预期结果：**
- ✅ 显示"已断开连接"提示
- ✅ 顶部绿色连接标签消失
- ✅ 设备页面绿色状态栏消失
- ✅ 设备列表中的"已连接"标签变回"连接"按钮
- ✅ 终端日志停止显示"[Mock] 模拟接收数据"

## 验证方法

### 方法1：观察UI
- **顶部标题栏**：是否显示绿色连接标签
- **设备页面**：是否显示绿色状态栏
- **设备列表**：已连接设备是否显示"已连接"标签

### 方法2：查看日志
```bash
tail -f /tmp/flutter_run.log | grep Mock
```

**连接成功的日志：**
```
[Mock] 正在连接设备: mock-device-001
[Mock] 连接成功: 编程卡-001
[Mock] 模拟接收数据  # 每5秒出现一次
[Mock] 模拟接收数据
[Mock] 模拟接收数据
...
```

**断开连接的日志：**
- 停止出现"[Mock] 模拟接收数据"

### 方法3：检查状态Provider
在代码中添加调试输出（已添加）：
```dart
print('[UI] 检查连接状态: isConnected=$isConnected, deviceId=$deviceId');
```

## 常见问题

### Q1: 切换页面后顶部标签消失了
**原因：** 可能是热重载导致状态丢失

**解决：**
1. 重新连接设备
2. 或者完全重启应用（按 `R` 键）

### Q2: 返回设备页面时状态栏不显示
**原因：** `didChangeDependencies` 可能没有触发

**解决：**
1. 检查是否使用了 `ConsumerStatefulWidget`
2. 确认 `ref.watch()` 正确使用
3. 查看终端日志确认连接是否真的保持

### Q3: 日志显示连接但UI不显示
**原因：** 状态同步问题

**解决：**
1. 检查 `_checkConnectionState()` 是否被调用
2. 确认 Provider 状态是否正确更新
3. 尝试热重启（按 `R` 键）

## 技术实现细节

### 状态流转
```
连接设备
  ↓
更新 mockBluetoothProvider (底层连接)
  ↓
更新 connectionStateProvider (UI状态)
  ↓
更新 connectedDeviceIdProvider (设备ID)
  ↓
更新 connectedDeviceNameProvider (设备名称)
  ↓
所有页面通过 ref.watch() 监听状态变化
  ↓
UI自动更新
```

### 关键代码位置

**全局Provider定义：**
`lib/presentation/providers/mock_providers.dart`

**主界面状态显示：**
`lib/presentation/screens/home_screen.dart` - AppBar

**设备页面状态同步：**
`lib/presentation/screens/mock_scan_screen.dart` - didChangeDependencies()

**蓝牙数据源：**
`lib/data/datasources/simple_mock_bluetooth_datasource.dart`

## 当前状态

✅ **已修复**：连接状态现在保存在全局Provider中
✅ **已实现**：顶部标题栏显示连接状态
✅ **已实现**：页面切换时状态保持
✅ **已实现**：返回设备页面时状态同步

## 下一步

如果仍然遇到问题，请：
1. 完全重启应用（关闭并重新运行 `flutter run`）
2. 清理并重新构建：`flutter clean && flutter run`
3. 检查终端日志确认连接状态
4. 提供具体的错误信息或截图
