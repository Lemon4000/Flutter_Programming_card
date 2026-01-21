# Flutter编程卡上位机 - 运行说明

## 当前状态

应用已成功构建并运行在Linux桌面环境。

## 已知问题

### 1. Linux桌面蓝牙支持限制

**问题描述：**
- 在Linux桌面上，flutter_blue_plus的蓝牙功能支持有限
- 扫描可能无法找到设备
- 连接功能可能无法正常工作

**原因：**
flutter_blue_plus主要针对移动平台（Android/iOS）优化，Linux桌面支持不完整。

**解决方案：**
1. **推荐方式**：在Android或iOS设备上测试
   ```bash
   # 连接Android设备后运行
   flutter run -d <device-id>

   # 查看可用设备
   flutter devices
   ```

2. **临时测试**：使用模拟数据
   - 可以修改代码添加模拟设备用于UI测试

### 2. 连接超时问题

**已修复：**
- 添加了10秒连接超时
- 连接前自动停止扫描
- 添加了更好的错误提示

**代码改进：**
```dart
// 连接时会先停止扫描
if (_isScanning) {
  await _stopScan();
  await Future.delayed(const Duration(milliseconds: 500));
}

// 添加超时处理
final result = await connectUseCase(device.id, timeout: const Duration(seconds: 10))
    .timeout(const Duration(seconds: 12));
```

## 运行应用

### Linux桌面
```bash
cd /home/lemon/桌面/docs/plans/flutter
flutter run -d linux
```

### Android设备
```bash
# 1. 启用USB调试
# 2. 连接设备
# 3. 运行
flutter run -d <android-device-id>
```

### iOS设备（需要Mac）
```bash
flutter run -d <ios-device-id>
```

## 应用功能

### 已实现
- ✅ 设备扫描页面
- ✅ 设备连接功能
- ✅ 底部导航栏
- ✅ 错误处理和提示
- ✅ 超时保护

### 待实现
- ⏳ 参数读写页面
- ⏳ 固件烧录页面
- ⏳ 通信日志页面

## 测试建议

### 在Android设备上测试完整功能

1. **准备工作**
   - 确保Android设备已启用开发者选项和USB调试
   - 安装ADB驱动
   - 授予应用蓝牙权限

2. **运行步骤**
   ```bash
   # 检查设备连接
   flutter devices

   # 运行应用
   flutter run

   # 或指定设备
   flutter run -d <device-id>
   ```

3. **测试流程**
   - 打开应用
   - 点击"开始扫描"
   - 等待发现蓝牙设备
   - 点击设备的"连接"按钮
   - 观察连接状态

### 模拟测试（开发用）

如果需要在没有真实蓝牙设备的情况下测试UI，可以：

1. 创建模拟数据源
2. 在providers中切换到模拟实现
3. 测试UI交互和状态管理

## 架构说明

应用采用Clean Architecture：

```
lib/
├── core/              # 核心工具
│   ├── errors/       # 错误定义
│   └── utils/        # CRC、HEX解析器
├── data/             # 数据层
│   ├── datasources/  # 蓝牙数据源
│   ├── models/       # 数据模型
│   ├── protocol/     # 协议处理
│   └── repositories/ # 仓库实现
├── domain/           # 领域层
│   ├── entities/     # 实体
│   ├── repositories/ # 仓库接口
│   └── usecases/     # 用例
└── presentation/     # 表现层
    ├── providers/    # Riverpod状态管理
    └── screens/      # UI页面
```

## 调试工具

应用运行时可以使用Flutter DevTools：

```
http://127.0.0.1:<port>/devtools/
```

端口号会在应用启动时显示在终端。

## 常见问题

### Q: 为什么扫描不到设备？
A:
1. 检查蓝牙是否开启
2. 检查应用权限
3. 在Linux上，建议使用Android/iOS设备测试

### Q: 连接一直转圈？
A:
1. 已添加12秒超时保护
2. 确保设备在范围内
3. 尝试重启蓝牙

### Q: 如何查看日志？
A:
```bash
# 查看Flutter日志
flutter logs

# 或在运行时查看终端输出
```

## 下一步开发

1. 实现参数读写页面
2. 实现固件烧录页面
3. 实现通信日志页面
4. 添加更多错误处理
5. 优化用户体验
