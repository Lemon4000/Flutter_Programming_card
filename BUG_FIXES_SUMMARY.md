# Bug 修复总结

## ✅ 已完成的修复

### 1. 蓝牙连接功能恢复 ✅
**问题**: Linux 桌面蓝牙连接失败 "bad state no element"
**修复**:
- 修改 `lib/presentation/providers/providers.dart`
- Linux/Android 使用原生 `BluetoothDatasource`
- Windows 使用 `CrossPlatformBluetoothDatasource`
**状态**: ✅ 已修复并测试

### 2. 连接后误报"已断开" ✅
**问题**: 每个平台连接设备后立即显示"设备连接已断开"
**修复**:
- 修改 `lib/presentation/screens/home_screen.dart`
- 添加 `_isInitialConnection` 标志
- 过滤初始的 disconnected 状态
**状态**: ✅ 已修复，需要测试

---

## ⏳ 部分完成的修复

### 3. Android 重连黑屏 ⚠️
**问题**: Android 设备断开后重连会黑屏
**已完成**:
- 在断开连接时重置 `_isInitialConnection` 标志
**还需要**:
- 在 Android 设备上实际测试
- 可能需要额外的状态清理逻辑
**状态**: ⚠️ 需要 Android 设备测试

---

## 📝 待完成的修复

### 4. 烧录无法停止 ⏳
**问题**:
- 烧录过程中无法停止
- 点击按钮后命令继续发送
- 重新烧录时状态未重置

**需要的修改**:

#### 4.1 添加停止烧录按钮
文件: `lib/presentation/screens/flash_screen.dart`

```dart
// 添加停止烧录方法
void _stopFlashing() {
  final worker = ref.read(currentFlashWorkerProvider);
  if (worker != null) {
    worker.abort();
    ref.read(currentFlashWorkerProvider.notifier).state = null;
  }
}

// 修改按钮逻辑
Widget _buildActionButtonSection(...) {
  final progress = ref.watch(flashProgressProvider);

  // 判断是否正在烧录
  final isFlashing = progress.status == FlashStatus.flashing ||
                     progress.status == FlashStatus.initializing ||
                     progress.status == FlashStatus.erasing ||
                     progress.status == FlashStatus.programming ||
                     progress.status == FlashStatus.verifying;

  if (isFlashing) {
    return ElevatedButton.icon(
      onPressed: _stopFlashing,
      icon: Icon(Icons.stop_rounded),
      label: Text('停止烧录'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade600,
      ),
    );
  }

  // ... 其他状态的按钮 ...
}
```

#### 4.2 在 Repository 中保存 Worker 实例
文件: `lib/data/repositories/communication_repository_impl.dart`

需要在创建 FlashWorker 时保存到 Provider：
```dart
final worker = FlashWorker(...);
ref.read(currentFlashWorkerProvider.notifier).state = worker;

// 烧录完成后清空
worker.startFlashWithBlocks(...).then((_) {
  ref.read(currentFlashWorkerProvider.notifier).state = null;
});
```

---

### 5. 参数界面不保存值 ⏳
**问题**: 每次进入参数界面都显示默认值

**需要的修改**:

#### 5.1 创建参数状态 Provider
文件: `lib/presentation/providers/parameter_providers.dart` (新建)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 当前参数值 Provider
final currentParametersProvider = StateProvider<Map<String, dynamic>>((ref) => {});

/// 原始参数值 Provider（用于比较差异）
final originalParametersProvider = StateProvider<Map<String, dynamic>>((ref) => {});

/// 参数是否已修改 Provider
final hasModifiedParametersProvider = Provider<bool>((ref) {
  final current = ref.watch(currentParametersProvider);
  final original = ref.watch(originalParametersProvider);

  if (current.isEmpty || original.isEmpty) return false;

  for (final key in current.keys) {
    if (current[key] != original[key]) return true;
  }
  return false;
});
```

#### 5.2 修改参数界面
文件: `lib/presentation/screens/parameter_screen.dart`

```dart
// 读取参数后保存
void _onReadSuccess(Map<String, dynamic> parameters) {
  // 保存当前值
  ref.read(currentParametersProvider.notifier).state = parameters;
  // 保存原始值（用于比较）
  ref.read(originalParametersProvider.notifier).state = Map.from(parameters);
}

// 界面显示保存的值
Widget build(BuildContext context) {
  final parameters = ref.watch(currentParametersProvider);
  // ... 使用 parameters 显示 ...
}

// 修改参数时更新状态
void _onParameterChanged(String key, dynamic value) {
  ref.read(currentParametersProvider.notifier).update((state) {
    return {...state, key: value};
  });
}
```

---

### 6. 参数修改无差异显示 ⏳
**问题**: 修改参数后看不出哪些被修改了

**需要的修改**:

#### 6.1 添加差异检查函数
```dart
bool isParameterModified(String key) {
  final current = ref.watch(currentParametersProvider);
  final original = ref.watch(originalParametersProvider);

  if (original.isEmpty) return false;
  return current[key] != original[key];
}
```

#### 6.2 修改参数显示 Widget
```dart
Widget _buildParameterItem(String key, dynamic value) {
  final isModified = isParameterModified(key);

  return Container(
    decoration: BoxDecoration(
      border: Border.all(
        color: isModified ? Colors.orange : Colors.grey.shade300,
        width: isModified ? 2 : 1,
      ),
      borderRadius: BorderRadius.circular(8),
      color: isModified ? Colors.orange.shade50 : null,
    ),
    child: ListTile(
      leading: isModified
        ? Icon(Icons.edit, color: Colors.orange)
        : Icon(Icons.settings),
      title: Text(key),
      subtitle: Text(value.toString()),
      trailing: isModified
        ? IconButton(
            icon: Icon(Icons.restore),
            tooltip: '恢复原始值',
            onPressed: () {
              final original = ref.read(originalParametersProvider);
              ref.read(currentParametersProvider.notifier).update((state) {
                return {...state, key: original[key]};
              });
            },
          )
        : null,
    ),
  );
}
```

#### 6.3 添加全局恢复按钮
```dart
// 在 AppBar 或底部添加
if (ref.watch(hasModifiedParametersProvider))
  TextButton.icon(
    icon: Icon(Icons.restore_page),
    label: Text('恢复全部'),
    onPressed: () {
      final original = ref.read(originalParametersProvider);
      ref.read(currentParametersProvider.notifier).state = Map.from(original);
    },
  )
```

---

## 🎯 修复优先级

### 高优先级（影响功能）:
1. ✅ 蓝牙连接恢复
2. ⏳ 烧录无法停止
3. ⚠️ Android 重连黑屏

### 中优先级（影响体验）:
4. ✅ 连接后误报断开
5. ⏳ 参数不保存

### 低优先级（改进体验）:
6. ⏳ 参数差异显示

---

## 📋 下一步行动

### 立即执行:
1. 完成烧录停止功能的代码修改
2. 在 Android 设备上测试重连问题

### 后续执行:
3. 实现参数持久化
4. 添加参数差异显示

---

## 🧪 测试清单

- [x] Linux: 蓝牙连接正常
- [x] Linux: 连接后不误报断开
- [ ] Android: 蓝牙连接正常
- [ ] Android: 重连不黑屏
- [ ] 所有平台: 烧录可以停止
- [ ] 所有平台: 参数值保持
- [ ] 所有平台: 修改的参数有标识

---

## 📁 修改的文件

### 已修改:
1. `lib/presentation/providers/providers.dart` - 蓝牙平台选择
2. `lib/presentation/screens/home_screen.dart` - 连接状态处理
3. `lib/presentation/providers/flash_providers.dart` - 添加 worker provider
4. `lib/data/datasources/cross_platform_bluetooth_datasource.dart` - 添加调试日志

### 待修改:
5. `lib/presentation/screens/flash_screen.dart` - 停止烧录按钮
6. `lib/data/repositories/communication_repository_impl.dart` - 保存 worker
7. `lib/presentation/providers/parameter_providers.dart` - 新建参数状态
8. `lib/presentation/screens/parameter_screen.dart` - 参数持久化和差异显示

---

**更新时间**: 2026-01-23
**完成度**: 2/6 (33%)
**下一个里程碑**: 完成烧录停止功能
