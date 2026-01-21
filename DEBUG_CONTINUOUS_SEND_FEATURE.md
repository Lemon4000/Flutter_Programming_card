# 调试页面连续发送功能

## 新增功能

### 1. 连续发送模式

**功能描述**：
- 启用后，发送指令时不等待设备响应
- 可以快速连续发送多个指令
- 适用于批量测试和快速调试

**使用方法**：
- 在调试页面顶部的"发送设置"区域
- 打开"连续发送模式"开关

**工作原理**：
- 正常模式：`await response` - 等待响应后才能发送下一条
- 连续模式：`then(response)` - 立即返回，响应异步处理

### 2. 发送间隔设置

**功能描述**：
- 设置连续发送时的时间间隔
- 范围：10ms - 1000ms
- 默认值：100ms

**使用方法**：
- 在"发送设置"区域使用滑块调整
- 实时显示当前间隔值

**应用场景**：
- 快速测试：10-50ms
- 正常调试：100-200ms
- 慢速测试：500-1000ms

### 3. 数据帧自动递增

**功能描述**：
- 发送数据帧后自动增加块索引
- 方便连续发送多个数据块
- 默认启用

**使用方法**：
- 在"发送设置"区域打开/关闭"数据帧自动递增"
- 发送数据帧后，块索引自动 +1
- 到达最后一块时停止递增

**工作流程**：
```
发送块 0 → 自动切换到块 1 → 发送块 1 → 自动切换到块 2 → ...
```

## 使用场景

### 场景 1：快速批量发送数据帧

**步骤**：
1. 加载 HEX 文件
2. 启用"连续发送模式"
3. 启用"数据帧自动递增"
4. 设置发送间隔（如 50ms）
5. 连续点击"发送"按钮，或使用快捷键

**效果**：
- 每次点击发送一个数据块
- 自动切换到下一块
- 无需等待响应
- 快速完成所有数据块的发送

### 场景 2：压力测试

**步骤**：
1. 启用"连续发送模式"
2. 设置最小间隔（10ms）
3. 快速连续点击发送按钮

**效果**：
- 测试设备的处理能力
- 观察设备在高负载下的表现

### 场景 3：正常调试

**步骤**：
1. 关闭"连续发送模式"
2. 正常发送指令
3. 等待并查看响应

**效果**：
- 每次发送都等待响应
- 可以详细查看每个响应的内容
- 适合逐步调试

## 技术实现

### 连续发送模式实现

```dart
if (continuousMode) {
  // 连续发送模式：不等待响应
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
  await Future.delayed(Duration(milliseconds: sendInterval));

  // 自动递增块索引
  if (autoIncrement && blockIndex < dataBlocks.length - 1) {
    ref.read(debugBlockIndexProvider.notifier).state = blockIndex + 1;
  }
} else {
  // 正常模式：等待响应
  final response = await debugService.sendDataFrame(
    address: block.address,
    data: block.data,
  );
  // ...
}
```

### 状态管理

新增了3个状态Provider：

```dart
/// 连续发送模式（不等待响应）
final continuousSendModeProvider = StateProvider<bool>((ref) => false);

/// 发送间隔（毫秒）
final sendIntervalProvider = StateProvider<int>((ref) => 100);

/// 数据帧自动递增
final autoIncrementBlockProvider = StateProvider<bool>((ref) => true);
```

## UI 设计

### 发送设置卡片

```
┌─────────────────────────────────────┐
│ ⚙️ 发送设置                          │
├─────────────────────────────────────┤
│ 🔘 连续发送模式                      │
│    不等待响应，连续发送指令           │
│                                     │
│ 发送间隔: [━━━━━●━━━━] 100ms        │
│                                     │
│ 🔘 数据帧自动递增                    │
│    发送后自动增加块索引               │
└─────────────────────────────────────┘
```

## 注意事项

### 1. 连续发送模式的风险

⚠️ **警告**：
- 连续发送模式下，响应可能丢失或乱序
- 设备可能无法处理过快的指令
- 建议先用正常模式测试，确认设备正常后再使用连续模式

### 2. 发送间隔的选择

- **太快（< 50ms）**：设备可能来不及处理
- **太慢（> 500ms）**：发送效率低
- **推荐值**：100-200ms

### 3. 自动递增的限制

- 只对数据帧有效
- 到达最后一块时自动停止
- 可以手动关闭此功能

## 修改的文件

1. `lib/presentation/providers/debug_providers.dart`
   - 新增 `continuousSendModeProvider`
   - 新增 `sendIntervalProvider`
   - 新增 `autoIncrementBlockProvider`

2. `lib/presentation/screens/debug_screen.dart`
   - 新增 `_buildSendSettings()` 方法
   - 更新 `_sendHandshake()` 方法
   - 更新 `_sendErase()` 方法
   - 更新 `_sendDataFrame()` 方法
   - 更新 `_sendVerify()` 方法

## 测试步骤

### 1. 测试连续发送模式

```bash
./run-linux.sh
```

1. 连接设备
2. 进入调试页面
3. 启用"连续发送模式"
4. 设置发送间隔为 100ms
5. 连续点击"发送握手指令"按钮
6. 观察日志，应该看到快速连续的发送记录

### 2. 测试数据帧自动递增

1. 加载 HEX 文件
2. 启用"数据帧自动递增"
3. 发送数据帧
4. 观察块索引是否自动增加

### 3. 测试发送间隔

1. 启用"连续发送模式"
2. 调整发送间隔滑块
3. 连续发送指令
4. 观察发送间隔是否符合设置

## 预期结果

✅ 连续发送模式正常工作，不等待响应
✅ 发送间隔可调整，范围 10-1000ms
✅ 数据帧自动递增，方便批量发送
✅ 正常模式和连续模式可以切换
✅ UI 清晰，设置直观

## 后续改进建议

1. **批量发送功能**：
   - 添加"发送全部数据块"按钮
   - 自动循环发送所有块

2. **发送进度显示**：
   - 显示当前发送进度（如 "5/100"）
   - 添加进度条

3. **发送统计**：
   - 统计发送成功/失败次数
   - 计算平均发送速度

4. **快捷键支持**：
   - 添加键盘快捷键（如 Ctrl+Enter 发送）
   - 提高操作效率

## 总结

新增的连续发送功能大大提高了调试效率，特别是在需要批量发送数据帧时。通过灵活的设置选项，可以适应不同的调试场景。
