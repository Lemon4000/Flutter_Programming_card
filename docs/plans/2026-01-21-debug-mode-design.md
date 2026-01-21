# 调试模式功能设计文档

**日期**: 2026-01-21
**项目**: Flutter编程卡上位机
**作者**: Claude Sonnet 4.5

## 概述

为编程卡上位机添加独立的调试模式功能，允许用户手动发送烧录协议指令并查看设备响应，用于协议测试和问题排查。

## 需求

用户需要一个调试工具来：
1. 手动发送握手指令 (!HEX;)
2. 手动发送擦除指令 (!HEX:ESIZE[n];)
3. 从 HEX 文件加载数据并发送单个数据帧
4. 手动发送验证指令 (!HEX:ENDCRC[total];)
5. 查看设备响应并自动校验
6. 支持简洁和详细两种显示模式

## 设计方案

### 1. 整体架构

#### 1.1 UI 层
- **位置**: 新增独立的"调试"标签页（第5个标签）
- **布局**: 垂直滚动的卡片式布局
- **组件**: 4个功能卡片 + 操作日志区域

#### 1.2 业务逻辑层
- **DebugService**: 处理调试指令的发送和响应
- **复用现有组件**:
  - `FrameBuilder`: 构建协议帧
  - `FrameParser`: 解析响应帧
  - `BluetoothDatasource`: 蓝牙通信

#### 1.3 数据流
```
用户操作 → DebugScreen → DebugService → FrameBuilder → BluetoothDatasource
                                                              ↓
用户查看 ← DebugScreen ← DebugService ← FrameParser ← 设备响应
```

---

### 2. UI 界面设计

#### 2.1 页面结构

```
┌─────────────────────────────────┐
│  顶部：连接状态栏                │
├─────────────────────────────────┤
│                                 │
│  [握手指令卡片]                  │
│  - 发送按钮                      │
│  - 响应状态（可展开）             │
│                                 │
│  [擦除指令卡片]                  │
│  - 擦除块数输入                  │
│  - 发送按钮                      │
│  - 响应状态（可展开）             │
│                                 │
│  [数据帧卡片]                    │
│  - 选择 HEX 文件                 │
│  - 数据块选择器                  │
│  - 发送按钮                      │
│  - 响应状态（可展开）             │
│                                 │
│  [验证指令卡片]                  │
│  - CRC 值输入                    │
│  - 发送按钮                      │
│  - 响应状态（可展开）             │
│                                 │
├─────────────────────────────────┤
│  底部：操作日志（最近10条）       │
└─────────────────────────────────┘
```

#### 2.2 卡片设计

每个功能卡片包含：
- **标题区域**: 指令名称 + 图标
- **输入区域**: 参数输入（如果需要）
- **操作区域**: 发送按钮 + 状态指示器
- **响应区域**:
  - 简洁模式：状态图标 + 关键信息
  - 详细模式：原始数据 + 解析字段 + 时间信息

#### 2.3 响应状态显示

**简洁模式**（默认）：
```
✓ 握手成功 (45ms)
  响应: #HEX;
  [展开详情 ▼]
```

**详细模式**（展开后）：
```
✓ 握手成功 (45ms)
  响应: #HEX;
  [收起 ▲]

  原始数据 (HEX):
  AA 55 23 48 45 58 3B C3 A2

  解析结果:
  - 前导码: AA 55
  - 帧类型: 响应帧 (#)
  - 内容: HEX;
  - CRC: C3 A2 ✓ 校验通过

  时间信息:
  - 发送时间: 08:30:15.123
  - 接收时间: 08:30:15.168
  - 耗时: 45ms
```

---

### 3. 核心组件实现

#### 3.1 DebugService 类

```dart
class DebugService {
  final BluetoothDatasource bluetoothDatasource;
  final FrameBuilder frameBuilder;
  final FrameParser frameParser;
  final void Function(String) onLog;

  Timer? _timeoutTimer;
  Completer<DebugResponse>? _responseCompleter;

  DebugService({
    required this.bluetoothDatasource,
    required this.frameBuilder,
    required this.frameParser,
    required this.onLog,
  });

  /// 发送握手指令
  Future<DebugResponse> sendHandshake({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final startTime = DateTime.now();
    _responseCompleter = Completer<DebugResponse>();

    try {
      // 构建握手帧
      final frame = frameBuilder.buildInitFrame();

      // 发送
      onLog('发送握手指令: !HEX;');
      await bluetoothDatasource.write(frame);

      // 设置超时
      _startTimeout(timeout, () {
        if (!_responseCompleter!.isCompleted) {
          _responseCompleter!.complete(DebugResponse.timeout(
            message: '握手超时',
            elapsed: DateTime.now().difference(startTime),
          ));
        }
      });

      return await _responseCompleter!.future;
    } catch (e) {
      return DebugResponse.error(
        message: '发送失败: $e',
        elapsed: DateTime.now().difference(startTime),
      );
    }
  }

  /// 处理接收到的帧
  void handleReceivedFrame(List<int> frame) {
    if (_responseCompleter == null || _responseCompleter!.isCompleted) {
      return;
    }

    _cancelTimeout();

    // 解析响应
    final response = frameParser.parseInitResponse(frame);

    if (response != null && response.success) {
      _responseCompleter!.complete(DebugResponse.success(
        message: '握手成功',
        rawData: frame,
        parsedData: {'type': 'init', 'success': true},
        elapsed: DateTime.now().difference(_startTime),
      ));
    } else {
      _responseCompleter!.complete(DebugResponse.error(
        message: '响应解析失败',
        rawData: frame,
        elapsed: DateTime.now().difference(_startTime),
      ));
    }
  }

  // 其他方法类似...
}
```

#### 3.2 DebugResponse 模型

```dart
enum DebugStatus { success, timeout, error, waiting }

class DebugResponse {
  final DebugStatus status;
  final String message;
  final List<int>? rawData;
  final Map<String, dynamic>? parsedData;
  final Duration elapsed;
  final DateTime timestamp;

  DebugResponse({
    required this.status,
    required this.message,
    this.rawData,
    this.parsedData,
    required this.elapsed,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory DebugResponse.success({...});
  factory DebugResponse.timeout({...});
  factory DebugResponse.error({...});
}
```

#### 3.3 Provider 定义

```dart
// 调试服务 Provider
final debugServiceProvider = Provider<DebugService>((ref) {
  return DebugService(
    bluetoothDatasource: ref.read(bluetoothDatasourceProvider),
    frameBuilder: ref.read(frameBuilderProvider),
    frameParser: ref.read(frameParserProvider),
    onLog: (msg) => ref.read(logProvider.notifier).addLog(msg),
  );
});

// 选中的调试 HEX 文件
final debugHexFileProvider = StateProvider<FirmwareFile?>((ref) => null);

// 当前数据块索引
final debugBlockIndexProvider = StateProvider<int>((ref) => 0);

// 各指令的响应状态
final handshakeResponseProvider = StateProvider<DebugResponse?>((ref) => null);
final eraseResponseProvider = StateProvider<DebugResponse?>((ref) => null);
final dataFrameResponseProvider = StateProvider<DebugResponse?>((ref) => null);
final verifyResponseProvider = StateProvider<DebugResponse?>((ref) => null);

// 操作日志
final debugLogsProvider = StateProvider<List<String>>((ref) => []);
```

---

### 4. 文件结构

```
lib/
├── data/
│   └── services/
│       └── debug_service.dart          # 新增：调试服务
├── data/
│   └── models/
│       └── debug_response.dart         # 新增：响应模型
├── presentation/
│   ├── screens/
│   │   ├── debug_screen.dart           # 新增：调试页面
│   │   └── home_screen.dart            # 修改：添加调试标签
│   ├── providers/
│   │   └── debug_providers.dart        # 新增：调试相关 Provider
│   └── widgets/
│       ├── debug_command_card.dart     # 新增：指令卡片组件
│       └── debug_response_view.dart    # 新增：响应显示组件
```

---

### 5. 实现步骤

1. 创建数据模型 (`DebugResponse`)
2. 创建调试服务 (`DebugService`)
3. 创建 Provider 定义
4. 创建响应显示组件 (`DebugResponseView`)
5. 创建指令卡片组件 (`DebugCommandCard`)
6. 创建调试页面 (`DebugScreen`)
7. 修改主页面添加调试标签
8. 测试各项功能

---

## 设计完成

这就是完整的调试模式设计方案。主要特点：

✅ 独立的调试标签页，不影响现有功能
✅ 从 HEX 文件加载真实数据进行测试
✅ 可展开/折叠的响应详情
✅ 完整的错误处理和超时机制
✅ 复用现有的协议组件，代码简洁

准备好开始实现了吗？