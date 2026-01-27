# 编程数据帧日志记录修复

## 🐛 问题描述

**问题**: 日志界面没有显示发送出去的编程数据帧（`!HEX:START...`）

**原因**: `FlashWorker` 的 `_sendProgramData` 方法在发送数据时，没有调用 `onTxData` 回调来记录日志

**影响**: 编程阶段的 256 个数据块都没有记录到日志中

---

## 🔍 问题分析

### 代码对比

**其他发送方法**（正确）:
```dart
// 初始化命令 - ✅ 有日志记录
void _sendInitCommand() {
  final frame = frameBuilder.buildInitFrame();
  onTxData?.call(frame);  // ✅ 记录日志
  writeData(frame);
}

// 擦除命令 - ✅ 有日志记录
void _sendEraseCommand() {
  final frame = frameBuilder.buildEraseFrame(eraseBlocks);
  onTxData?.call(frame);  // ✅ 记录日志
  writeData(frame);
}

// 验证命令 - ✅ 有日志记录
void _sendVerifyCommand() {
  final frame = frameBuilder.buildFlashVerifyFrame(_totalCrc);
  onTxData?.call(frame);  // ✅ 记录日志
  writeData(frame);
}
```

**编程数据方法**（错误）:
```dart
// 编程数据 - ❌ 没有日志记录
void _sendProgramData() {
  final frame = frameBuilder.buildFlashDataFrame(block.address, block.data);
  writeData(frame);  // ❌ 直接发送，没有记录日志
}
```

---

## ✅ 修复方案

### 修改文件
**文件**: `lib/data/services/flash_worker.dart`

**位置**: 第 299-319 行

**修改内容**:

**原代码**:
```dart
void _sendProgramData({bool isRetry = false}) {
  if (_currentBlockIndex >= _blocks.length) {
    _transitionTo(FlashState.verify);
    return;
  }

  final block = _blocks[_currentBlockIndex];

  if (!isRetry) {
    _retryCount = 0;
  }

  final frame = frameBuilder.buildFlashDataFrame(block.address, block.data);
  writeData(frame);  // ❌ 没有记录日志

  _transitionTo(FlashState.waitProgram);
  _startTimeout(const Duration(milliseconds: 20), _onProgramTimeout);
}
```

**新代码**:
```dart
void _sendProgramData({bool isRetry = false}) {
  if (_currentBlockIndex >= _blocks.length) {
    _transitionTo(FlashState.verify);
    return;
  }

  final block = _blocks[_currentBlockIndex];

  if (!isRetry) {
    _retryCount = 0;
  }

  final frame = frameBuilder.buildFlashDataFrame(block.address, block.data);
  onTxData?.call(frame);  // ✅ 添加日志记录
  writeData(frame);

  _transitionTo(FlashState.waitProgram);
  _startTimeout(const Duration(milliseconds: 20), _onProgramTimeout);
}
```

---

## 📊 修复效果

### 修复前
```
日志界面显示:
[TX] [x100] !HEX;              (初始化)
[RX] [x1]   #HEX;
[TX] [x1]   !HEX:ESIZE10;      (擦除)
[RX] [x1]   #HEX:ERASE;
                               (编程阶段 - 空白，没有日志)
[TX] [x1]   !HEX:ENDCRC...     (验证)
[RX] [x1]   #HEX:REPLY...
```

### 修复后
```
日志界面显示:
[TX] [x100] !HEX;                           (初始化)
[RX] [x1]   #HEX;
[TX] [x1]   !HEX:ESIZE10;                   (擦除)
[RX] [x1]   #HEX:ERASE;
[TX] [x256] !HEX:START0200,SIZE256,DATA...  (编程 - ✅ 显示并计数)
[RX] [x256] #HEX:REPLY[CRC];
[TX] [x1]   !HEX:ENDCRC...                  (验证)
[RX] [x1]   #HEX:REPLY...
```

---

## 🔄 数据流

### 完整的日志记录流程

```
FlashWorker._sendProgramData()
  ↓
生成数据帧: buildFlashDataFrame()
  ↓
调用回调: onTxData?.call(frame)  ← ✅ 添加的代码
  ↓
CommunicationRepositoryImpl.onTxData
  ↓
_ref.read(logProvider.notifier).addTxLog(data)
  ↓
LogNotifier._addLog('TX', data)
  ↓
智能比较: hasSameData()
  ↓
找到相同的 START 命令
  ↓
更新计数: count + 1
  ↓
UI 显示: [TX] [x256] ...
```

---

## 🧪 测试验证

### 测试步骤

1. **启用日志记录**
   - 打开日志页面
   - 点击"已暂停"按钮，切换为"记录中"（橙色）

2. **开始烧录**
   - 选择固件文件
   - 点击"开始烧录"

3. **观察日志**
   - 初始化阶段：应该看到 `[TX] [x100] !HEX;`
   - 擦除阶段：应该看到 `[TX] [x1] !HEX:ESIZE10;`
   - **编程阶段**：应该看到 `[TX] [x256] !HEX:START...` ← **重点验证**
   - 验证阶段：应该看到 `[TX] [x1] !HEX:ENDCRC...`

4. **验证计数**
   - 编程阶段的 TX 应该显示 `[x256]` 徽章
   - 编程阶段的 RX 应该显示 `[x256]` 徽章

### 预期结果

**控制台输出**:
```
[LOG] 添加 TX: !HEX:START0000,SIZE256,DATA...
[LOG] 添加新条目
[LOG] 添加 RX: #HEX:REPLY...
[LOG] 添加新条目
[LOG] 添加 TX: !HEX:START0100,SIZE256,DATA...
[LOG] 找到匹配的条目，索引: 2, 当前计数: 1
[LOG] 更新计数: 1 -> 2
[LOG] 添加 RX: #HEX:REPLY...
[LOG] 找到匹配的条目，索引: 3, 当前计数: 1
[LOG] 更新计数: 1 -> 2
... (重复 256 次)
```

**UI 显示**:
```
┌─────────────────────────────────────────────────────┐
│ [TX] [x100] 最后: 10:00:05.00  !HEX;               │
│ [RX] [x1]   10:00:05.05         #HEX;               │
│ [TX] [x1]   10:00:05.10         !HEX:ESIZE10;       │
│ [RX] [x1]   10:00:07.00         #HEX:ERASE;         │
│ [TX] [x256] 最后: 10:00:20.00  !HEX:START0200...   │ ← 新增
│ [RX] [x256] 最后: 10:00:20.05  #HEX:REPLY[CRC];    │ ← 新增
│ [TX] [x1]   10:00:20.10         !HEX:ENDCRC...      │
│ [RX] [x1]   10:00:20.15         #HEX:REPLY...       │
└─────────────────────────────────────────────────────┘
```

---

## 🎯 相关修复

这个修复配合之前的改进，完整实现了日志计数功能：

1. ✅ **日志记录** - 添加 `onTxData?.call(frame)` 记录编程数据
2. ✅ **智能比较** - `hasSameData()` 识别 START 命令
3. ✅ **向后查找** - 查找最近 10 条日志中的相同命令
4. ✅ **计数显示** - UI 显示 `[x256]` 徽章和最后时间

---

## 📝 检查清单

修复后，请确认以下内容：

- [ ] 日志记录已启用（"记录中"按钮是橙色）
- [ ] 初始化阶段有日志（`!HEX;`）
- [ ] 擦除阶段有日志（`!HEX:ESIZE...`）
- [ ] **编程阶段有日志**（`!HEX:START...`）← **重点**
- [ ] 验证阶段有日志（`!HEX:ENDCRC...`）
- [ ] 编程阶段显示计数徽章（`[x256]`）
- [ ] 控制台有 `[LOG]` 调试输出

---

## 🔧 其他发送方法检查

已确认其他发送方法都正确记录了日志：

| 方法 | 命令 | 日志记录 | 状态 |
|------|------|---------|------|
| `_sendInitCommand` | `!HEX;` | ✅ 有 | 正常 |
| `_sendEraseCommand` | `!HEX:ESIZE...` | ✅ 有 | 正常 |
| `_sendProgramData` | `!HEX:START...` | ✅ 已修复 | **本次修复** |
| `_sendVerifyCommand` | `!HEX:ENDCRC...` | ✅ 有 | 正常 |

---

## 💡 经验总结

### 问题根源
在实现新功能时，遗漏了日志记录的调用，导致编程阶段的数据没有被记录。

### 预防措施
1. **统一模式**: 所有发送方法都应该遵循相同的模式
   ```dart
   final frame = buildFrame();
   onTxData?.call(frame);  // 先记录
   writeData(frame);       // 后发送
   ```

2. **代码审查**: 检查所有 `writeData()` 调用前是否有 `onTxData?.call()`

3. **测试覆盖**: 确保每个阶段的日志都有测试验证

---

**修复时间**: 2026-01-23
**修复文件**: `lib/data/services/flash_worker.dart`
**修复行数**: 1 行（添加 `onTxData?.call(frame);`）
**影响范围**: 编程阶段的 256 个数据块
**测试状态**: 待设备验证
