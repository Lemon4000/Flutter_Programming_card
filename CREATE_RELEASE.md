# 创建 GitHub Release

## 为什么构建完成后没有自动创建 Release？

GitHub Actions 配置为：
- **推送到 master 分支**：只构建并上传 Artifacts（保留30天）
- **推送版本标签**：构建并自动创建 Release（永久保存）

## 如何创建 Release

### 方法 1：创建版本标签（推荐）

```bash
# 1. 创建版本标签
git tag v1.0.0

# 2. 推送标签到 GitHub
git push origin v1.0.0
```

这会自动：
- ✅ 触发 GitHub Actions 构建
- ✅ 构建 Windows、Android、Linux 三个平台
- ✅ 自动创建 GitHub Release
- ✅ 上传所有构建产物到 Release

### 方法 2：从 Artifacts 手动创建 Release

如果您已经有了构建产物（Artifacts），可以手动创建 Release：

1. **下载 Artifacts**
   - 访问：https://github.com/Lemon4000/Flutter_Programming_card/actions
   - 点击最新的成功构建
   - 下载所有 Artifacts

2. **创建 Release**
   ```bash
   # 创建标签
   git tag v1.0.0
   git push origin v1.0.0

   # 使用 GitHub CLI 创建 Release
   gh release create v1.0.0 \
     --title "Programming Card Host v1.0.0" \
     --notes "首次发布" \
     ProgrammingCardHost_v1.0.0_Windows_x64.zip \
     ProgrammingCardHost_v1.0.0_Android.apk \
     ProgrammingCardHost_v1.0.0_Linux_x64.tar.gz
   ```

3. **或在网页上创建**
   - 访问：https://github.com/Lemon4000/Flutter_Programming_card/releases/new
   - 选择标签：v1.0.0
   - 填写标题和说明
   - 上传下载的文件
   - 点击 "Publish release"

## 版本号管理

### 更新版本号

编辑 `pubspec.yaml`：

```yaml
version: 1.0.1+2  # 格式：主版本.次版本.修订版本+构建号
```

### 版本号规范

- **主版本**（1.x.x）：重大更新，可能不兼容
- **次版本**（x.1.x）：新功能，向后兼容
- **修订版本**（x.x.1）：Bug 修复
- **构建号**（+2）：内部构建编号

### 发布新版本流程

```bash
# 1. 更新版本号
# 编辑 pubspec.yaml: version: 1.0.1+2

# 2. 提交更改
git add pubspec.yaml
git commit -m "Bump version to 1.0.1"

# 3. 创建标签
git tag v1.0.1

# 4. 推送
git push origin master
git push origin v1.0.1

# 5. 等待构建完成（约20分钟）

# 6. 查看 Release
# 访问：https://github.com/Lemon4000/Flutter_Programming_card/releases
```

## 查看构建状态

### 实时查看

```bash
# 列出最近的构建
gh run list --limit 5

# 查看特定构建的详情
gh run view <run-id>

# 查看构建日志
gh run view <run-id> --log

# 在浏览器中打开
gh run view <run-id> --web
```

### 网页查看

访问：https://github.com/Lemon4000/Flutter_Programming_card/actions

## 下载构建产物

### 从 Artifacts 下载（30天内）

```bash
# 列出最新构建的 artifacts
gh run view --web

# 或使用命令行下载
gh run download <run-id>
```

### 从 Release 下载（永久）

访问：https://github.com/Lemon4000/Flutter_Programming_card/releases

## 常见问题

### Q: 为什么推送代码后没有创建 Release？

A: 只有推送**版本标签**（如 v1.0.0）才会创建 Release。普通推送只会构建并上传 Artifacts。

### Q: Artifacts 和 Release 有什么区别？

A:
- **Artifacts**：临时构建产物，保留30天，适合测试
- **Release**：永久发布版本，适合正式发布和分发

### Q: 如何删除错误的 Release？

A:
```bash
# 删除 Release
gh release delete v1.0.0

# 删除标签
git tag -d v1.0.0
git push origin :refs/tags/v1.0.0
```

### Q: 构建失败怎么办？

A:
1. 查看构建日志：`gh run view <run-id> --log-failed`
2. 修复问题
3. 重新推送代码
4. 或手动重新运行：`gh run rerun <run-id>`

## 示例：完整发布流程

```bash
# 1. 确保代码已提交
git status

# 2. 更新版本号（编辑 pubspec.yaml）
# version: 1.0.0+1

# 3. 提交版本更新
git add pubspec.yaml
git commit -m "Release v1.0.0"

# 4. 创建并推送标签
git tag v1.0.0
git push origin master
git push origin v1.0.0

# 5. 等待构建（约20分钟）
gh run watch

# 6. 查看 Release
gh release view v1.0.0 --web
```

## 自动化脚本

创建一个快速发布脚本 `release.sh`：

```bash
#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: ./release.sh <version>"
  echo "Example: ./release.sh 1.0.0"
  exit 1
fi

VERSION=$1

# 更新 pubspec.yaml
sed -i "s/^version: .*/version: $VERSION+1/" pubspec.yaml

# 提交
git add pubspec.yaml
git commit -m "Release v$VERSION"

# 创建标签
git tag "v$VERSION"

# 推送
git push origin master
git push origin "v$VERSION"

echo "✓ Release v$VERSION created!"
echo "View at: https://github.com/Lemon4000/Flutter_Programming_card/releases"
```

使用方法：

```bash
chmod +x release.sh
./release.sh 1.0.0
```

## 相关链接

- **Actions 页面**：https://github.com/Lemon4000/Flutter_Programming_card/actions
- **Releases 页面**：https://github.com/Lemon4000/Flutter_Programming_card/releases
- **GitHub CLI 文档**：https://cli.github.com/manual/
