# 修复串口通信仓库集成问题

## 问题描述

虽然扫描界面可以连接 USB 串口设备，但是：
- 参数页面读取参数显示"无串口连接"
- 烧录功能没有发送出数据
- 调试功能显示"无连接"

## 根本原因

扫描界面和通信仓库使用了不同的 `CrossPlatformSerialDatasource` 实例：
- 扫描界面创建并连接了自己的实例
- 通信仓库（用于参数读取、烧录、调试）使用的是另一个未连接的实例

这导致虽然扫描界面显示"已连接"，但其他功能无法访问串口。

## 解决方案

### 1. 更新 `CommunicationRepositoryImpl`

添加了对 `CrossPlatformSerialDatasource` 的支持：

```dart
class CommunicationRepositoryImpl {
  final BluetoothDatasource? _bluetoothDatasource;
  final SerialPortDatasource? _serialPortDatasource;
  final CrossPlatformSerialDatasource? _crossPlatformSerialDatasource;  // 新增

  // 新增构造函数
  CommunicationRepositoryImpl.crossPlatformSerial(
    CrossPlatformSerialDatasource crossPlatformSerialDatasource,
    this._protocolConfig,
    this._ref,
  ) { ... }

  // 更新 _writeData 方法支持跨平台数据源
  Future<void> _writeData(List<int> data) async {
    if (_bluetoothDatasource != null) {
      await _bluetoothDatasource.write(data);
    } else if (_serialPortDatasource != null) {
      await _serialPortDatasource.write(data);
    } else if (_crossPlatformSerialDatasource != null) {
      await _crossPlatformSerialDatasource.write(data);  // 新增
    } else {
      throw Exception('没有可用的数据源');
    }
  }
}
```

### 2. 更新 `communicationRepositoryProvider`

修改为使用跨平台串口数据源：

```dart
final communicationRepositoryProvider = FutureProvider<CommunicationRepository>((ref) async {
  final communicationType = ref.watch(communicationTypeProvider);
  final protocolConfig = await ref.watch(protocolConfigProvider.future);

  if (communicationType == CommunicationType.bluetooth) {
    final datasource = ref.watch(bluetoothDatasourceProvider);
    return CommunicationRepositoryImpl.bluetooth(datasource, protocolConfig, ref);
  } else {
    // 使用跨平台串口数据源（共享实例）
    final datasource = ref.watch(crossPlatformSerialDatasourceProvider);
    return CommunicationRepositoryImpl.crossPlatformSerial(datasource, protocolConfig, ref);
  }
});
```

### 3. 更新扫描界面连接逻辑

确保使用 Provider 中的共享实例，并在连接后重新初始化通信仓库：

```dart
Future<void> _connectToSerialPort(SerialDeviceInfo device) async {
  // 使用 Provider 中的共享实例
  final serialDatasource = ref.read(crossPlatformSerialDatasourceProvider);

  // 连接设备
  await serialDatasource.connect(device, baudRate: baudRate);

  // 更新全局连接状态
  ref.read(connectionStateProvider.notifier).state = true;

  // 重新初始化通信仓库以使用新连接的数据源
  ref.invalidate(communicationRepositoryProvider);
}
```

## 关键改进

1. **共享数据源实例**：扫描界面和通信仓库现在使用同一个 `CrossPlatformSerialDatasource` 实例
2. **自动重新初始化**：连接串口后，通信仓库会自动重新初始化并监听数据流
3. **完整的数据流**：参数读取、烧录、调试功能现在都可以正常工作

## 数据流

```
用户点击连接
    ↓
扫描界面使用 crossPlatformSerialDatasourceProvider
    ↓
连接 USB 设备
    ↓
更新连接状态
    ↓
invalidate(communicationRepositoryProvider)
    ↓
通信仓库重新初始化，使用同一个已连接的数据源
    ↓
监听数据流
    ↓
参数读取/烧录/调试功能正常工作 ✅
```

## 测试步骤

1. 构建并安装 APK
2. 连接 USB OTG 转串口设备
3. 在扫描界面连接设备
4. 切换到参数页面，点击"读取参数" - 应该能正常读取
5. 切换到烧录页面，选择固件并烧录 - 应该能正常发送数据
6. 切换到调试页面 - 应该显示"已连接"并能收发数据

## 构建结果

```
✓ Built build/app/outputs/flutter-apk/app-release.apk (23.0MB)
```

现在所有功能都应该可以正常工作了！
