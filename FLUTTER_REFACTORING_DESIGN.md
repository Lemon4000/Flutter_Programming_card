# 编程卡上位机 Flutter 重构设计方案

## 项目概述

将现有的 Python/PySide6 编程卡上位机应用重构为 Flutter 跨平台应用。

**目标平台**：iOS、Android（第一阶段）、Windows、Ubuntu、鸿蒙（后续阶段）

**核心功能**：
- 参数读写（A组等参数组）
- 固件烧录（HEX文件）
- 实时通信日志
- 蓝牙/串口通信

---

## 1. 架构设计

### 1.1 分层架构

采用清晰的三层架构模式：

```
┌─────────────────────────────────────────┐
│   表现层 (Presentation Layer)           │
│   - UI界面、状态管理、用户交互           │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│   领域层 (Domain Layer)                 │
│   - 业务逻辑、用例、实体定义             │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│   数据层 (Data Layer)                   │
│   - 硬件通信、协议处理、数据持久化       │
└─────────────────────────────────────────┘
```

### 1.2 技术栈选型

| 组件 | 技术方案 | 选择理由 |
|------|---------|---------|
| 状态管理 | Riverpod 2.x | 类型安全、编译时检查、适合复杂状态 |
| 蓝牙通信 | flutter_blue_plus | 最佳跨平台BLE支持、活跃维护 |
| 串口通信 | 自定义Platform Channels | 仅桌面端、原生侧使用libserialport |
| 协议处理 | 纯Dart实现 | 重写CRC16_MODBUS/SUM8，完全控制 |
| 配置文件 | JSON Assets | 将CSV转为JSON，作为应用资源加载 |
| 日志系统 | logger + 自定义UI | 实时日志显示，支持HEX/ASCII切换 |
| 文件处理 | file_picker | 用于HEX文件选择 |
| 权限管理 | permission_handler | 统一权限管理 |

---

## 2. 项目目录结构

```
flutter/
├── lib/
│   ├── main.dart                          # 应用入口
│   ├── app.dart                           # App配置
│   │
│   ├── core/                              # 核心工具
│   │   ├── constants/                     # 常量定义
│   │   ├── utils/                         # 工具类
│   │   │   ├── crc_calculator.dart        # CRC16/SUM8计算
│   │   │   └── hex_parser.dart            # HEX文件解析
│   │   └── errors/                        # 错误定义
│   │
│   ├── data/                              # 数据层
│   │   ├── models/                        # 数据模型
│   │   │   ├── device_info.dart           # 设备信息
│   │   │   ├── parameter.dart             # 参数模型
│   │   │   └── flash_progress.dart        # 烧录进度
│   │   ├── datasources/                   # 数据源
│   │   │   ├── bluetooth_datasource.dart  # 蓝牙数据源
│   │   │   └── config_datasource.dart     # 配置数据源
│   │   ├── repositories/                  # 仓储实现
│   │   │   ├── device_repository_impl.dart
│   │   │   └── config_repository_impl.dart
│   │   └── protocol/                      # 协议处理
│   │       ├── frame_builder.dart         # 帧构建
│   │       ├── frame_parser.dart          # 帧解析
│   │       └── protocol_config.dart       # 协议配置
│   │
│   ├── domain/                            # 领域层
│   │   ├── entities/                      # 实体
│   │   │   ├── device.dart
│   │   │   └── parameter_group.dart
│   │   ├── repositories/                  # 仓储接口
│   │   │   └── device_repository.dart
│   │   └── usecases/                      # 用例
│   │       ├── scan_devices.dart
│   │       ├── connect_device.dart
│   │       ├── read_parameters.dart
│   │       ├── write_parameters.dart
│   │       └── flash_firmware.dart
│   │
│   └── presentation/                      # 表现层
│       ├── providers/                     # Riverpod Providers
│       │   ├── device_provider.dart
│       │   ├── connection_provider.dart
│       │   └── log_provider.dart
│       ├── screens/                       # 页面
│       │   ├── scan_screen.dart           # 扫描页面
│       │   ├── parameter_screen.dart      # 参数读写页面
│       │   ├── flash_screen.dart          # 烧录页面
│       │   └── log_screen.dart            # 日志页面
│       └── widgets/                       # 通用组件
│           ├── device_list_item.dart
│           ├── parameter_table.dart
│           └── log_viewer.dart
│
├── assets/                                # 资源文件
│   ├── config/                            # 配置文件（JSON）
│   │   ├── protocol.json                  # 协议配置
│   │   └── groups/                        # 参数组配置
│   │       └── group_a.json               # A组参数
│   └── images/                            # 图片资源
│
├── pubspec.yaml                           # 依赖配置
└── README.md
```

---

## 3. 核心模块设计

### 3.1 协议层（Protocol Layer）

#### 3.1.1 CRC计算工具

```dart
// lib/core/utils/crc_calculator.dart
class CrcCalculator {
  // CRC16 MODBUS算法
  static int crc16Modbus(List<int> data) {
    int crc = 0xFFFF;
    for (var byte in data) {
      crc ^= byte;
      for (int i = 0; i < 8; i++) {
        if (crc & 1 != 0) {
          crc = (crc >> 1) ^ 0xA001;
        } else {
          crc >>= 1;
        }
      }
    }
    return crc & 0xFFFF;
  }

  // SUM8校验
  static int sum8(List<int> data) {
    return data.reduce((a, b) => a + b) & 0xFF;
  }

  // 根据类型计算校验值
  static List<int> calculateChecksum(
    List<int> payload,
    ChecksumType type
  ) {
    switch (type) {
      case ChecksumType.crc16Modbus:
        final crc = crc16Modbus(payload);
        return [crc & 0xFF, (crc >> 8) & 0xFF]; // 小端序
      case ChecksumType.sum8:
        return [sum8(payload)];
    }
  }
}
```

#### 3.1.2 帧构建器

```dart
// lib/data/protocol/frame_builder.dart
class FrameBuilder {
  final ProtocolConfig config;

  // 构建读取请求帧：!READ:A;[CRC]
  List<int> buildReadRequest(String group) {
    final payload = '${config.txStart}READ:$group;'.codeUnits;
    final preamble = _hexToBytes(config.preamble);
    final checksum = CrcCalculator.calculateChecksum(
      payload,
      config.checksumType
    );
    return [...preamble, ...payload, ...checksum];
  }

  // 构建写入帧：!WRITEA0:14.00,A1:60.00;[CRC]
  List<int> buildWriteFrame(
    String group,
    Map<String, double> values,
    Map<String, int> precisionMap
  ) {
    final parts = <String>[];
    final sortedKeys = values.keys.toList()
      ..sort((a, b) => _extractNumber(a).compareTo(_extractNumber(b)));

    for (var key in sortedKeys) {
      final precision = precisionMap[key] ?? 2;
      final value = values[key]!.toStringAsFixed(precision);
      parts.add('$key:$value');
    }

    final payload = '${config.txStart}WRITE${parts.join(',')};'.codeUnits;
    final preamble = _hexToBytes(config.preamble);
    final checksum = CrcCalculator.calculateChecksum(
      payload,
      config.checksumType
    );
    return [...preamble, ...payload, ...checksum];
  }

  // 构建烧录数据帧
  List<int> buildFlashDataFrame(int address, List<int> data) {
    final header = '${config.txStart}HEX:START$address.SIZE${data.length},DATA';
    final payload = [...header.codeUnits, ...data, ';'.codeUnitAt(0)];
    final preamble = _hexToBytes(config.preamble);
    final checksum = CrcCalculator.calculateChecksum(
      payload,
      config.checksumType
    );
    return [...preamble, ...payload, ...checksum];
  }
}
```

### 3.2 蓝牙通信层

```dart
// lib/data/datasources/bluetooth_datasource.dart
class BluetoothDatasource {
  final FlutterBluePlus _flutterBlue = FlutterBluePlus.instance;
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _txCharacteristic;
  BluetoothCharacteristic? _rxCharacteristic;

  // 扫描设备
  Stream<List<ScanResult>> scanDevices({
    Duration timeout = const Duration(seconds: 10)
  }) {
    return _flutterBlue.scanResults.timeout(timeout);
  }

  // 连接设备
  Future<void> connect(BluetoothDevice device) async {
    await device.connect(autoConnect: false);
    _connectedDevice = device;

    // 发现服务和特征值
    final services = await device.discoverServices();
    for (var service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.properties.write) {
          _txCharacteristic = characteristic;
        }
        if (characteristic.properties.notify) {
          _rxCharacteristic = characteristic;
          await characteristic.setNotifyValue(true);
        }
      }
    }
  }

  // 发送数据
  Future<void> write(List<int> data) async {
    if (_txCharacteristic == null) {
      throw Exception('未找到TX特征值');
    }
    await _txCharacteristic!.write(data, withoutResponse: false);
  }

  // 接收数据流
  Stream<List<int>> get dataStream {
    if (_rxCharacteristic == null) {
      return Stream.empty();
    }
    return _rxCharacteristic!.value;
  }
}
```

### 3.3 固件烧录模块

#### 3.3.1 HEX文件解析器

```dart
// lib/core/utils/hex_parser.dart
class HexParser {
  // 解析HEX文件，返回地址->数据映射
  static Map<int, List<int>> parseHexFile(String hexContent) {
    final lines = hexContent.split('\n');
    final dataMap = <int, List<int>>{};
    int baseAddress = 0;

    for (var line in lines) {
      line = line.trim();
      if (!line.startsWith(':')) continue;

      final byteCount = int.parse(line.substring(1, 3), radix: 16);
      final address = int.parse(line.substring(3, 7), radix: 16);
      final recordType = int.parse(line.substring(7, 9), radix: 16);

      if (recordType == 0x00) {
        // 数据记录
        final data = <int>[];
        for (int i = 0; i < byteCount; i++) {
          final byte = int.parse(
            line.substring(9 + i * 2, 11 + i * 2),
            radix: 16
          );
          data.add(byte);
        }
        dataMap[baseAddress + address] = data;
      } else if (recordType == 0x04) {
        // 扩展线性地址记录
        baseAddress = int.parse(line.substring(9, 13), radix: 16) << 16;
      } else if (recordType == 0x01) {
        // 文件结束
        break;
      }
    }

    return dataMap;
  }

  // 将数据分块
  static List<FlashBlock> createBlocks(
    Map<int, List<int>> dataMap,
    {int blockSize = 256}
  ) {
    final blocks = <FlashBlock>[];

    for (var entry in dataMap.entries) {
      final address = entry.key;
      final data = entry.value;

      for (int i = 0; i < data.length; i += blockSize) {
        final end = (i + blockSize < data.length)
          ? i + blockSize
          : data.length;
        blocks.add(FlashBlock(
          address: address + i,
          data: data.sublist(i, end),
        ));
      }
    }

    return blocks;
  }
}
```

#### 3.3.2 烧录用例

```dart
// lib/domain/usecases/flash_firmware.dart
class FlashFirmware {
  final DeviceRepository _repository;

  Stream<FlashProgress> execute(String hexFilePath) async* {
    try {
      // 1. 读取HEX文件
      yield FlashProgress.loading('读取HEX文件...');
      final file = File(hexFilePath);
      final content = await file.readAsString();

      // 2. 解析HEX文件
      yield FlashProgress.loading('解析HEX文件...');
      final dataMap = HexParser.parseHexFile(content);
      final blocks = HexParser.createBlocks(dataMap);

      // 3. 开始烧录
      yield FlashProgress.loading('开始烧录...');
      int totalCrc = 0;

      for (int i = 0; i < blocks.length; i++) {
        final block = blocks[i];

        // 发送数据块
        await _repository.flashBlock(block.address, block.data);

        // 等待设备响应
        final reply = await _repository.waitForFlashReply();
        if (!reply.success) {
          throw Exception('烧录失败：块 $i');
        }

        // 累加CRC
        totalCrc += reply.crc;

        // 报告进度
        final progress = ((i + 1) / blocks.length * 100).toInt();
        yield FlashProgress.progress(
          progress,
          '烧录中... $progress% (${i + 1}/${blocks.length})'
        );

        await Future.delayed(Duration(milliseconds: 50));
      }

      // 4. 发送校验帧
      yield FlashProgress.loading('校验中...');
      await _repository.verifyFlash(totalCrc & 0xFFFF);

      // 5. 完成
      yield FlashProgress.completed('烧录完成！');

    } catch (e) {
      yield FlashProgress.error('烧录失败：$e');
    }
  }
}
```

### 3.4 UI界面设计

#### 3.4.1 主界面导航

```dart
// lib/presentation/screens/main_screen.dart
class MainScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('编程卡上位机'),
        actions: [ConnectionStatusIndicator()],
      ),
      body: TabBarView(
        children: [
          ScanScreen(),        // 设备扫描
          ParameterScreen(),   // 参数读写
          FlashScreen(),       // 固件烧录
          LogScreen(),         // 通信日志
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.bluetooth), label: '扫描'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '参数'),
          BottomNavigationBarItem(icon: Icon(Icons.upload_file), label: '烧录'),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: '日志'),
        ],
      ),
    );
  }
}
```

---

## 4. 配置文件格式

### 4.1 协议配置 (protocol.json)

```json
{
  "preamble": "FC",
  "checksum": "CRC16_MODBUS",
  "baudRate": 2000000,
  "txStart": "!",
  "rxStart": "#"
}
```

### 4.2 参数组配置 (group_a.json)

```json
{
  "name": "A组",
  "parameters": [
    {
      "key": "A0",
      "name": "电压",
      "unit": "V",
      "min": 0.0,
      "max": 100.0,
      "precision": 2,
      "default": 14.0
    },
    {
      "key": "A1",
      "name": "电流",
      "unit": "A",
      "min": 0.0,
      "max": 50.0,
      "precision": 2,
      "default": 10.0
    }
  ]
}
```

---

## 5. 开发路线图

### Phase 1: 基础框架（1-2周）
- Flutter项目初始化
- 目录结构搭建
- Riverpod状态管理配置
- 基础UI框架（导航、主题）

### Phase 2: 协议层（1周）
- CRC计算工具
- 帧构建器和解析器
- 配置文件转换和加载
- 单元测试

### Phase 3: 蓝牙通信（1-2周）
- flutter_blue_plus集成
- 设备扫描功能
- 连接管理
- 数据收发
- iOS/Android权限配置

### Phase 4: 核心功能（2-3周）
- 参数读写功能
- HEX文件解析
- 固件烧录功能
- 实时日志系统

### Phase 5: UI完善（1周）
- 界面优化
- 错误提示
- 加载状态
- 用户体验优化

### Phase 6: 测试与发布（1周）
- 集成测试
- 真机测试（iOS/Android）
- 性能优化
- 打包发布

**总计：7-10周**

---

## 6. 第一阶段范围

### 目标平台
- iOS
- Android

### 通信方式
- 仅蓝牙（BLE）

### 核心功能
- 设备扫描与连接
- 参数读写（A组等）
- 固件烧录（HEX文件）
- 实时通信日志（HEX/ASCII）
- 配置管理

### 延后到第二阶段
- 桌面平台（Windows、Ubuntu）
- 串口通信
- 鸿蒙系统支持
- 高级数据可视化

---

## 7. 依赖包清单 (pubspec.yaml)

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
  
  # UI组件
  flutter_hooks: ^0.20.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  
  # 代码生成
  riverpod_generator: ^2.3.0
  build_runner: ^2.4.0
  
  # 测试
  mockito: ^5.4.0
```

---

## 8. 关键技术要点

### 8.1 蓝牙权限配置

**iOS (Info.plist)**:
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>需要蓝牙权限以连接编程卡设备</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>需要蓝牙权限以连接编程卡设备</string>
```

**Android (AndroidManifest.xml)**:
```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

### 8.2 错误处理策略

```dart
sealed class Failure {
  final String message;
  Failure(this.message);
}

class ConnectionFailure extends Failure {
  ConnectionFailure(super.message);
}

class ProtocolFailure extends Failure {
  ProtocolFailure(super.message);
}

class FlashFailure extends Failure {
  FlashFailure(super.message);
}

extension FailureHandler on Failure {
  String toUserMessage() {
    return switch (this) {
      ConnectionFailure() => '连接失败：$message',
      ProtocolFailure() => '协议错误：$message',
      FlashFailure() => '烧录失败：$message',
      _ => '未知错误：$message',
    };
  }
}
```

---

## 9. 测试策略

### 9.1 单元测试
- CRC计算工具测试
- HEX文件解析器测试
- 帧构建器测试

### 9.2 集成测试
- 蓝牙连接流程测试
- 参数读写流程测试
- 固件烧录流程测试

### 9.3 UI测试
- 页面导航测试
- 用户交互测试

---

## 10. 性能优化建议

1. **日志管理**：限制日志条目数量（最多1000条），避免内存溢出
2. **蓝牙数据流**：使用StreamController管理数据流，及时释放资源
3. **烧录优化**：合理设置数据块大小和发送间隔
4. **UI响应**：使用Isolate处理HEX文件解析等耗时操作
5. **状态管理**：合理使用Riverpod的autoDispose避免内存泄漏

---

## 11. 后续扩展计划

### Phase 2: 桌面端支持
- Windows/Ubuntu平台适配
- 串口通信实现（Platform Channels）
- 桌面端UI优化

### Phase 3: 鸿蒙系统支持
- 鸿蒙SDK集成
- 鸿蒙蓝牙API适配
- 鸿蒙应用打包发布

### Phase 4: 高级功能
- 数据可视化（图表）
- 历史记录管理
- 多设备同时管理
- 云端配置同步

---

**文档版本**: 1.0  
**创建日期**: 2026-01-17  
**最后更新**: 2026-01-17
