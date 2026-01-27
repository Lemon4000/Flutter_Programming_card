# SnackBar 队列堵塞问题修复

## 🐛 问题描述

**问题**: 应用中的 SnackBar（底部提示）停留时间过长（2-3秒），导致：
1. 后续提示被阻塞在队列中
2. 用户看到的提示信息不是当前操作的
3. 提示信息延迟显示，造成混乱

**影响**: 所有使用 SnackBar 的地方

---

## ✅ 解决方案

### 1. 创建统一的 SnackBar 工具类

**文件**: `lib/core/utils/snackbar_helper.dart`

**功能**:
- ✅ 自动清除旧的 SnackBar
- ✅ 缩短显示时间（1-1.5秒）
- ✅ 统一样式和图标
- ✅ 类型化方法（success, error, warning, info）

**使用方法**:
```dart
// 成功提示（1秒）
SnackBarHelper.showSuccess(context, '已连接到设备');

// 错误提示（1.5秒）
SnackBarHelper.showError(context, '连接失败');

// 警告提示（1.5秒）
SnackBarHelper.showWarning(context, '已断开连接');

// 信息提示（1秒）
SnackBarHelper.showInfo(context, '正在扫描...');
```

### 2. 关键特性

#### 自动清除队列
```dart
// 显示新 SnackBar 前先清除旧的
ScaffoldMessenger.of(context).clearSnackBars();
```

#### 缩短显示时间
- 成功/信息：1秒
- 错误/警告：1.5秒
- 原来：2-3秒

#### 统一样式
- 浮动样式（floating）
- 圆角边框
- 带图标
- 一致的间距和阴影

---

## 📝 需要修改的文件

### 已修改
1. ✅ `lib/core/utils/snackbar_helper.dart` - 新建工具类
2. ✅ `lib/presentation/screens/home_screen.dart` - 已更新

### 待修改
3. ⏳ `lib/presentation/screens/scan_screen.dart` - 5处
4. ⏳ `lib/presentation/screens/parameter_screen.dart`
5. ⏳ `lib/presentation/screens/flash_screen.dart`
6. ⏳ `lib/presentation/screens/log_screen.dart`

---

## 🔧 修改指南

### 步骤 1: 添加导入
```dart
import '../../core/utils/snackbar_helper.dart';
```

### 步骤 2: 替换 SnackBar 调用

**原代码**:
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('已连接到设备'),
    backgroundColor: Colors.green,
    duration: const Duration(seconds: 2),
  ),
);
```

**新代码**:
```dart
SnackBarHelper.showSuccess(context, '已连接到设备');
```

### 步骤 3: 根据类型选择方法

| 原 backgroundColor | 新方法 | 默认时长 |
|-------------------|--------|---------|
| Colors.green | `showSuccess` | 1秒 |
| Colors.red | `showError` | 1.5秒 |
| Colors.orange | `showWarning` | 1.5秒 |
| Colors.blue | `showInfo` | 1秒 |

---

## 📋 scan_screen.dart 修改清单

### 位置 1: 第 250 行 - 连接失败
```dart
// 原代码
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(failure.toUserMessage()),
    backgroundColor: Colors.red,
    duration: const Duration(seconds: 3),
  ),
);

// 新代码
SnackBarHelper.showError(context, failure.toUserMessage());
```

### 位置 2: 第 265 行 - 连接成功
```dart
// 原代码
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('已连接到 ${device.name}'),
    backgroundColor: Colors.green,
    duration: const Duration(seconds: 2),
  ),
);

// 新代码
SnackBarHelper.showSuccess(context, '已连接到 ${device.name}');
```

### 位置 3: 第 282 行 - 连接超时
```dart
// 原代码
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('连接超时: ${e.toString()}'),
    backgroundColor: Colors.red,
    duration: const Duration(seconds: 3),
  ),
);

// 新代码
SnackBarHelper.showError(context, '连接超时: ${e.toString()}');
```

### 位置 4: 第 379 行 - 串口连接成功
```dart
// 原代码
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('已连接到 ${device.name}'),
    backgroundColor: Colors.green,
    duration: const Duration(seconds: 2),
  ),
);

// 新代码
SnackBarHelper.showSuccess(context, '已连接到 ${device.name}');
```

### 位置 5: 第 394 行 - 串口连接失败
```dart
// 原代码
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('连接失败: $e'),
    backgroundColor: Colors.red,
    duration: const Duration(seconds: 3),
  ),
);

// 新代码
SnackBarHelper.showError(context, '连接失败: $e');
```

---

## 🎯 预期效果

### 修复前
- ❌ SnackBar 显示 2-3 秒
- ❌ 多个提示排队等待
- ❌ 看到过时的提示信息
- ❌ 用户体验混乱

### 修复后
- ✅ SnackBar 显示 1-1.5 秒
- ✅ 新提示立即显示（清除旧的）
- ✅ 提示信息及时准确
- ✅ 用户体验流畅

---

## 🧪 测试场景

### 场景 1: 快速连接多个设备
1. 快速点击多个设备尝试连接
2. 观察提示信息

**预期**: 每次只显示最新的提示，不会堆积

### 场景 2: 连接失败后重试
1. 连接一个设备失败
2. 立即重试连接

**预期**: 失败提示快速消失，新的连接提示立即显示

### 场景 3: 频繁操作
1. 快速进行多个操作（扫描、连接、断开）
2. 观察提示信息

**预期**: 提示信息跟随操作，不延迟

---

## 📊 修改进度

- [x] 创建 SnackBarHelper 工具类
- [x] 修改 home_screen.dart (2处)
- [ ] 修改 scan_screen.dart (5处)
- [ ] 修改 parameter_screen.dart
- [ ] 修改 flash_screen.dart
- [ ] 修改其他文件

---

## 💡 最佳实践

### 1. 始终使用 SnackBarHelper
```dart
// ✅ 好
SnackBarHelper.showSuccess(context, '操作成功');

// ❌ 避免
ScaffoldMessenger.of(context).showSnackBar(...);
```

### 2. 选择合适的提示类型
- 成功操作 → `showSuccess`
- 错误/失败 → `showError`
- 警告/注意 → `showWarning`
- 一般信息 → `showInfo`

### 3. 保持消息简洁
```dart
// ✅ 好
SnackBarHelper.showSuccess(context, '已连接');

// ❌ 太长
SnackBarHelper.showSuccess(context, '设备连接操作已经成功完成，您现在可以进行下一步操作了');
```

### 4. 自定义时长（如需要）
```dart
// 需要更长时间显示
SnackBarHelper.showError(
  context,
  '严重错误信息',
  duration: Duration(seconds: 3),
);
```

---

**创建时间**: 2026-01-23
**状态**: 部分完成
**下一步**: 完成 scan_screen.dart 的修改
