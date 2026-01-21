# Flutter 编程卡上位机 - 实施计划

## 计划概述

本计划将设计方案转化为可执行的步骤，每个步骤都有明确的验证方法。

---

## Batch 1: 项目初始化与基础框架

### Task 1.1: 初始化 Flutter 项目

**步骤**:
1. 进入 flutter 目录
2. 创建 Flutter 项目
3. 验证项目创建成功

**命令**:
```bash
cd /home/lemon/桌面/docs/plans/flutter
flutter create --org com.programmingcard --project-name programming_card_host .
```

**验证**:
```bash
flutter doctor
flutter analyze
```

**预期结果**: 
- 项目结构创建成功
- `flutter analyze` 无错误

---

### Task 1.2: 配置 pubspec.yaml

**步骤**:
1. 备份原有 pubspec.yaml
2. 更新依赖配置
3. 运行 flutter pub get

**需要添加的依赖**:
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # 状态管理
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.3.0
  
  # 蓝牙通信
  flutter_blue_plus: ^1.31.0
  
  # 权限管理
  permission_handler: ^11.0.0
  
  # 文件处理
  file_picker: ^6.0.0
  path_provider: ^2.1.0
  
  # 日志
  logger: ^2.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  
  # 代码生成
  riverpod_generator: ^2.3.0
  build_runner: ^2.4.0
```

**验证**:
```bash
flutter pub get
flutter pub outdated
```

**预期结果**: 
- 所有依赖安装成功
- 无版本冲突

---

### Task 1.3: 创建目录结构

**步骤**:
创建完整的项目目录结构

**命令**:
```bash
mkdir -p lib/core/constants
mkdir -p lib/core/utils
mkdir -p lib/core/errors
mkdir -p lib/data/models
mkdir -p lib/data/datasources
mkdir -p lib/data/repositories
mkdir -p lib/data/protocol
mkdir -p lib/domain/entities
mkdir -p lib/domain/repositories
mkdir -p lib/domain/usecases
mkdir -p lib/presentation/providers
mkdir -p lib/presentation/screens
mkdir -p lib/presentation/widgets
mkdir -p assets/config/groups
mkdir -p test/core/utils
mkdir -p test/data/protocol
```

**验证**:
```bash
tree -L 3 lib/
ls -la assets/config/
```

**预期结果**: 
- 所有目录创建成功
- 目录结构符合设计

---

## Batch 2: 核心工具层实现

### Task 2.1: 实现 CRC 计算器

**步骤**:
1. 创建 `lib/core/utils/crc_calculator.dart`
2. 实现 CRC16 MODBUS 算法
3. 实现 SUM8 校验算法
4. 创建单元测试

**文件**: `lib/core/utils/crc_calculator.dart`

**验证**:
```bash
flutter analyze lib/core/utils/crc_calculator.dart
flutter test test/core/utils/crc_calculator_test.dart
```

**预期结果**: 
- 代码无语法错误
- 所有测试通过
- CRC16 计算结果与 Python 版本一致

---

### Task 2.2: 实现 HEX 文件解析器

**步骤**:
1. 创建 `lib/core/utils/hex_parser.dart`
2. 实现 Intel HEX 格式解析
3. 实现数据分块功能
4. 创建单元测试

**文件**: `lib/core/utils/hex_parser.dart`

**验证**:
```bash
flutter analyze lib/core/utils/hex_parser.dart
flutter test test/core/utils/hex_parser_test.dart
```

**预期结果**: 
- 能正确解析 HEX 文件
- 数据分块功能正常
- 所有测试通过

---

### Task 2.3: 定义错误类型

**步骤**:
1. 创建 `lib/core/errors/failures.dart`
2. 定义 sealed class Failure
3. 定义具体错误类型
4. 实现错误消息转换

**文件**: `lib/core/errors/failures.dart`

**验证**:
```bash
flutter analyze lib/core/errors/failures.dart
```

**预期结果**: 
- 代码无语法错误
- 错误类型定义完整

---

## Batch 3: 协议层实现

### Task 3.1: 实现协议配置模型

**步骤**:
1. 创建 `lib/data/protocol/protocol_config.dart`
2. 定义 ProtocolConfig 类
3. 定义 ChecksumType 枚举
4. 实现 fromJson 方法

**文件**: `lib/data/protocol/protocol_config.dart`

**验证**:
```bash
flutter analyze lib/data/protocol/protocol_config.dart
```

**预期结果**: 
- 代码无语法错误
- JSON 解析功能正常

---

### Task 3.2: 实现帧构建器

**步骤**:
1. 创建 `lib/data/protocol/frame_builder.dart`
2. 实现读取请求帧构建
3. 实现写入帧构建
4. 实现烧录帧构建
5. 创建单元测试

**文件**: `lib/data/protocol/frame_builder.dart`

**验证**:
```bash
flutter analyze lib/data/protocol/frame_builder.dart
flutter test test/data/protocol/frame_builder_test.dart
```

**预期结果**: 
- 所有帧构建功能正常
- 校验值计算正确
- 所有测试通过

---

### Task 3.3: 实现帧解析器

**步骤**:
1. 创建 `lib/data/protocol/frame_parser.dart`
2. 实现帧解析逻辑
3. 实现校验验证
4. 创建单元测试

**文件**: `lib/data/protocol/frame_parser.dart`

**验证**:
```bash
flutter analyze lib/data/protocol/frame_parser.dart
flutter test test/data/protocol/frame_parser_test.dart
```

**预期结果**: 
- 帧解析功能正常
- 校验验证正确
- 所有测试通过

---

## Batch 4: 配置文件转换

### Task 4.1: 创建配置转换脚本

**步骤**:
1. 创建 `tools/convert_config.dart`
2. 实现 Protocol.csv 转换
3. 实现参数组 CSV 转换

**文件**: `tools/convert_config.dart`

**验证**:
```bash
cd tools
dart convert_config.dart
cd ..
ls -la assets/config/
cat assets/config/protocol.json
```

**预期结果**: 
- protocol.json 生成成功
- group_a.json 生成成功
- JSON 格式正确

---

### Task 4.2: 创建示例配置文件

**步骤**:
1. 创建 `assets/config/protocol.json`
2. 创建 `assets/config/groups/group_a.json`
3. 更新 pubspec.yaml 的 assets 配置

**验证**:
```bash
flutter pub get
flutter analyze
```

**预期结果**: 
- 配置文件格式正确
- assets 配置生效

---

## Batch 5: 数据模型定义

### Task 5.1: 定义设备实体

**步骤**:
1. 创建 `lib/domain/entities/device.dart`
2. 创建 `lib/data/models/device_info.dart`

**验证**:
```bash
flutter analyze lib/domain/entities/device.dart
flutter analyze lib/data/models/device_info.dart
```

**预期结果**: 
- 代码无语法错误
- 模型定义完整

---

### Task 5.2: 定义参数模型

**步骤**:
1. 创建 `lib/domain/entities/parameter_group.dart`
2. 创建 `lib/data/models/parameter.dart`

**验证**:
```bash
flutter analyze lib/domain/entities/parameter_group.dart
flutter analyze lib/data/models/parameter.dart
```

**预期结果**: 
- 代码无语法错误
- 模型定义完整

---

### Task 5.3: 定义烧录进度模型

**步骤**:
1. 创建 `lib/data/models/flash_progress.dart`
2. 使用 sealed class 定义状态

**验证**:
```bash
flutter analyze lib/data/models/flash_progress.dart
```

**预期结果**: 
- 代码无语法错误
- 状态定义完整

---

## Batch 6: 蓝牙通信层（基础）

### Task 6.1: 实现蓝牙数据源

**步骤**:
1. 创建 `lib/data/datasources/bluetooth_datasource.dart`
2. 实现设备扫描
3. 实现设备连接
4. 实现数据收发

**文件**: `lib/data/datasources/bluetooth_datasource.dart`

**验证**:
```bash
flutter analyze lib/data/datasources/bluetooth_datasource.dart
```

**预期结果**: 
- 代码无语法错误
- API 设计合理

---

### Task 6.2: 配置蓝牙权限

**步骤**:
1. 配置 iOS Info.plist
2. 配置 Android AndroidManifest.xml

**iOS 文件**: `ios/Runner/Info.plist`
**Android 文件**: `android/app/src/main/AndroidManifest.xml`

**验证**:
```bash
flutter build ios --debug --no-codesign
flutter build apk --debug
```

**预期结果**: 
- iOS 构建成功
- Android 构建成功
- 权限配置正确

---

## 验证检查点

每个 Batch 完成后，运行以下命令进行全面验证：

```bash
# 代码分析
flutter analyze

# 运行所有测试
flutter test

# 检查格式
dart format --set-exit-if-changed lib/ test/

# 检查依赖
flutter pub outdated
```

---

## 下一步计划

完成 Batch 1-6 后，继续实施：

- **Batch 7**: 仓储层实现
- **Batch 8**: 用例层实现
- **Batch 9**: 状态管理（Riverpod Providers）
- **Batch 10**: UI 界面实现
- **Batch 11**: 集成测试
- **Batch 12**: 真机测试与优化

---

**计划版本**: 1.0  
**创建日期**: 2026-01-17
