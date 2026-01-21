# 编程卡上位机 - Flutter 版本

基于 Flutter 的跨平台编程卡上位机应用，支持 iOS、Android、Windows、Ubuntu 和鸿蒙系统。

## 项目概述

本项目是对原有 Python/PySide6 编程卡上位机的 Flutter 重构版本，提供以下核心功能：

- 🔍 **设备扫描与连接** - 蓝牙设备自动发现和连接管理
- ⚙️ **参数读写** - 支持多组参数的读取和写入（A组、B组等）
- 📤 **固件烧录** - HEX文件解析和固件烧录功能
- 📊 **实时日志** - 通信数据实时显示（HEX/ASCII格式）
- 🔐 **协议支持** - CRC16_MODBUS 和 SUM8 校验

## 技术栈

- **框架**: Flutter 3.x
- **状态管理**: Riverpod 2.x
- **蓝牙通信**: flutter_blue_plus
- **架构模式**: Clean Architecture (三层架构)

## 项目结构

```
flutter/
├── lib/
│   ├── core/           # 核心工具（CRC、HEX解析器等）
│   ├── data/           # 数据层（蓝牙、协议、仓储实现）
│   ├── domain/         # 领域层（实体、用例、仓储接口）
│   └── presentation/   # 表现层（UI、状态管理）
├── assets/
│   └── config/         # 配置文件（JSON格式）
├── test/               # 单元测试
└── integration_test/   # 集成测试
```

## 快速开始

### 1. 环境准备

```bash
# 安装 Flutter SDK
# 访问: https://flutter.dev/docs/get-started/install

# 验证安装
flutter doctor
```

### 2. 克隆并初始化项目

```bash
cd flutter
flutter pub get
```

### 3. 配置文件转换

```bash
cd tools
dart convert_config.dart
cd ..
```

### 4. 运行项目

```bash
# iOS
flutter run -d ios

# Android
flutter run -d android
```

详细的开发指南请参阅 [QUICK_START.md](QUICK_START.md)

## 文档

- 📖 [完整设计文档](FLUTTER_REFACTORING_DESIGN.md) - 架构设计和技术细节
- 🚀 [快速开始指南](QUICK_START.md) - 项目初始化和开发流程
- 📋 [原始设计文档](../2026-01-16-cross-platform-host-computer-design.md) - 需求分析

## 开发阶段

### Phase 1: 移动端（已完成 ✅）
- ✅ 架构设计完成
- ✅ iOS/Android 实现完成
- ✅ 蓝牙通信实现
- ✅ 核心功能开发完成
- ✅ UI 美化和优化
- ✅ 性能优化
- ✅ 无障碍支持

### Phase 2: 桌面端（计划中）
- ⏳ Windows/Ubuntu 支持
- ⏳ 串口通信实现

### Phase 3: 鸿蒙系统（计划中）
- ⏳ 鸿蒙 SDK 集成
- ⏳ 鸿蒙应用适配

## 最新改进 (v1.0.0)

### UI/UX 改进
- ✅ Material 3 现代化设计
- ✅ 统一的圆角、阴影、渐变效果
- ✅ 流畅的页面切换动画
- ✅ 改进的加载和错误状态显示
- ✅ 修复所有布局溢出问题

### 代码质量改进
- ✅ 创建统一的日志工具类 (`AppLogger`)
- ✅ 创建应用常量类 (`AppConstants`)
- ✅ 创建可复用 UI 组件库
- ✅ Release 模式自动禁用日志
- ✅ 改进无障碍访问支持

### 新增工具类
- `lib/core/utils/logger.dart` - 统一日志管理
- `lib/core/constants/app_constants.dart` - 应用常量
- `lib/presentation/widgets/common_widgets.dart` - 可复用组件

## 核心功能

### 1. 蓝牙设备管理
- 自动扫描附近的蓝牙设备
- 显示设备名称和信号强度
- 一键连接/断开

### 2. 参数读写
- 支持多组参数配置（A组、B组等）
- 实时读取设备参数
- 批量写入参数到设备
- 参数范围验证

### 3. 固件烧录
- Intel HEX 文件解析
- 分块烧录进度显示
- CRC 校验确保数据完整性
- 烧录失败自动重试

### 4. 通信日志
- 实时显示收发数据
- HEX/ASCII 格式切换
- 日志导出功能
- 自动滚动和清除

## 协议说明

### 帧格式

```
[前导码][数据载荷][校验值]
```

- **前导码**: FC (可配置)
- **数据载荷**: ASCII 文本格式
- **校验值**: CRC16_MODBUS 或 SUM8

### 命令示例

**读取参数**:
```
FC !READ:A; [CRC]
```

**写入参数**:
```
FC !WRITEA0:14.00,A1:60.00; [CRC]
```

**烧录数据**:
```
FC !HEX:START0x0000.SIZE256,DATA[binary]; [CRC]
```

## 测试

```bash
# 运行单元测试
flutter test

# 运行集成测试
flutter test integration_test/

# 代码覆盖率
flutter test --coverage
```

## 打包发布

### Android

```bash
flutter build apk --release
# 输出: build/app/outputs/flutter-apk/app-release.apk
```

### iOS

```bash
flutter build ios --release
# 然后在 Xcode 中归档
```

## 贡献指南

1. Fork 本项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

## 联系方式

项目维护者: [您的名字]
项目链接: [项目仓库地址]

## 致谢

- 原始 Python 版本开发团队
- Flutter 社区
- flutter_blue_plus 维护者

---

**版本**: 1.0.0
**最后更新**: 2026-01-19
**状态**: ✅ 生产就绪
