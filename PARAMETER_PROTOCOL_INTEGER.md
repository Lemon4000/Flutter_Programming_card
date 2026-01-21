# 参数写入协议整数化修改

## ✅ 已完成

成功将参数写入协议修改为整数格式，不再发送浮点数。

## 🔧 问题描述

### 之前的问题

虽然UI只能输入整数，但发送的协议帧仍然使用浮点数格式：

```
!WRITEA0:14.00,A1:60.00,A2:45.00;
```

这不符合整数要求。

### 根本原因

在 `frame_builder.dart` 中使用了 `toStringAsFixed(precision)` 方法：

```dart
final valueStr = value.toStringAsFixed(precision);  // 产生 "14.00"
```

## 🎯 解决方案

### 修改协议构建逻辑

**修改前**：
```dart
// 构建参数字符串: A0:14.00,A1:60.00
final parts = <String>[];
for (var key in sortedKeys) {
  final value = values[key]!;
  final precision = precisionMap[key] ?? 2;
  final valueStr = value.toStringAsFixed(precision);  // 浮点数格式
  parts.add('$key:$valueStr');
}
```

**修改后**：
```dart
// 构建参数字符串: A0:14,A1:60（整数格式）
final parts = <String>[];
for (var key in sortedKeys) {
  final value = values[key]!;
  // 转换为整数格式（不使用小数点）
  final valueStr = value.toInt().toString();  // 整数格式
  parts.add('$key:$valueStr');
}
```

## 📝 修改的文件

1. ✅ `lib/data/protocol/frame_builder.dart`
   - 修改 `buildWriteFrame()` 方法
   - 使用 `toInt().toString()` 替代 `toStringAsFixed()`
   - 更新注释说明

## 📊 效果对比

### 修改前 ❌

```
!WRITEA0:14.00,A1:60.00,A2:45.00,A3:665.00,A4:1000.00;
```

### 修改后 ✅

```
!WRITEA0:14,A1:60,A2:45,A3:665,A4:1000;
```

## 🎯 完整示例

### 输入参数

```
A0: 14
A1: 60
A2: 45
A3: 665
A4: 1000
```

### 生成的协议帧

```
!WRITEA0:14,A1:60,A2:45,A3:665,A4:1000;
```

### 完整帧（带前导码和校验）

```
[前导码]!WRITEA0:14,A1:60,A2:45,A3:665,A4:1000;[CRC]
```

## 🔍 技术细节

### 数据流程

```
用户输入整数 (100)
    ↓
存储为 double (100.0)
    ↓
转换为整数 (100)
    ↓
转换为字符串 ("100")
    ↓
构建协议帧 ("A0:100")
    ↓
发送到设备
```

### 为什么内部使用 double？

虽然最终发送整数，但内部仍使用 `double` 类型：

1. **兼容性**：保持与现有API的兼容
2. **灵活性**：未来可能需要支持浮点数
3. **精度**：整数→double→整数不会丢失精度

### 转换方法

```dart
double value = 14.0;
int intValue = value.toInt();        // 14
String strValue = intValue.toString(); // "14"
```

## 🧪 测试步骤

### 1. 编译运行

```bash
flutter clean
flutter pub get
./run-linux.sh
```

### 2. 测试写入

1. 连接设备
2. 进入参数设置页面
3. 输入参数值（整数）
4. 点击"写入参数"
5. 观察发送的协议帧

### 3. 验证格式

查看日志输出，确认格式为：

```
!WRITEA0:14,A1:60,A2:45;
```

而不是：

```
!WRITEA0:14.00,A1:60.00,A2:45.00;
```

## 📋 完整的参数写入流程

### 1. UI输入

```
参数A0: [100]  ← 只能输入整数
参数A1: [200]
```

### 2. 数据收集

```dart
final values = <String, double>{
  'A0': 100.0,
  'A1': 200.0,
};
```

### 3. 协议构建

```dart
// 转换为整数字符串
'A0:100'
'A1:200'

// 组合
'!WRITEA0:100,A1:200;'
```

### 4. 发送

```
[前导码]!WRITEA0:100,A1:200;[CRC]
```

## ⚙️ 配置说明

### precisionMap 参数

虽然 `buildWriteFrame()` 仍接受 `precisionMap` 参数，但现在已被忽略：

```dart
List<int> buildWriteFrame(
  String group,
  Map<String, double> values,
  Map<String, int> precisionMap,  // 已废弃，保留兼容性
)
```

这是为了保持API兼容性，避免修改调用代码。

### 如果需要恢复浮点数

如果将来需要恢复浮点数格式，只需修改一行：

```dart
// 整数格式
final valueStr = value.toInt().toString();

// 浮点数格式
final valueStr = value.toStringAsFixed(precision);
```

## 🔧 相关修改

### 1. UI层（已完成）

- ✅ 输入框只允许整数
- ✅ 显示值为整数格式
- ✅ 范围提示显示整数

### 2. 协议层（本次修改）

- ✅ 协议帧使用整数格式
- ✅ 不再包含小数点
- ✅ 发送整数值

### 3. 数据层

- ✅ 内部使用 double（兼容性）
- ✅ 转换为整数发送
- ✅ 无精度损失

## 📊 性能影响

- **转换开销**: 几乎为零（toInt() 是O(1)操作）
- **协议大小**: 减小（"14" vs "14.00"）
- **传输速度**: 略微提升（数据更少）

## ✅ 验证清单

- ✅ UI只能输入整数
- ✅ 协议帧不包含小数点
- ✅ 发送的值是整数格式
- ✅ 代码编译无错误
- ✅ 兼容现有API

## 🎉 总结

成功将参数写入协议改为整数格式：

- 🔢 **纯整数**：协议帧只包含整数，无小数点
- 📏 **更简洁**：数据更短，传输更快
- ✅ **完全一致**：UI输入、显示、发送全部整数
- 🔄 **向后兼容**：保持API兼容性
- 🎯 **符合要求**：完全满足整数要求

现在发送的协议帧格式为：

```
!WRITEA0:14,A1:60,A2:45,A3:665,A4:1000;
```

完全是整数格式，没有小数点！

---

**修改时间**: 2026-01-21
**修改文件**: `lib/data/protocol/frame_builder.dart`
**状态**: ✅ 已完成并测试
