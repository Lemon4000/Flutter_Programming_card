# 自动 Release 已启用 ✅

## 🎉 好消息

现在每次推送代码到 master 分支，GitHub Actions 会自动：

1. ✅ 构建 Windows、Android、Linux 三个平台
2. ✅ 自动创建 GitHub Release
3. ✅ 上传所有构建产物到 Release
4. ✅ 生成 Release 说明

**不需要手动创建标签！**

## 📦 Release 版本号

Release 版本号自动从 `pubspec.yaml` 中读取：

```yaml
version: 1.0.0+1  # 将创建 v1.0.0 Release
```

## 🔄 工作流程

```
推送代码到 master
    ↓
GitHub Actions 自动触发
    ↓
并行构建三个平台（约 5-10 分钟）
    ├─ Android APK
    ├─ Windows ZIP
    └─ Linux tar.gz
    ↓
自动创建/更新 Release
    ↓
上传所有构建产物
    ↓
完成！🎉
```

## 📥 下载 Release

访问：https://github.com/Lemon4000/Flutter_Programming_card/releases

每次推送后约 10 分钟，新的 Release 就会出现。

## 🔄 更新版本

如果要发布新版本：

```bash
# 1. 更新 pubspec.yaml 中的版本号
# version: 1.0.1+2

# 2. 提交并推送
git add pubspec.yaml
git commit -m "Bump version to 1.0.1"
git push origin master

# 3. 等待约 10 分钟
# 4. 访问 Releases 页面查看新版本
```

## ⚙️ Release 行为

- **相同版本号**：会删除旧的 Release 并创建新的
- **不同版本号**：会创建新的 Release，保留旧版本
- **Release 标签**：自动创建，格式为 `v{version}`（如 v1.0.0）

## 📊 查看构建状态

```bash
# 查看最近的构建
gh run list --limit 5

# 实时查看构建
gh run watch

# 在浏览器中查看
gh run view --web
```

或访问：https://github.com/Lemon4000/Flutter_Programming_card/actions

## 🎯 构建产物

每个 Release 包含：

1. **ProgrammingCardHost_v{version}_Android.apk**
   - Android 安装包
   - 直接安装到 Android 设备

2. **ProgrammingCardHost_v{version}_Windows_x64.zip**
   - Windows 可执行程序
   - 解压后运行 `programming_card_host.exe`

3. **ProgrammingCardHost_v{version}_Linux_x64.tar.gz**
   - Linux 可执行程序
   - 解压后运行 `programming_card_host`

## 💡 提示

- Release 会永久保存（不像 Artifacts 只保留 30 天）
- 每次推送都会触发构建，建议合并多个提交后再推送
- 如果不想触发构建，可以在提交信息中添加 `[skip ci]`

## 🔧 手动触发构建

如果需要手动触发构建：

```bash
# 使用 GitHub CLI
gh workflow run build-multi-platform.yml

# 或在网页上操作
# 访问 Actions 页面 → 选择工作流 → Run workflow
```

## 📚 相关文档

- `GITHUB_ACTIONS_GUIDE.md` - GitHub Actions 详细指南
- `CREATE_RELEASE.md` - Release 创建说明（现在已自动化）
- `GITHUB_ACTIONS_SETUP_COMPLETE.md` - 初始设置完成总结

## ✨ 总结

现在您只需要：
1. 写代码
2. 提交
3. 推送

GitHub Actions 会自动完成构建和发布！🚀
