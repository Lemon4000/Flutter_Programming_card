# Android 连接取消黑屏问题修复

## 🐛 问题描述

**严重程度**: 🔴 严重

**问题**: Android 设备在连接过程中按返回键取消连接，会导致应用黑屏，无法恢复。

**影响范围**:
- Android 平台
- 蓝牙连接
- 串口连接

---

## 🔍 问题原因

### 根本原因
连接对话框的导航栈管理问题：

1. **显示连接对话框**：`showDialog()` 显示"正在连接..."对话框
2. **用户按返回键**：对话框被关闭，但 `dialogShown` 状态未更新
3. **连接操作完成**：代码尝试执行 `Navigator.of(context).pop()`
4. **导航栈错误**：尝试关闭一个已经不存在的对话框
5. **导航栈混乱**：导致应用进入错误状态，显示黑屏

### 技术细节

**原始代码问题**:
```dart
showDialog(
  context: context,
  barrierDismissible: false,  // 禁止点击外部关闭
  builder: (context) => AlertDialog(...),
);

// ... 连接操作 ...

Navigator.of(context).pop(); // ❌ 如果对话框已被返回键关闭，这里会出错
```

**问题场景**:
- 对话框设置了 `barrierDismissible: false`，但用户仍可以按返回键关闭
- 代码没有追踪对话框的实际状态
- 盲目调用 `pop()` 导致导航栈错误

---

## ✅ 修复方案

### 修复策略
使用状态标志追踪对话框是否仍然显示，只在对话框存在时才关闭它。

### 修复内容

#### 1. 添加对话框状态追踪
```dart
bool dialogShown = true;  // 追踪对话框状态
```

#### 2. 使用 WillPopScope 捕获返回键
```dart
showDialog(
  context: context,
  barrierDismissible: false,
  builder: (context) => WillPopScope(
    onWillPop: () async {
      // 用户按返回键时，标记对话框已关闭
      dialogShown = false;
      return true;  // 允许关闭
    },
    child: AlertDialog(...),
  ),
).then((_) {
  // 对话框被关闭时（任何方式），标记状态
  dialogShown = false;
});
```

#### 3. 条件关闭对话框
```dart
// 只有在对话框还显示时才关闭它
if (dialogShown) {
  Navigator.of(context).pop();
}
```

---

## 📝 修改的文件

### lib/presentation/screens/scan_screen.dart

#### 修改 1: 蓝牙连接方法 `_connectToDevice`

**位置**: 第 197-289 行

**修改内容**:
- 添加 `dialogShown` 状态标志
- 使用 `WillPopScope` 包装对话框
- 添加 `.then()` 回调更新状态
- 条件执行 `Navigator.pop()`

#### 修改 2: 串口连接方法 `_connectToSerialPort`

**位置**: 第 323-401 行

**修改内容**:
- 相同的修复策略
- 确保串口连接也不会出现黑屏问题

---

## 🧪 测试验证

### 测试场景 1: 蓝牙连接取消

**步骤**:
1. 打开应用
2. 点击一个蓝牙设备连接
3. 在"正在连接..."对话框显示时，按返回键
4. 观察应用状态

**预期结果**:
- ✅ 对话框关闭
- ✅ 应用返回设备列表
- ✅ 界面正常显示，无黑屏
- ✅ 可以继续操作

### 测试场景 2: 串口连接取消

**步骤**:
1. 切换到"串口"选项卡
2. 点击一个串口设备连接
3. 在"正在连接..."对话框显示时，按返回键
4. 观察应用状态

**预期结果**:
- ✅ 对话框关闭
- ✅ 应用返回设备列表
- ✅ 界面正常显示，无黑屏
- ✅ 可以继续操作

### 测试场景 3: 正常连接流程

**步骤**:
1. 连接设备
2. 等待连接完成（不按返回键）
3. 观察连接结果

**预期结果**:
- ✅ 对话框自动关闭
- ✅ 显示"已连接到 [设备名]"提示
- ✅ 界面正常，无黑屏

### 测试场景 4: 连接失败

**步骤**:
1. 连接一个无法连接的设备
2. 等待连接超时或失败
3. 观察错误处理

**预期结果**:
- ✅ 对话框自动关闭
- ✅ 显示错误提示
- ✅ 界面正常，无黑屏

---

## 🔧 构建和测试

### 构建 APK
```bash
cd ~/桌面/docs/plans/flutter
flutter build apk --debug
```

### 安装到 Android 设备
```bash
adb install build/app/outputs/flutter-apk/app-debug.apk
```

### 查看日志
```bash
adb logcat | grep flutter
```

---

## 📊 修复状态

- [x] 问题分析完成
- [x] 修复方案设计
- [x] 代码修改完成
- [x] 蓝牙连接修复
- [x] 串口连接修复
- [ ] Android 设备测试
- [ ] 验证修复效果

---

## 🎯 相关问题

这个修复也解决了以下相关问题：
1. ✅ 连接超时后的导航栈问题
2. ✅ 连接失败后的对话框关闭问题
3. ✅ 重连时的状态管理问题

---

## 💡 技术要点

### WillPopScope 的作用
- 捕获 Android 返回键事件
- 允许在对话框关闭前执行清理逻辑
- 更新应用状态以保持一致性

### 状态追踪的重要性
- 避免盲目操作导航栈
- 确保 UI 状态与实际状态一致
- 防止导航栈错误导致的黑屏

### 防御性编程
- 始终检查 `mounted` 状态
- 条件执行导航操作
- 多重保护机制

---

## 📚 参考资料

- [Flutter WillPopScope 文档](https://api.flutter.dev/flutter/widgets/WillPopScope-class.html)
- [Flutter Navigation 最佳实践](https://flutter.dev/docs/cookbook/navigation)
- [Dialog 生命周期管理](https://flutter.dev/docs/cookbook/navigation/dialogs)

---

**修复时间**: 2026-01-23
**修复版本**: 待发布
**测试状态**: 待 Android 设备验证
