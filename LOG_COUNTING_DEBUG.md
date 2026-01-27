# 日志计数调试指南

## 🔍 问题排查

如果数据帧（`!HEX:START...`）仍然没有计数，请按以下步骤排查：

---

## 📋 调试步骤

### 1. 启用日志记录

在日志页面，确保"记录中"按钮是激活状态（橙色）：
```
[记录中] ✅  （橙色，已激活）
[已暂停] ❌  （灰色，未激活）
```

### 2. 查看控制台输出

运行应用时，控制台会输出调试信息：

```bash
flutter run -d linux
```

**正常输出示例**:
```
[LOG] 添加 TX: !HEX:START0000,SIZE256,DATA...
[LOG] 添加新条目

[LOG] 添加 RX: #HEX:REPLY...
[LOG] 添加新条目

[LOG] 添加 TX: !HEX:START0100,SIZE256,DATA...
[LOG] 找到匹配的条目，索引: 0, 当前计数: 1
[LOG] 更新计数: 1 -> 2

[LOG] 添加 RX: #HEX:REPLY...
[LOG] 找到匹配的条目，索引: 1, 当前计数: 1
[LOG] 更新计数: 1 -> 2
```

### 3. 检查数据格式

数据帧必须包含以下关键字才会被识别为可计数的命令：
- `START` - 数据块发送命令
- `ESIZE` - 擦除大小命令
- `ENDCRC` - 验证 CRC 命令
- `REPLY` - 响应命令

**示例**:
```
✅ !HEX:START0000,SIZE256,DATA...  （包含 START，会计数）
✅ !HEX:ESIZE10;                   （包含 ESIZE，会计数）
✅ !HEX:ENDCRC1234;                （包含 ENDCRC，会计数）
✅ #HEX:REPLY[CRC];                （包含 REPLY，会计数）
❌ !HEX;                           （普通命令，完全匹配才计数）
```

---

## 🔧 代码逻辑

### 智能比较函数

```dart
bool hasSameData(List<int> other) {
  // 1. 提取可打印字符
  String bytesToString(List<int> bytes) {
    final buffer = StringBuffer();
    for (final b in bytes) {
      if (b >= 32 && b <= 126) {  // 只保留可打印字符
        buffer.writeCharCode(b);
      }
    }
    return buffer.toString();
  }

  final thisStr = bytesToString(data);
  final otherStr = bytesToString(other);

  // 2. 检查是否是数据帧命令
  final isThisDataFrame = thisStr.contains('START') ||
                         thisStr.contains('ESIZE') ||
                         thisStr.contains('ENDCRC') ||
                         thisStr.contains('REPLY');

  // 3. 如果是数据帧，只比较命令类型
  if (isThisDataFrame && isOtherDataFrame) {
    if (thisStr.contains('START') && otherStr.contains('START')) {
      return true;  // ✅ 所有 START 命令视为相同
    }
    // ... 其他命令类型
  }

  // 4. 普通命令，完全匹配
  return 逐字节比较;
}
```

### 查找逻辑

```dart
// 向后查找最近10条日志
for (int i = logsList.length - 1; i >= searchLimit; i--) {
  final log = logsList[i];
  if (log.direction == direction && log.hasSameData(data)) {
    foundIndex = i;  // 找到匹配的条目
    break;
  }
}

if (foundIndex != -1) {
  // 更新计数
  updatedLog = foundLog.copyWith(
    timestamp: now,
    count: foundLog.count + 1,
  );
}
```

---

## 🧪 测试场景

### 场景 1: 初始化阶段

**操作**: 发送多个 `!HEX;` 命令

**预期**:
```
控制台输出:
[LOG] 添加 TX: !HEX;
[LOG] 添加新条目
[LOG] 添加 TX: !HEX;
[LOG] 找到匹配的条目，索引: 0, 当前计数: 1
[LOG] 更新计数: 1 -> 2

UI 显示:
[TX] [x2] 最后: 10:00:01.00  !HEX;
```

### 场景 2: 编程阶段

**操作**: 发送多个 `!HEX:START...` 数据帧

**预期**:
```
控制台输出:
[LOG] 添加 TX: !HEX:START0000,SIZE256,DATA...
[LOG] 添加新条目
[LOG] 添加 TX: !HEX:START0100,SIZE256,DATA...
[LOG] 找到匹配的条目，索引: 0, 当前计数: 1
[LOG] 更新计数: 1 -> 2
[LOG] 添加 TX: !HEX:START0200,SIZE256,DATA...
[LOG] 找到匹配的条目，索引: 0, 当前计数: 2
[LOG] 更新计数: 2 -> 3

UI 显示:
[TX] [x3] 最后: 10:00:01.20  !HEX:START0200,SIZE256,DATA...
```

### 场景 3: 交替发送接收

**操作**: TX 和 RX 交替

**预期**:
```
控制台输出:
[LOG] 添加 TX: !HEX:START0000...
[LOG] 添加新条目
[LOG] 添加 RX: #HEX:REPLY...
[LOG] 添加新条目
[LOG] 添加 TX: !HEX:START0100...
[LOG] 找到匹配的条目，索引: 0, 当前计数: 1
[LOG] 更新计数: 1 -> 2
[LOG] 添加 RX: #HEX:REPLY...
[LOG] 找到匹配的条目，索引: 1, 当前计数: 1
[LOG] 更新计数: 1 -> 2

UI 显示:
[TX] [x2] 最后: 10:00:01.10  !HEX:START0100...
[RX] [x2] 最后: 10:00:01.15  #HEX:REPLY...
```

---

## 🐛 常见问题

### 问题 1: 日志没有显示

**原因**: 日志记录未启用

**解决**: 点击"已暂停"按钮，切换为"记录中"状态

### 问题 2: 所有数据都添加新条目，没有计数

**原因**:
1. 数据格式不包含关键字（START、ESIZE、ENDCRC、REPLY）
2. 方向不同（TX 和 RX 分别计数）

**解决**:
1. 检查控制台输出，确认数据包含关键字
2. 确认是相同方向的数据

### 问题 3: 计数徽章没有显示

**原因**: 计数为 1 时不显示徽章

**解决**: 这是正常的，只有计数 > 1 时才显示 `[x数字]` 徽章

### 问题 4: 不同的数据被合并了

**原因**: 智能比较只看命令类型，不看数据内容

**解决**: 这是预期行为，所有 `START` 命令会合并计数

---

## 📝 调试清单

使用以下清单排查问题：

- [ ] 日志记录已启用（"记录中"按钮是橙色）
- [ ] 控制台有 `[LOG]` 输出
- [ ] 数据包含关键字（START、ESIZE、ENDCRC、REPLY）
- [ ] 相同方向的数据（TX 或 RX）
- [ ] 查看控制台是否输出"找到匹配的条目"
- [ ] 查看控制台是否输出"更新计数"
- [ ] UI 上是否显示计数徽章 `[x数字]`

---

## 🔄 移除调试日志

测试完成后，可以移除调试日志以提高性能：

**文件**: `lib/presentation/providers/log_provider.dart`

**移除以下行**:
```dart
// 移除这些 print 语句
print('[LOG] 添加 $direction: ...');
print('[LOG] 找到匹配的条目，索引: $i, 当前计数: ${log.count}');
print('[LOG] 更新计数: ${foundLog.count} -> ${updatedLog.count}');
print('[LOG] 添加新条目');
```

---

## 📞 获取帮助

如果问题仍然存在，请提供以下信息：

1. **控制台完整输出**（包含 `[LOG]` 的部分）
2. **UI 截图**（显示日志列表）
3. **操作步骤**（如何触发问题）
4. **预期行为** vs **实际行为**

---

**创建时间**: 2026-01-23
**版本**: 1.0
**状态**: 调试中
