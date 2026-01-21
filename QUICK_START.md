# Flutter 重构项目快速开始指南

## 前置准备

### 1. 安装 Flutter SDK
```bash
# 下载 Flutter SDK
# 访问: https://flutter.dev/docs/get-started/install

# 验证安装
flutter doctor
```

### 2. 配置开发环境

**iOS 开发**:
- 安装 Xcode
- 安装 CocoaPods: `sudo gem install cocoapods`

**Android 开发**:
- 安装 Android Studio
- 配置 Android SDK

## 项目初始化

### 1. 创建 Flutter 项目

```bash
cd /home/lemon/桌面/docs/plans/flutter
flutter create --org com.programmingcard --project-name programming_card_host .
```

### 2. 配置 pubspec.yaml

```yaml
name: programming_card_host
description: 编程卡上位机 Flutter 版本
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

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
  
  # UI组件
  flutter_hooks: ^0.20.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  
  # 代码生成
  riverpod_generator: ^2.3.0
  build_runner: ^2.4.0
  
  # 测试
  mockito: ^5.4.0

flutter:
  uses-material-design: true
  
  assets:
    - assets/config/
    - assets/config/groups/
```

### 3. 安装依赖

```bash
flutter pub get
```

## 配置文件转换

### 1. 创建配置转换脚本

```bash
mkdir -p tools
```

创建 `tools/convert_config.dart`:

```dart
import 'dart:io';
import 'dart:convert';

void main() {
  // 转换 Protocol.csv 到 protocol.json
  convertProtocolConfig();
  
  // 转换 A组.csv 到 group_a.json
  convertGroupConfig('A');
}

void convertProtocolConfig() {
  final csvFile = File('../编程卡上位机/config/Protocol.csv');
  if (!csvFile.existsSync()) {
    print('Protocol.csv 不存在');
    return;
  }
  
  final lines = csvFile.readAsLinesSync();
  final config = <String, dynamic>{};
  
  for (var line in lines.skip(1)) {
    final parts = line.split(',');
    if (parts.length >= 2) {
      final key = parts[0].trim();
      final value = parts[1].trim();
      
      switch (key) {
        case 'Preamble':
          config['preamble'] = value;
          break;
        case 'Checksum':
          config['checksum'] = value;
          break;
        case 'Baud':
          config['baudRate'] = int.tryParse(value) ?? 2000000;
          break;
        case 'TxStart':
          config['txStart'] = value;
          break;
        case 'RxStart':
          config['rxStart'] = value;
          break;
      }
    }
  }
  
  final outputFile = File('assets/config/protocol.json');
  outputFile.parent.createSync(recursive: true);
  outputFile.writeAsStringSync(
    JsonEncoder.withIndent('  ').convert(config)
  );
  
  print('✓ protocol.json 已生成');
}

void convertGroupConfig(String group) {
  final csvFile = File('../编程卡上位机/config/${group}组.csv');
  if (!csvFile.existsSync()) {
    print('${group}组.csv 不存在');
    return;
  }
  
  final lines = csvFile.readAsLinesSync();
  final parameters = <Map<String, dynamic>>[];
  
  for (var line in lines.skip(1)) {
    final parts = line.split(',');
    if (parts.length >= 6) {
      parameters.add({
        'key': parts[0].trim(),
        'name': parts[1].trim(),
        'unit': parts[2].trim(),
        'min': double.tryParse(parts[3].trim()) ?? 0.0,
        'max': double.tryParse(parts[4].trim()) ?? 100.0,
        'precision': int.tryParse(parts[5].trim()) ?? 2,
        'default': double.tryParse(parts[6].trim()) ?? 0.0,
      });
    }
  }
  
  final config = {
    'name': '${group}组',
    'parameters': parameters,
  };
  
  final outputFile = File('assets/config/groups/group_${group.toLowerCase()}.json');
  outputFile.parent.createSync(recursive: true);
  outputFile.writeAsStringSync(
    JsonEncoder.withIndent('  ').convert(config)
  );
  
  print('✓ group_${group.toLowerCase()}.json 已生成');
}
```

### 2. 运行转换脚本

```bash
cd tools
dart convert_config.dart
cd ..
```

## 权限配置

### iOS 权限 (ios/Runner/Info.plist)

在 `<dict>` 标签内添加:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>需要蓝牙权限以连接编程卡设备</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>需要蓝牙权限以连接编程卡设备</string>
```

### Android 权限 (android/app/src/main/AndroidManifest.xml)

在 `<manifest>` 标签内添加:

```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" 
                 android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

在 `<application>` 标签内添加:

```xml
<application
    android:label="编程卡上位机"
    ...>
```

## 开发流程

### 1. 创建目录结构

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
```

### 2. 开发顺序

按照以下顺序开发模块:

1. **核心工具层** (`lib/core/`)
   - CRC计算器
   - HEX解析器
   - 错误定义

2. **数据层** (`lib/data/`)
   - 协议配置模型
   - 帧构建器和解析器
   - 蓝牙数据源

3. **领域层** (`lib/domain/`)
   - 实体定义
   - 仓储接口
   - 用例实现

4. **表现层** (`lib/presentation/`)
   - Providers
   - 页面UI
   - 通用组件

### 3. 运行项目

```bash
# 检查设备
flutter devices

# 运行到 iOS 模拟器
flutter run -d ios

# 运行到 Android 模拟器
flutter run -d android

# 热重载: 按 r
# 热重启: 按 R
# 退出: 按 q
```

### 4. 代码生成

当使用 Riverpod 注解时:

```bash
flutter pub run build_runner build --delete-conflicting-outputs

# 或者监听模式
flutter pub run build_runner watch --delete-conflicting-outputs
```

## 测试

### 运行单元测试

```bash
flutter test
```

### 运行集成测试

```bash
flutter test integration_test/
```

## 打包发布

### Android APK

```bash
flutter build apk --release
# 输出: build/app/outputs/flutter-apk/app-release.apk
```

### iOS IPA

```bash
flutter build ios --release
# 然后在 Xcode 中归档和上传
```

## 常见问题

### 1. 蓝牙权限被拒绝

确保在 Info.plist 和 AndroidManifest.xml 中正确配置了权限。

### 2. 找不到蓝牙设备

- 确保设备蓝牙已开启
- 确保应用有位置权限（Android）
- 检查设备是否在广播模式

### 3. 连接超时

- 检查设备是否在范围内
- 确认设备未被其他应用连接
- 增加连接超时时间

## 下一步

1. 阅读 `FLUTTER_REFACTORING_DESIGN.md` 了解完整设计
2. 开始实现核心工具层（CRC计算器）
3. 实现协议层（帧构建器）
4. 实现蓝牙通信层
5. 实现UI界面

## 参考资源

- [Flutter 官方文档](https://flutter.dev/docs)
- [Riverpod 文档](https://riverpod.dev/)
- [flutter_blue_plus 文档](https://pub.dev/packages/flutter_blue_plus)
- [原始设计文档](../2026-01-16-cross-platform-host-computer-design.md)

---

**祝开发顺利！** 🚀
