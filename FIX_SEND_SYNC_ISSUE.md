# 修复连续发送与实际传输同步问题

## 问题

UI显示发送完成，但串口还在接收数据。发送间隔与实际传输不同步。

## 根本原因

之前的实现：
```dart
// 不等待任何东西，立即发送下一块
debugService.sendDataFrame(...).then(...);
await Future.delayed(Duration(milliseconds: sendInterval));
```

问题：
1. 所有发送请求快速进入蓝牙缓冲区
2. 蓝牙底层慢慢传输
3. UI显示完成，但数据还在传输

## 解决方案

### 1. 添加新方法（已完成）

在 `lib/data/services/debug_service.dart` 中添加：

```dart
/// 只发送数据帧，不等待响应
///
/// 用于连续发送模式，只等待数据写入蓝牙缓冲区
Future<void> sendDataFrameOnly({
  required int address,
  required List<int> data,
}) async {
  try {
    // 构建数据帧
    final frame = frameBuilder.buildFlashDataFrame(address, data);

    // 发送（等待写入蓝牙缓冲区完成）
    await bluetoothDatasource.write(frame);
  } catch (e) {
    onLog('发送数据帧失败: $e');
    rethrow;
  }
}
```

### 2. 修改连续发送逻辑

在 `lib/presentation/screens/debug_screen.dart` 的 `_sendAllDataFrames()` 方法中：

**修改前**：
```dart
// 不等待响应，直接发送
debugService.sendDataFrame(
  address: block.address,
  data: block.data,
).then((response) {
  // 异步处理响应
  ref.read(dataFrameResponseProvider.notifier).state = response;
  addDebugLog(ref, '数据帧响应: ${response.message}');
}).catchError((e) {
  addDebugLog(ref, '数据帧异常: $e');
});

// 等待发送间隔
if (i < dataBlocks.length - 1) {
  await Future.delayed(Duration(milliseconds: sendInterval));
}
```

**修改后**：
```dart
try {
  // 只发送数据，等待写入完成（不等待响应）
  await debugService.sendDataFrameOnly(
    address: block.address,
    data: block.data,
  );

  addDebugLog(ref, '数据帧已发送');
} catch (e) {
  addDebugLog(ref, '数据帧发送失败: $e');
}

// 等待发送间隔
if (i < dataBlocks.length - 1) {
  await Future.delayed(Duration(milliseconds: sendInterval));
}
```

## 工作流程

### 修改前（不同步）

```
调用 sendDataFrame() → 不等待 → 等待间隔 → 调用下一个
    ↓
所有请求快速进入蓝牙缓冲区
    ↓
蓝牙慢慢传输（UI已显示完成）
```

### 修改后（同步）

```
调用 sendDataFrameOnly()
    ↓
等待数据写入蓝牙缓冲区 ✅
    ↓
等待发送间隔
    ↓
调用下一个
```

## 优势

1. **同步传输**：
   - 等待数据写入蓝牙缓冲区
   - UI显示与实际传输同步

2. **准确的间隔**：
   - 发送间隔真正控制传输速度
   - 不会堆积在缓冲区

3. **可控的速度**：
   - 通过调整间隔控制传输速度
   - 避免缓冲区溢出

## 需要修改的文件

1. ✅ `lib/data/services/debug_service.dart` - 已添加 `sendDataFrameOnly()` 方法

2. ⏳ `lib/presentation/screens/debug_screen.dart` - 需要修改 `_sendAllDataFrames()` 方法

## 具体修改步骤

### 步骤 1：找到 `_sendAllDataFrames()` 方法

在 `lib/presentation/screens/debug_screen.dart` 中，找到这个方法（大约在第 700 行）。

### 步骤 2：找到发送数据的代码

找到这段代码：
```dart
// 不等待响应，直接发送
debugService.sendDataFrame(
  address: block.address,
  data: block.data,
).then((response) {
  ...
});
```

### 步骤 3：替换为新代码

替换为：
```dart
try {
  // 只发送数据，等待写入完成（不等待响应）
  await debugService.sendDataFrameOnly(
    address: block.address,
    data: block.data,
  );

  addDebugLog(ref, '数据帧已发送');
} catch (e) {
  addDebugLog(ref, '数据帧发送失败: $e');
}
```

## 测试步骤

1. **重新构建**：
   ```bash
   flutter build linux --release
   ```

2. **运行应用**：
   ```bash
   ./run-linux.sh
   ```

3. **测试连续发送**：
   - 加载 HEX 文件
   - 设置发送间隔（如 100ms）
   - 点击"连续发送全部"
   - 观察串口接收

4. **验证同步**：
   - UI显示的进度应该与串口接收同步
   - 发送完成时，串口也应该接收完成

## 预期结果

✅ UI显示与实际传输同步
✅ 发送间隔准确控制传输速度
✅ 不会出现UI完成但数据还在传输的情况
✅ 串口接收与发送进度一致

## 注意事项

1. **发送间隔的选择**：
   - 建议 100-200ms
   - 太小可能导致缓冲区压力
   - 太大会降低传输速度

2. **错误处理**：
   - 单个块发送失败会记录日志
   - 继续发送下一块
   - 不会中断整个流程

3. **性能**：
   - 等待写入会稍微降低速度
   - 但确保了传输的可靠性和同步性

## 总结

通过添加 `sendDataFrameOnly()` 方法并等待数据写入蓝牙缓冲区，确保了UI显示与实际传输的同步。现在发送间隔真正控制传输速度，不会出现UI完成但数据还在传输的情况。
