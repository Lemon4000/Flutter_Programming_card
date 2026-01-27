# Flutter + HDC 快速参考

## 🚀 快速开始

```bash
# 1. 使环境变量生效（仅需一次）
source ~/.bashrc

# 2. 检查设备
./flutter-hdc-deploy.sh devices

# 3. 部署应用
./flutter-hdc-deploy.sh deploy
```

## 📋 常用命令

### 部署脚本

```bash
# 构建并部署（最常用）
./flutter-hdc-deploy.sh deploy

# 构建release版本
./flutter-hdc-deploy.sh deploy --release

# 只构建
./flutter-hdc-deploy.sh build

# 只安装
./flutter-hdc-deploy.sh install

# 查看日志
./flutter-hdc-deploy.sh log

# 列出设备
./flutter-hdc-deploy.sh devices

# 清理构建
./flutter-hdc-deploy.sh clean
```

### 直接使用HDC

```bash
# 列出设备
hdc list targets

# 安装应用
hdc install -r app.apk

# 卸载应用
hdc uninstall com.example.app

# 查看日志（可能受限）
hdc hilog

# 文件传输（可能受限）
hdc file send <本地> <设备>
hdc file recv <设备> <本地>
```

### Flutter命令

```bash
# 在Linux桌面开发（推荐）
flutter run -d linux

# 构建APK
flutter build apk --debug
flutter build apk --release

# 清理
flutter clean
```

## 💡 推荐工作流程

### 开发阶段
```bash
# 在Linux桌面上快速迭代
flutter run -d linux
```
✅ 热重载 | ✅ 快速调试 | ✅ DevTools

### 测试阶段
```bash
# 定期在设备上测试
./flutter-hdc-deploy.sh deploy
```
✅ 真实环境 | ✅ 设备功能 | ✅ 性能测试

### 发布阶段
```bash
# 构建release版本
./flutter-hdc-deploy.sh deploy --release
```
✅ 优化性能 | ✅ 最终测试

## ⚠️ 重要提示

1. **版本警告**：HDC可能显示版本警告，这是正常的
2. **手动启动**：安装后需要在设备上手动启动应用
3. **日志受限**：`hdc hilog` 可能不可用
4. **无热重载**：需要重新构建和安装

## 🔧 故障排除

### 设备未找到
```bash
lsusb | grep Huawei
hdc list targets
```

### 安装失败
```bash
hdc uninstall com.example.app
./flutter-hdc-deploy.sh install
```

### 应用崩溃
```bash
# 在桌面上调试
flutter run -d linux
```

## 📚 完整文档

- `FLUTTER_HDC_WORKFLOW.md` - 完整工作流程指南
- `HDC_TROUBLESHOOTING.md` - 故障排除指南
- `HDC_USAGE_GUIDE.md` - HDC命令详解

## 🎯 下一步

```bash
# 开始开发
cd /home/lemon/桌面/docs/plans/flutter
./flutter-hdc-deploy.sh deploy
```

祝开发顺利！🚀
