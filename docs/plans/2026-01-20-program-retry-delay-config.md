# 编程阶段重试延迟可配置功能设计文档

**日期**: 2026-01-20
**项目**: Flutter编程卡上位机
**作者**: Claude Sonnet 4.5

## 概述

本文档记录了为烧录功能的编程阶段添加可配置重试延迟的完整设计和实现。

## 需求

用户希望能够自定义烧录过程中编程阶段的重试延迟时间，以适应不同的设备和通信环境。

## 设计方案

### 1. 配置参数

- **参数名**: `programRetryDelay`
- **默认值**: 50ms (保持原有行为)
- **取值范围**: 10-500ms
- **单位**: 毫秒
- **配置方式**: 在烧录页面的设置对话框中配置

### 2. 架构设计

**数据流向**:
```
烧录页面 UI → Provider → UseCase → Repository → FlashWorker
```

**涉及的组件**:
1. **Provider**: 管理配置状态 (`programRetryDelayProvider`)
2. **FlashScreen**: 读取配置并传递给 UseCase
3. **FlashFirmwareUseCase**: 接收并传递配置参数
4. **CommunicationRepository**: 接口定义
5. **CommunicationRepositoryImpl**: 实现层传递参数
6. **FlashWorker**: 使用配置的延迟值进行重试

## 实现细节

### 1. Provider 层

**文件**: `lib/presentation/providers/flash_providers.dart`

```dart
/// 编程阶段重试延迟（毫秒）Provider
final programRetryDelayProvider = StateProvider<int>((ref) => 50);
```

**说明**:
- 使用 `StateProvider` 管理状态
- 默认值为 50ms，与原有行为一致
- 状态在应用运行期间保持，但不持久化到本地存储

### 2. UI 层

**文件**: `lib/presentation/screens/flash_screen.dart`

#### 2.1 紧凑设置区显示

```dart
Widget _buildCompactInitSettingsSection(
  int initTimeout,
  int initMaxRetries,
  int programRetryDelay,
) {
  return Container(
    // ...
    Text('初始化: ${initTimeout}ms × $initMaxRetries次 | 编程重试: ${programRetryDelay}ms'),
    // ...
  );
}
```

**改进**:
- 标题从"初始化设置"改为"烧录设置"，更准确地反映功能范围
- 显示格式更紧凑，一行显示所有关键参数

#### 2.2 设置对话框

```dart
void _showInitSettingsDialog(
  BuildContext context,
  int currentTimeout,
  int currentRetries,
  int currentProgramRetryDelay,
) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('烧录设置'),
      content: Column(
        children: [
          // 初始化超时滑块 (10-200ms)
          // 初始化重试滑块 (10-500次)
          // 编程重试延迟滑块 (10-500ms) ← 新增
        ],
      ),
    ),
  );
}
```

**新增滑块配置**:
- **标签**: "编程重试延迟"
- **范围**: 10-500ms
- **步进**: 49 个刻度 (每 10ms 一个刻度)
- **实时更新**: 滑动时立即更新 Provider 状态

### 3. UseCase 层

**文件**: `lib/domain/usecases/flash_firmware_usecase.dart`

```dart
Future<Either<Failure, bool>> call(
  String hexFilePath, {
  void Function(FlashProgress progress)? onProgress,
  int? initTimeout,
  int? initMaxRetries,
  int? programRetryDelay,  // 新增参数
}) async {
  // ...
  return _repository.flashFirmware(
    hexFilePath,
    onProgress: onProgress,
    initTimeout: initTimeout,
    initMaxRetries: initMaxRetries,
    programRetryDelay: programRetryDelay,  // 传递参数
  );
}
```

### 4. Repository 层

**接口文件**: `lib/domain/repositories/communication_repository.dart`

```dart
Future<Either<Failure, bool>> flashFirmware(
  String hexFilePath, {
  void Function(FlashProgress progress)? onProgress,
  int? initTimeout,
  int? initMaxRetries,
  int? programRetryDelay,  // 新增参数
});
```

**实现文件**: `lib/data/repositories/communication_repository_impl.dart`

```dart
@override
Future<Either<Failure, bool>> flashFirmware(
  String hexFilePath, {
  void Function(FlashProgress progress)? onProgress,
  int? initTimeout,
  int? initMaxRetries,
  int? programRetryDelay,  // 新增参数
}) async {
  // ...
  _flashWorker = FlashWorker(
    // ...
    initTimeout: initTimeout ?? 50,
    initMaxRetries: initMaxRetries ?? 100,
    programRetryDelay: programRetryDelay ?? 50,  // 传递参数
  );
  // ...
}
```

### 5. FlashWorker 层

**文件**: `lib/data/services/flash_worker.dart`

#### 5.1 构造函数

```dart
FlashWorker({
  required this.bluetoothDatasource,
  required this.frameBuilder,
  required this.frameParser,
  required this.protocolConfig,
  required this.onLog,
  this.onTxData,
  this.initTimeout = 50,
  this.initMaxRetries = 100,
  this.programRetryDelay = 50,  // 新增参数
});
```

#### 5.2 重试逻辑

```dart
void _retryOrFail({bool immediate = false}) {
  _retryCount++;
  if (_retryCount < 20) {
    if (!immediate) {
      // 使用配置的重试延迟
      Future.delayed(Duration(milliseconds: programRetryDelay), () {
        if (_state == FlashState.waitProgram) {
          _transitionTo(FlashState.program);
        }
      });
    } else {
      _transitionTo(FlashState.program);
    }
  } else {
    onLog('编程失败，已重试 20 次');
    _completer?.complete(const Left(FlashProgramFailure('编程失败，重试次数过多')));
    _transitionTo(FlashState.failed);
  }
}
```

**关键改动**:
- 将硬编码的 `50ms` 改为使用 `programRetryDelay` 参数
- 保持其他重试逻辑不变

## 文件变更清单

| 文件路径 | 变更类型 | 说明 |
|---------|---------|------|
| `lib/presentation/providers/flash_providers.dart` | 新增 | 添加 `programRetryDelayProvider` |
| `lib/presentation/screens/flash_screen.dart` | 修改 | 添加 UI 配置项，更新设置对话框 |
| `lib/domain/usecases/flash_firmware_usecase.dart` | 修改 | 添加 `programRetryDelay` 参数 |
| `lib/domain/repositories/communication_repository.dart` | 修改 | 接口添加 `programRetryDelay` 参数 |
| `lib/data/repositories/communication_repository_impl.dart` | 修改 | 实现添加 `programRetryDelay` 参数 |
| `lib/data/services/flash_worker.dart` | 修改 | 使用配置的延迟值 |

## 使用说明

### 1. 打开设置对话框

1. 进入烧录页面
2. 点击"烧录设置"区域右侧的调整按钮（齿轮图标）

### 2. 调整编程重试延迟

1. 在弹出的对话框中找到"编程重试延迟"滑块
2. 拖动滑块调整延迟时间 (10-500ms)
3. 实时显示当前值
4. 点击"关闭"保存设置

### 3. 开始烧录

1. 选择固件文件
2. 确认设置正确
3. 点击"开始烧录"按钮
4. 烧录过程将使用配置的延迟值

## 配置建议

### 不同场景的推荐值

| 场景 | 推荐延迟 | 说明 |
|------|---------|------|
| **稳定环境** | 50ms (默认) | 适合信号良好、设备响应快的情况 |
| **信号不稳定** | 100-200ms | 增加延迟可提高成功率 |
| **设备响应慢** | 200-300ms | 给设备更多处理时间 |
| **极端情况** | 300-500ms | 最大延迟，适合非常不稳定的环境 |
| **快速测试** | 10-30ms | 仅用于测试，可能导致失败率增加 |

### 调优建议

1. **从默认值开始**: 50ms 适合大多数情况
2. **逐步增加**: 如果烧录失败，每次增加 50ms
3. **观察日志**: 查看重试次数，如果频繁重试则增加延迟
4. **平衡速度和稳定性**: 延迟越大越稳定，但烧录时间越长

## 技术细节

### 1. 为什么选择 10-500ms 范围？

- **下限 10ms**: 低于 10ms 可能导致设备来不及响应
- **上限 500ms**: 超过 500ms 会显著增加烧录时间，用户体验差
- **默认 50ms**: 经过测试，50ms 在速度和稳定性之间取得良好平衡

### 2. 为什么不持久化配置？

- **简化实现**: 避免引入 SharedPreferences 依赖
- **会话级配置**: 用户可以根据当前环境临时调整
- **未来扩展**: 如需持久化，可以轻松添加 SharedPreferences 支持

### 3. 重试延迟的作用

编程阶段重试延迟影响以下场景:
- **CRC 校验失败**: 数据块 CRC 不匹配时重试
- **超时重试**: 等待设备响应超时后重试
- **通信错误**: 蓝牙通信出错后重试

延迟时间决定了两次重试之间的间隔，适当的延迟可以:
- 给设备足够的处理时间
- 避免过快重试导致设备缓冲区溢出
- 提高烧录成功率

## 测试验证

### 1. 编译测试

```bash
flutter analyze lib/presentation/screens/flash_screen.dart \
  lib/presentation/providers/flash_providers.dart \
  lib/data/services/flash_worker.dart \
  lib/domain/usecases/flash_firmware_usecase.dart \
  lib/domain/repositories/communication_repository.dart \
  lib/data/repositories/communication_repository_impl.dart
```

**结果**: ✅ 通过 (仅 2 个 info 级别的代码风格提示)

### 2. 构建测试

```bash
flutter build apk --debug --target-platform android-arm64
```

**结果**: ✅ 构建成功

### 3. 功能测试清单

- [ ] UI 显示正确：设置区域显示编程重试延迟
- [ ] 对话框正常：点击调整按钮弹出设置对话框
- [ ] 滑块工作：可以拖动滑块调整延迟值 (10-500ms)
- [ ] 实时更新：滑块值实时显示
- [ ] 参数传递：配置值正确传递到 FlashWorker
- [ ] 烧录功能：使用配置的延迟值进行重试
- [ ] 日志输出：日志中显示配置的延迟值

## 后续优化建议

### 1. 持久化配置

添加 SharedPreferences 支持，保存用户配置:

```dart
// 保存配置
final prefs = await SharedPreferences.getInstance();
await prefs.setInt('programRetryDelay', value);

// 加载配置
final programRetryDelayProvider = StateProvider<int>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getInt('programRetryDelay') ?? 50;
});
```

### 2. 预设配置

添加快速选择预设:
- **快速模式**: 30ms (适合稳定环境)
- **标准模式**: 50ms (默认)
- **稳定模式**: 150ms (适合不稳定环境)
- **安全模式**: 300ms (最大稳定性)

### 3. 自动调优

根据烧录过程中的重试次数自动调整延迟:
- 如果重试次数 > 10，自动增加 50ms
- 如果连续成功，自动减少 10ms
- 记录最佳延迟值供下次使用

### 4. 统计信息

显示烧录统计:
- 平均重试次数
- 成功率
- 推荐延迟值

## 总结

本次实现完成了以下目标:

✅ 添加编程阶段重试延迟配置功能
✅ 在烧录页面设置对话框中添加 UI 控件
✅ 配置范围 10-500ms，默认 50ms
✅ 完整的参数传递链路
✅ 代码编译通过，构建成功

### 关键改进

1. **用户可控**: 用户可以根据实际情况调整延迟
2. **灵活性**: 支持 10-500ms 的宽范围调整
3. **易用性**: 通过滑块直观调整，实时显示
4. **兼容性**: 保持默认值 50ms，不影响现有行为
5. **可扩展**: 架构清晰，易于添加更多配置项

### 用户价值

- **提高成功率**: 在信号不稳定时增加延迟可提高烧录成功率
- **节省时间**: 在稳定环境下减少延迟可加快烧录速度
- **灵活适配**: 适应不同的设备和通信环境
- **简单易用**: 无需修改代码，通过 UI 即可调整
