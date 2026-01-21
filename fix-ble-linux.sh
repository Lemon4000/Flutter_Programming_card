#!/bin/bash

# 修复 flutter_blue_plus_linux BLE 扫描问题
# 此脚本会创建本地包副本并应用补丁

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=========================================="
echo "修复 flutter_blue_plus_linux BLE 扫描问题"
echo -e "==========================================${NC}"
echo ""

# 1. 创建 packages 目录
echo -e "${YELLOW}步骤 1: 创建本地包目录${NC}"
mkdir -p packages
echo -e "${GREEN}✓ 目录已创建${NC}"
echo ""

# 2. 复制包到本地
echo -e "${YELLOW}步骤 2: 复制 flutter_blue_plus_linux 包${NC}"
PACKAGE_PATH="$HOME/.pub-cache/hosted/pub.dev/flutter_blue_plus_linux-7.0.3"
if [ ! -d "$PACKAGE_PATH" ]; then
    PACKAGE_PATH="$HOME/.pub-cache/hosted/pub.flutter-io.cn/flutter_blue_plus_linux-7.0.3"
fi

if [ ! -d "$PACKAGE_PATH" ]; then
    echo -e "${RED}✗ 找不到 flutter_blue_plus_linux 包${NC}"
    echo "  请先运行: flutter pub get"
    exit 1
fi

cp -r "$PACKAGE_PATH" packages/
echo -e "${GREEN}✓ 包已复制到 packages/flutter_blue_plus_linux-7.0.3${NC}"
echo ""

# 3. 应用补丁
echo -e "${YELLOW}步骤 3: 应用 BLE 扫描修复补丁${NC}"
PATCH_FILE="packages/flutter_blue_plus_linux-7.0.3/lib/flutter_blue_plus_linux.dart"

# 备份原文件
cp "$PATCH_FILE" "$PATCH_FILE.backup"

# 使用 sed 修改文件，在 setDiscoveryFilter 调用中添加 transport: 'le'
sed -i '/await adapter.setDiscoveryFilter(/,/);/ {
    /await adapter.setDiscoveryFilter(/a\      transport: '\''le'\'',
}' "$PATCH_FILE"

echo -e "${GREEN}✓ 补丁已应用${NC}"
echo "  修改文件: $PATCH_FILE"
echo "  备份文件: $PATCH_FILE.backup"
echo ""

# 4. 更新 pubspec.yaml
echo -e "${YELLOW}步骤 4: 更新 pubspec.yaml${NC}"

# 检查是否已经有 dependency_overrides
if grep -q "dependency_overrides:" pubspec.yaml; then
    # 检查是否已经有 flutter_blue_plus_linux 覆盖
    if grep -q "flutter_blue_plus_linux:" pubspec.yaml; then
        echo -e "${YELLOW}⚠ pubspec.yaml 中已存在 flutter_blue_plus_linux 覆盖${NC}"
        echo "  请手动检查配置"
    else
        # 在 dependency_overrides 下添加
        sed -i '/dependency_overrides:/a\  flutter_blue_plus_linux:\n    path: ./packages/flutter_blue_plus_linux-7.0.3' pubspec.yaml
        echo -e "${GREEN}✓ 已添加到现有的 dependency_overrides${NC}"
    fi
else
    # 添加新的 dependency_overrides 部分
    cat >> pubspec.yaml <<EOF

# 本地包覆盖 - 修复 Linux BLE 扫描问题
dependency_overrides:
  flutter_blue_plus_linux:
    path: ./packages/flutter_blue_plus_linux-7.0.3
EOF
    echo -e "${GREEN}✓ 已添加 dependency_overrides 到 pubspec.yaml${NC}"
fi
echo ""

# 5. 运行 flutter pub get
echo -e "${YELLOW}步骤 5: 运行 flutter pub get${NC}"
flutter pub get
echo -e "${GREEN}✓ 依赖已更新${NC}"
echo ""

# 6. 清理并重新构建
echo -e "${YELLOW}步骤 6: 清理并重新构建${NC}"
flutter clean
flutter build linux --release
echo -e "${GREEN}✓ 构建完成${NC}"
echo ""

echo -e "${GREEN}=========================================="
echo "修复完成！"
echo -e "==========================================${NC}"
echo ""
echo -e "${BLUE}修改内容：${NC}"
echo "  在 setDiscoveryFilter 调用中添加了 transport: 'le' 参数"
echo "  这将强制扫描 BLE（低功耗蓝牙）设备"
echo ""
echo -e "${BLUE}下一步：${NC}"
echo "  1. 运行应用: ./run-linux.sh"
echo "  2. 点击"开始扫描"按钮"
echo "  3. 现在应该能看到 BLE 设备了"
echo ""
echo -e "${YELLOW}注意：${NC}"
echo "  - 原始文件已备份为: $PATCH_FILE.backup"
echo "  - 如需恢复，删除 packages 目录并从 pubspec.yaml 中移除 dependency_overrides"
echo ""
