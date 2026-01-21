#!/bin/bash

# Flutter Linux 原生应用构建脚本
# 此脚本需要手动执行某些需要 sudo 的步骤

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=================================="
echo "Flutter Linux 原生应用构建指南"
echo -e "==================================${NC}"
echo ""

# 步骤 1: 卸载 snap 版本的 Flutter
echo -e "${YELLOW}步骤 1: 卸载 snap 版本的 Flutter${NC}"
echo ""
echo "请在新终端中执行以下命令:"
echo -e "${GREEN}sudo snap remove flutter${NC}"
echo ""
read -p "完成后按 Enter 继续..."
echo ""

# 步骤 2: 下载官方 Flutter
echo -e "${YELLOW}步骤 2: 下载官方 Flutter SDK${NC}"
echo ""
if [ -d "$HOME/flutter" ]; then
    echo -e "${YELLOW}检测到 ~/flutter 目录已存在${NC}"
    read -p "是否删除并重新下载? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$HOME/flutter"
    else
        echo "跳过下载，使用现有 Flutter"
    fi
fi

if [ ! -d "$HOME/flutter" ]; then
    echo "正在下载 Flutter SDK..."
    cd ~
    git clone https://github.com/flutter/flutter.git -b stable --depth 1
    echo -e "${GREEN}✓ Flutter SDK 下载完成${NC}"
else
    echo -e "${GREEN}✓ Flutter SDK 已存在${NC}"
fi
echo ""

# 步骤 3: 配置环境变量
echo -e "${YELLOW}步骤 3: 配置环境变量${NC}"
echo ""
if ! grep -q "export PATH=\"\$PATH:\$HOME/flutter/bin\"" ~/.bashrc; then
    echo "添加 Flutter 到 PATH..."
    echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
    echo -e "${GREEN}✓ 已添加到 ~/.bashrc${NC}"
else
    echo -e "${GREEN}✓ PATH 已配置${NC}"
fi

# 临时设置 PATH
export PATH="$PATH:$HOME/flutter/bin"
echo ""

# 步骤 4: 安装 Linux 构建依赖
echo -e "${YELLOW}步骤 4: 安装 Linux 构建依赖${NC}"
echo ""
echo "需要安装以下依赖包:"
echo "  - clang"
echo "  - cmake"
echo "  - ninja-build"
echo "  - pkg-config"
echo "  - libgtk-3-dev"
echo "  - liblzma-dev"
echo "  - libstdc++-12-dev"
echo ""
echo "请在新终端中执行以下命令:"
echo -e "${GREEN}sudo apt-get update${NC}"
echo -e "${GREEN}sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev${NC}"
echo ""
read -p "完成后按 Enter 继续..."
echo ""

# 步骤 5: 运行 flutter doctor
echo -e "${YELLOW}步骤 5: 检查 Flutter 环境${NC}"
echo ""
echo "运行 flutter doctor..."
$HOME/flutter/bin/flutter doctor
echo ""
read -p "检查完成后按 Enter 继续..."
echo ""

# 步骤 6: 启用 Linux 桌面支持
echo -e "${YELLOW}步骤 6: 启用 Linux 桌面支持${NC}"
echo ""
$HOME/flutter/bin/flutter config --enable-linux-desktop
echo -e "${GREEN}✓ Linux 桌面支持已启用${NC}"
echo ""

# 步骤 7: 构建 Linux 应用
echo -e "${YELLOW}步骤 7: 构建 Linux Release 应用${NC}"
echo ""
echo "开始构建..."
cd /home/lemon/桌面/docs/plans/flutter

# 清理之前的构建
$HOME/flutter/bin/flutter clean

# 获取依赖
$HOME/flutter/bin/flutter pub get

# 构建 Linux 应用
if $HOME/flutter/bin/flutter build linux --release; then
    echo ""
    echo -e "${GREEN}=================================="
    echo "✓ 构建成功！"
    echo -e "==================================${NC}"
    echo ""
    echo "构建产物位置:"
    echo "  build/linux/x64/release/bundle/"
    echo ""
    echo "运行应用:"
    echo "  cd build/linux/x64/release/bundle"
    echo "  ./programming_card_host"
    echo ""
else
    echo ""
    echo -e "${RED}=================================="
    echo "✗ 构建失败"
    echo -e "==================================${NC}"
    echo ""
    echo "请检查错误信息并重试"
    exit 1
fi

# 步骤 8: 创建启动脚本
echo -e "${YELLOW}步骤 8: 创建启动脚本${NC}"
echo ""
cat > run-linux.sh <<'SCRIPT'
#!/bin/bash
cd "$(dirname "$0")/build/linux/x64/release/bundle"
./programming_card_host
SCRIPT
chmod +x run-linux.sh
echo -e "${GREEN}✓ 启动脚本已创建: run-linux.sh${NC}"
echo ""

# 完成
echo -e "${GREEN}=================================="
echo "✓ 所有步骤完成！"
echo -e "==================================${NC}"
echo ""
echo "使用方法:"
echo "  1. 重新加载环境变量: ${BLUE}source ~/.bashrc${NC}"
echo "  2. 运行应用: ${BLUE}./run-linux.sh${NC}"
echo "  或直接运行: ${BLUE}cd build/linux/x64/release/bundle && ./programming_card_host${NC}"
echo ""
echo "注意事项:"
echo "  - 首次运行可能需要一些时间"
echo "  - 确保蓝牙设备已连接"
echo "  - 如需重新构建: ${BLUE}$HOME/flutter/bin/flutter build linux --release${NC}"
echo ""
