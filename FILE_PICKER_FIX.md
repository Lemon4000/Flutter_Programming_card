# Android 文件选择器 `.hex` 扩展名错误修复

## 🐛 问题描述

**错误日志**:
```
W/FilePickerUtils(29467): Custom file type hex is unsupported and will be ignored.
D/FilePickerUtils(29467): Allowed file extensions mimes: []
I/flutter (29467): [MethodChannelFilePicker] Platform exception: PlatformException(FilePicker, Unsupported filter. Make sure that you are only using the extension without the dot, (ie., jpg instead of .jpg). This could also have happened because you are using an unsupported file extension. If the problem persists, you may want to consider using FileType.any instead., null, null)
```

**问题**: Android 平台上使用 `FileType.custom` 配合 `allowedExtensions: ['hex']` 会导致错误，因为 Android 的文件选择器不支持自定义扩展名过滤。

**影响**:
- 调试界面无法选择 HEX 文件
- 应用崩溃或文件选择失败

---

## 🔍 问题根源

### 错误代码
**文件**: `lib/presentation/screens/debug_screen.dart` (第 406-409 行)

```dart
final result = await FilePicker.platform.pickFiles(
  type: FileType.custom,
  allowedExtensions: ['hex'],
);
```

### 原因分析
1. **Android 文件选择器限制**: Android 的文件选择器不支持自定义文件扩展名过滤
2. **跨平台差异**: `FileType.custom` 在 iOS/Desktop 可以工作，但在 Android 上会抛出异常
3. **解决方案**: 使用 `FileType.any` 允许选择所有文件，然后在代码中验证扩展名

---

## ✅ 修复方案

### 修复策略
1. 使用 `FileType.any` 代替 `FileType.custom`
2. 在文件选择后验证文件扩展名
3. 如果扩展名不对，显示错误提示并返回

### 修复内容

#### 修改文件: `lib/presentation/screens/debug_screen.dart`

**添加导入**:
```dart
import '../../core/utils/snackbar_helper.dart';
```

**修复方法**: `_pickHexFile()`

**原代码**:
```dart
Future<void> _pickHexFile() async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['hex'],
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      final name = result.files.single.name;

      // 加载 HEX 文件
      final hexFile = await FirmwareFile.fromHexFile(path, name);

      ref.read(debugHexFileProvider.notifier).state = hexFile;
      ref.read(debugBlockIndexProvider.notifier).state = 0;

      addDebugLog(ref, '已加载 HEX 文件: $name (${hexFile.dataBlocks?.length ?? 0} 个数据块)');
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载 HEX 文件失败: $e')),
      );
    }
  }
}
```

**新代码**:
```dart
Future<void> _pickHexFile() async {
  try {
    // 使用 FileType.any，因为 Android 不支持 .hex 自定义扩展名
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;

      // 验证文件扩展名
      if (!path.toLowerCase().endsWith('.hex')) {
        if (mounted) {
          SnackBarHelper.showError(context, '请选择 .hex 格式的文件');
        }
        return;
      }

      final name = result.files.single.name;

      // 加载 HEX 文件
      final hexFile = await FirmwareFile.fromHexFile(path, name);

      ref.read(debugHexFileProvider.notifier).state = hexFile;
      ref.read(debugBlockIndexProvider.notifier).state = 0;

      addDebugLog(ref, '已加载 HEX 文件: $name (${hexFile.dataBlocks?.length ?? 0} 个数据块)');
    }
  } catch (e) {
    if (mounted) {
      SnackBarHelper.showError(context, '加载 HEX 文件失败: $e');
    }
  }
}
```

### 额外修复

同时将 `debug_screen.dart` 中的旧 SnackBar 调用替换为 `SnackBarHelper`，保持代码一致性。

---

## 📋 相关文件

### 已验证正确的实现
**文件**: `lib/data/datasources/firmware_datasource.dart` (第 56-89 行)

这个文件已经正确实现了文件选择和验证逻辑：

```dart
Future<FirmwareFile?> pickFirmwareFile() async {
  try {
    // 使用 FileType.any 因为 Android 不支持 .hex 扩展名
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.first;
    final filePath = file.path;

    if (filePath == null) {
      return null;
    }

    // 验证文件扩展名
    if (!filePath.toLowerCase().endsWith('.hex')) {
      print('选择的文件不是 .hex 文件: $filePath');
      throw Exception('请选择 .hex 格式的固件文件');
    }

    // 获取文件大小
    final fileSize = await File(filePath).length();

    return FirmwareFile.fromPath(filePath, fileSize);
  } catch (e) {
    print('选择固件文件失败: $e');
    rethrow;
  }
}
```

---

## 🧪 测试验证

### 测试场景 1: 选择正确的 HEX 文件

**步骤**:
1. 打开调试界面
2. 点击"选择 HEX 文件"按钮
3. 在文件选择器中选择一个 `.hex` 文件

**预期结果**:
- ✅ 文件选择成功
- ✅ 文件被正确加载
- ✅ 显示"已加载 HEX 文件: [文件名] ([N] 个数据块)"

### 测试场景 2: 选择非 HEX 文件

**步骤**:
1. 打开调试界面
2. 点击"选择 HEX 文件"按钮
3. 在文件选择器中选择一个 `.txt` 或其他格式文件

**预期结果**:
- ✅ 显示错误提示"请选择 .hex 格式的文件"
- ✅ 文件不会被加载
- ✅ 可以重新选择文件

### 测试场景 3: 取消选择

**步骤**:
1. 打开调试界面
2. 点击"选择 HEX 文件"按钮
3. 在文件选择器中点击"取消"

**预期结果**:
- ✅ 文件选择器关闭
- ✅ 不显示任何错误提示
- ✅ 界面状态保持不变

---

## 💡 最佳实践

### 1. 跨平台文件选择策略

```dart
// ✅ 推荐：使用 FileType.any + 代码验证
final result = await FilePicker.platform.pickFiles(
  type: FileType.any,
);

if (result != null) {
  final path = result.files.single.path!;

  // 在代码中验证扩展名
  if (!path.toLowerCase().endsWith('.hex')) {
    showError('请选择 .hex 文件');
    return;
  }

  // 处理文件...
}

// ❌ 避免：使用 FileType.custom（在某些平台上不支持）
final result = await FilePicker.platform.pickFiles(
  type: FileType.custom,
  allowedExtensions: ['hex'],  // Android 不支持
);
```

### 2. 扩展名验证

```dart
// ✅ 使用 toLowerCase() 进行大小写不敏感的比较
if (!path.toLowerCase().endsWith('.hex')) {
  // 错误处理
}

// ❌ 大小写敏感的比较可能会漏掉某些文件
if (!path.endsWith('.hex')) {
  // 可能无法匹配 .HEX 或 .Hex 文件
}
```

### 3. 用户体验

```dart
// ✅ 提供清晰的错误提示
if (!path.toLowerCase().endsWith('.hex')) {
  SnackBarHelper.showError(context, '请选择 .hex 格式的文件');
  return;
}

// ✅ 使用统一的 SnackBarHelper
SnackBarHelper.showError(context, message);

// ❌ 使用不一致的错误提示方式
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(message)),
);
```

---

## 🔧 其他 SnackBar 修复

在修复文件选择器问题的同时，也将以下文件的旧 SnackBar 调用替换为 `SnackBarHelper`：

### 已修复文件
1. ✅ `lib/presentation/screens/debug_screen.dart` - 文件选择器修复 + SnackBar 替换
2. ✅ `lib/presentation/screens/parameter_screen.dart` - `_showMessage()` 方法重构
3. ✅ `lib/presentation/screens/flash_screen.dart` - 3 处 SnackBar 替换
4. ✅ `lib/presentation/screens/scan_screen.dart` - 串口连接错误提示替换

### 替换映射

| 原 backgroundColor | 新方法 | 默认时长 |
|-------------------|--------|----------|
| Colors.green | `showSuccess` | 1秒 |
| Colors.red | `showError` | 1.5秒 |
| Colors.orange | `showWarning` | 1.5秒 |
| Colors.blue / 无 | `showInfo` | 1秒 |

---

## 📊 修复状态

- [x] 问题分析完成
- [x] 修复方案设计
- [x] debug_screen.dart 修复
- [x] 添加扩展名验证
- [x] SnackBar 统一替换
- [x] parameter_screen.dart 修复
- [x] flash_screen.dart 修复
- [x] scan_screen.dart 修复
- [ ] Android 设备测试

---

## 🎯 相关问题

这个修复也解决了以下相关问题：
1. ✅ Android 文件选择器兼容性
2. ✅ 跨平台文件选择统一策略
3. ✅ 文件验证的用户体验改进
4. ✅ SnackBar 显示一致性

---

## 📚 参考资料

- [file_picker 包文档](https://pub.dev/packages/file_picker)
- [Android 文件选择框架限制](https://developer.android.com/guide/topics/providers/document-provider)
- [Flutter 跨平台文件选择最佳实践](https://flutter.dev/docs/cookbook/picking-file)

---

**修复时间**: 2026-01-23
**修复版本**: 待发布
**测试状态**: 待 Android 设备验证
