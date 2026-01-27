# Bug 修复进度报告

## 已修复的问题

### ✅ 问题 2: 连接后显示"设备连接已断开"

**修改文件**: `lib/presentation/screens/home_screen.dart`

**修复内容**:
1. 添加 `_isInitialConnection` 标志来跟踪是否是初始连接
2. 忽略初始的 `disconnected` 状态（这是 Stream 的初始值）
3. 只在真正断开连接时显示提示

**代码变更**:
```dart
// 添加标志
bool _isInitialConnection = true;

// 在监听器中过滤初始状态
if (_isInitialConnection && !isConnected) {
  _isInitialConnection = false;
  return;  // 忽略初始的断开状态
}
```

**测试状态**: ✅ 已修复

---

### ✅ 问题 1: Android 设备重连后黑屏（部分修复）

**修改文件**: `lib/presentation/screens/home_screen.dart`

**修复内容**:
1. 在断开连接时重置 `_isInitialConnection` 标志
2. 为下次连接做好准备

**代码变更**:
```dart
Future<void> _disconnectDevice() async {
  // ... 断开连接逻辑 ...

  // 重置初始连接标志，为下次连接做准备
  _isInitialConnection = true;

  // ... 其他代码 ...
}
```

**测试状态**: ⚠️ 需要在 Android 设备上测试

**注意**: 黑屏问题可能还需要额外的修复，建议：
1. 检查是否有多个连接状态监听器
2. 确保 Provider 状态正确重置
3. 检查导航栈是否正常

---

## 待修复的问题

### ⏳ 问题 3: 烧录无法停止

**问题分析**:
- `FlashWorker` 有 `abort()` 方法
- 但 UI 上没有"停止烧录"按钮
- 烧录过程中按钮一直显示"开始烧录"

**需要的修改**:

1. **修改 `flash_screen.dart`**:
   - 添加 `FlashWorker?` 成员变量来保存当前的 worker 实例
   - 修改按钮逻辑：烧录中显示"停止烧录"
   - 添加 `_stopFlashing()` 方法调用 `worker.abort()`

2. **修改 `_buildActionButtonSection`**:
```dart
// 判断是否正在烧录
final bool isFlashing = progress.status == FlashStatus.flashing ||
                        progress.status == FlashStatus.initializing ||
                        progress.status == FlashStatus.erasing ||
                        progress.status == FlashStatus.programming ||
                        progress.status == FlashStatus.verifying;

if (isFlashing) {
  buttonText = '停止烧录';
  buttonIcon = Icons.stop_rounded;
  buttonColor = Colors.red.shade600;
  onPressed = _stopFlashing;
} else if (isFailed) {
  // ... 重试逻辑 ...
}
```

3. **添加停止方法**:
```dart
void _stopFlashing() {
  _flashWorker?.abort();
  ref.read(flashProgressProvider.notifier).state =
    FlashProgress.cancelled(startTime: DateTime.now());
}
```

4. **保存 worker 实例**:
```dart
FlashWorker? _flashWorker;

Future<void> _startFlashing() async {
  // ... 创建 worker ...
  _flashWorker = FlashWorker(...);

  // ... 开始烧录 ...
  final result = await _flashWorker!.startFlashWithBlocks(...);

  // 完成后清空
  _flashWorker = null;
}
```

---

### ⏳ 问题 4: 参数界面不保存之前的值

**问题分析**:
- 参数状态可能每次都重新初始化
- 需要使用持久化的 Provider

**需要的修改**:

1. **创建参数状态 Provider** (`lib/presentation/providers/parameter_providers.dart`):
```dart
/// 参数状态 Provider（持久化）
final parametersStateProvider = StateProvider<Map<String, dynamic>>((ref) => {});

/// 原始参数值 Provider（用于比较）
final originalParametersProvider = StateProvider<Map<String, dynamic>>((ref) => {});
```

2. **修改 `parameter_screen.dart`**:
   - 读取参数后保存到 `parametersStateProvider`
   - 同时保存到 `originalParametersProvider`（用于差异比较）
   - 界面显示 `parametersStateProvider` 的值
   - 修改参数时更新 `parametersStateProvider`

---

### ⏳ 问题 5: 参数修改无差异性显示

**需要的修改**:

1. **添加差异比较逻辑**:
```dart
bool isParameterModified(String key, dynamic currentValue) {
  final original = ref.watch(originalParametersProvider);
  return original[key] != currentValue;
}
```

2. **修改参数显示 Widget**:
```dart
// 如果参数被修改，显示不同的颜色
final isModified = isParameterModified(param.key, param.value);

Container(
  decoration: BoxDecoration(
    border: Border.all(
      color: isModified ? Colors.orange : Colors.grey,
      width: isModified ? 2 : 1,
    ),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Row(
    children: [
      if (isModified)
        Icon(Icons.edit, color: Colors.orange, size: 16),
      // ... 参数内容 ...
    ],
  ),
)
```

3. **添加"恢复默认"按钮**:
```dart
IconButton(
  icon: Icon(Icons.restore),
  onPressed: isModified ? () {
    // 恢复到原始值
    final original = ref.read(originalParametersProvider);
    ref.read(parametersStateProvider.notifier).update((state) {
      return {...state, param.key: original[param.key]};
    });
  } : null,
)
```

---

## 下一步行动

### 立即修复（高优先级）:
1. ✅ 完成烧录停止功能
2. ✅ 在 Android 设备上测试重连问题

### 后续改进（中优先级）:
3. ✅ 实现参数持久化
4. ✅ 添加参数差异显示

---

## 测试清单

- [ ] Linux 桌面：连接后不再显示"已断开"
- [ ] Android：重连后不黑屏
- [ ] 所有平台：烧录可以停止
- [ ] 所有平台：参数值保持
- [ ] 所有平台：修改的参数有视觉标识

---

**更新时间**: 2026-01-23
**修复进度**: 2/5 已完成
