# 烧录停止功能修复

## 🐛 问题描述

**问题**: 在烧录过程中点击"停止烧录"按钮后，烧录仍然会继续发送命令，直到超时才会停下。

**影响**:
- 用户无法及时停止烧录
- 浪费时间等待超时
- 用户体验差

---

## 🔍 问题根源

### 原始代码问题

**文件**: `lib/presentation/widgets/flash_progress_dialog.dart` (第 318-323 行)

```dart
return OutlinedButton.icon(
  onPressed: () {
    // 停止烧录
    ref.read(flashProgressProvider.notifier).state =
        FlashProgress.cancelled();
    Navigator.of(context).pop(false);
  },
  icon: const Icon(Icons.stop_rounded),
  label: const Text('停止烧录'),
  // ...
);
```

### 问题分析

1. **只更新了 UI 状态**: 停止按钮只更新了 `flashProgressProvider` 的状态
2. **没有停止 Worker**: 没有调用 `FlashWorker` 的 `abort()` 方法
3. **Worker 继续运行**: `FlashWorker` 的状态机继续运行，持续发送命令
4. **直到超时**: 只有当所有重试超时后才会停止

### 技术细节

烧录流程：
```
UI (FlashProgressDialog)
  ↓
FlashScreen
  ↓
FlashFirmwareUseCase
  ↓
CommunicationRepositoryImpl
  ↓
FlashWorker (状态机)
```

停止烧录需要：
1. 调用 `CommunicationRepositoryImpl.abortFlashing()`
2. 该方法会调用 `FlashWorker.abort()`
3. Worker 取消定时器、更新状态、清理资源

---

## ✅ 修复方案

### 修复策略

在停止按钮的 `onPressed` 回调中：
1. 调用 `CommunicationRepository` 的 `abortFlashing()` 方法
2. 更新 UI 进度状态
3. Worker 的 `abort()` 方法会：
   - 取消所有定时器
   - 设置状态为 `failed`
   - 阻止后续状态转换
   - 清理资源

### 修复内容

#### 1. 创建停止回调 Provider

**文件**: `lib/presentation/providers/flash_providers.dart`

```dart
/// 停止烧录回调 Provider
final abortFlashingCallbackProvider = StateProvider<void Function()?>((ref) => null);
```

#### 2. 在 FlashScreen 中设置回调

**文件**: `lib/presentation/screens/flash_screen.dart`

在 `_startFlashing()` 方法中，烧录开始前：

```dart
// 获取 communication repository 用于停止烧录
final communicationRepo = await ref.read(communicationRepositoryProvider.future);

// 设置停止烧录回调
ref.read(abortFlashingCallbackProvider.notifier).state = () {
  communicationRepo.abortFlashing();
};
```

#### 3. 修改 FlashProgressDialog 停止按钮

**文件**: `lib/presentation/widgets/flash_progress_dialog.dart`

**修复停止按钮**:

**原代码**:
```dart
return OutlinedButton.icon(
  onPressed: () {
    // 停止烧录
    ref.read(flashProgressProvider.notifier).state =
        FlashProgress.cancelled();
    Navigator.of(context).pop(false);
  },
  icon: const Icon(Icons.stop_rounded),
  label: const Text('停止烧录'),
  // ...
);
```

**新代码**:
```dart
return OutlinedButton.icon(
  onPressed: () {
    // 调用停止烧录回调
    final abortCallback = ref.read(abortFlashingCallbackProvider);
    if (abortCallback != null) {
      abortCallback();
    }

    // 更新进度状态
    ref.read(flashProgressProvider.notifier).state =
        FlashProgress.cancelled(startTime: progress.startTime);
  },
  icon: const Icon(Icons.stop_rounded),
  label: const Text('停止烧录'),
  // ...
);
```

### 关键改进

1. **调用 abortFlashing()**: 直接停止 Worker 的状态机
2. **保留 startTime**: 确保取消状态包含开始时间，用于计算已用时
3. **不关闭对话框**: 让对话框显示"烧录失败"状态，用户可以选择"关闭"或"重试"

---

## 🔧 FlashWorker 的停止机制

### abort() 方法

**文件**: `lib/data/services/flash_worker.dart` (第 486-499 行)

```dart
void abort() {
  if (_state != FlashState.idle && _state != FlashState.success && _state != FlashState.failed) {
    onLog('烧录被中止');
    _cancelTimeout();
    _onProgress?.call(FlashProgress.cancelled(startTime: _startTime));

    if (_completer != null && !_completer!.isCompleted) {
      _completer?.complete(const Left(FlashFailure('烧录被用户取消')));
    }

    _state = FlashState.failed;
    _cleanup();
  }
}
```

### 状态转换保护

**文件**: `lib/data/services/flash_worker.dart` (第 165-171 行)

```dart
void _transitionTo(FlashState newState) {
  // 如果已经处于终止状态（idle, success, failed），不允许转换到其他状态
  if ((_state == FlashState.idle || _state == FlashState.success || _state == FlashState.failed) &&
      newState != FlashState.init) {
    onLog('状态转换被阻止: 当前状态=$_state, 目标状态=$newState');
    return;
  }

  _state = newState;
  _cancelTimeout();
  // ...
}
```

### 停止机制工作流程

1. **用户点击停止按钮**
   - UI 调用 `communicationRepo.abortFlashing()`

2. **Repository 调用 Worker**
   - `CommunicationRepositoryImpl.abortFlashing()` 调用 `_flashWorker.abort()`

3. **Worker 停止状态机**
   - 取消所有定时器（`_cancelTimeout()`）
   - 设置状态为 `FlashState.failed`
   - 完成 completer，返回失败结果
   - 清理资源（`_cleanup()`）

4. **阻止后续操作**
   - 所有 `Future.delayed` 回调中的状态检查会失败
   - `_transitionTo` 方法会阻止从 `failed` 状态转换到其他状态
   - 不会再发送任何命令

---

## 🧪 测试验证

### 测试场景 1: 初始化阶段停止

**步骤**:
1. 选择固件文件
2. 点击"开始烧录"
3. 在"初始化设备..."阶段点击"停止烧录"

**预期结果**:
- ✅ 烧录立即停止
- ✅ 不再发送初始化命令
- ✅ 显示"烧录失败"状态
- ✅ 可以选择"关闭"或"重试"

### 测试场景 2: 擦除阶段停止

**步骤**:
1. 开始烧录
2. 在"擦除 Flash..."阶段点击"停止烧录"

**预期结果**:
- ✅ 烧录立即停止
- ✅ 不再发送擦除命令
- ✅ 显示"烧录失败"状态

### 测试场景 3: 编程阶段停止

**步骤**:
1. 开始烧录
2. 在"烧录中 X/Y"阶段点击"停止烧录"

**预期结果**:
- ✅ 烧录立即停止
- ✅ 不再发送数据块
- ✅ 显示"烧录失败"状态
- ✅ 进度条停留在当前位置

### 测试场景 4: 验证阶段停止

**步骤**:
1. 开始烧录
2. 在"验证烧录结果..."阶段点击"停止烧录"

**预期结果**:
- ✅ 烧录立即停止
- ✅ 不再发送验证命令
- ✅ 显示"烧录失败"状态

### 测试场景 5: 停止后重试

**步骤**:
1. 开始烧录
2. 点击"停止烧录"
3. 点击"重试"按钮

**预期结果**:
- ✅ 对话框关闭
- ✅ 重新开始烧录
- ✅ 从头开始（初始化阶段）
- ✅ 可以正常完成烧录

---

## 📊 修复状态

- [x] 问题分析完成
- [x] 修复方案设计
- [x] 创建 abortFlashingCallbackProvider
- [x] FlashScreen 设置停止回调
- [x] FlashProgressDialog 调用停止回调
- [x] 保留 startTime
- [x] 代码验证通过（无错误）
- [ ] 设备测试验证

---

## 🎯 相关代码

### CommunicationRepositoryImpl.abortFlashing()

**文件**: `lib/data/repositories/communication_repository_impl.dart` (第 403-408 行)

```dart
/// 停止烧录
void abortFlashing() {
  if (_flashWorker != null && _isFlashing) {
    _addLog('用户请求停止烧录');
    _flashWorker!.abort();
  }
}
```

### FlashWorker._cleanup()

**文件**: `lib/data/services/flash_worker.dart` (第 514-525 行)

```dart
/// 清理资源
void _cleanup() {
  _cancelTimeout();
  _state = FlashState.idle;
  _blocks = [];
  _currentBlockIndex = 0;
  _totalCrc = 0;
  _retryCount = 0;
  _onProgress = null;
  _completer = null;
  _startTime = null;
}
```

---

## 💡 技术要点

### 1. 状态机的停止机制

```dart
// ✅ 正确：调用 Worker 的 abort() 方法
communicationRepo.abortFlashing();

// ❌ 错误：只更新 UI 状态
ref.read(flashProgressProvider.notifier).state = FlashProgress.cancelled();
```

### 2. 状态转换保护

Worker 的状态机有内置保护：
- 一旦进入终止状态（`idle`、`success`、`failed`），就不能转换到其他状态
- 所有延迟回调都会检查状态是否有效
- 确保停止后不会继续执行

### 3. 资源清理

`abort()` 方法会：
- 取消所有定时器
- 完成 completer（避免内存泄漏）
- 清理所有状态变量
- 重置为 `idle` 状态

### 4. 用户体验

- 停止后对话框不自动关闭
- 显示"烧录失败"状态和取消原因
- 提供"关闭"和"重试"选项
- 保留已用时信息

---

## 🔄 完整流程

### 正常烧录流程

```
用户点击"开始烧录"
  ↓
FlashScreen._startFlashing()
  ↓
FlashFirmwareUseCase.call()
  ↓
CommunicationRepositoryImpl.flashFirmware()
  ↓
创建 FlashWorker
  ↓
FlashWorker.startFlashWithBlocks()
  ↓
状态机运行: init → erase → program → verify → success
  ↓
对话框显示"烧录成功"
```

### 停止烧录流程

```
用户点击"停止烧录"
  ↓
FlashProgressDialog 按钮回调
  ↓
communicationRepo.abortFlashing()
  ↓
FlashWorker.abort()
  ↓
- 取消定时器
- 设置状态为 failed
- 完成 completer
- 清理资源
  ↓
所有后续状态转换被阻止
  ↓
对话框显示"烧录失败"
```

---

## 📚 参考资料

- [Flutter 状态机模式](https://flutter.dev/docs/development/data-and-backend/state-mgmt)
- [Dart Future 和 Timer 管理](https://dart.dev/codelabs/async-await)
- [Riverpod 状态管理](https://riverpod.dev/)

---

**修复时间**: 2026-01-23
**修复版本**: 待发布
**测试状态**: 待设备验证
