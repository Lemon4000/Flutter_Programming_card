#!/bin/bash

# 编程卡上位机 DEB 包快速安装脚本
# 版本: v1.0.0

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

DEB_FILE="programming-card-host_1.0.0.deb"

echo -e "${BLUE}=================================="
echo "编程卡上位机 v1.0.0"
echo "DEB 包快速安装脚本"
echo -e "==================================${NC}"
echo ""

# 检查是否为 root
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}注意: 此脚本需要 sudo 权限${NC}"
    echo "将提示您输入密码..."
    echo ""
fi

# 检查 DEB 文件是否存在
if [ ! -f "$DEB_FILE" ]; then
    echo -e "${RED}错误: 找不到 DEB 包: $DEB_FILE${NC}"
    echo "请确保在包含 DEB 文件的目录中运行此脚本"
    exit 1
fi

echo -e "${GREEN}✓${NC} 找到 DEB 包: $DEB_FILE"
echo ""

# 步骤 1: 检查 Waydroid
echo "步骤 1/3: 检查 Waydroid..."
if command -v waydroid &> /dev/null; then
    echo -e "${GREEN}✓${NC} Waydroid 已安装"
else
    echo -e "${YELLOW}⚠${NC}  Waydroid 未安装"
    echo ""
    read -p "是否现在安装 Waydroid? (Y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        echo "正在安装 Waydroid..."

        # 检查是否为 Ubuntu/Debian
        if [ -f /etc/debian_version ]; then
            # 添加 Waydroid 仓库
            echo "添加 Waydroid 仓库..."
            curl https://repo.waydro.id 2>/dev/null | sudo bash || {
                echo -e "${YELLOW}警告: 无法添加 Waydroid 仓库${NC}"
                echo "请手动安装 Waydroid: sudo apt install waydroid"
            }

            # 安装 Waydroid
            sudo apt update
            sudo apt install -y waydroid

            echo -e "${GREEN}✓${NC} Waydroid 安装完成"
        else
            echo -e "${YELLOW}警告: 非 Debian/Ubuntu 系统${NC}"
            echo "请参考 https://waydro.id/ 手动安装 Waydroid"
        fi
    else
        echo -e "${YELLOW}跳过 Waydroid 安装${NC}"
        echo "注意: 应用需要 Waydroid 才能运行"
    fi
fi
echo ""

# 步骤 2: 安装 DEB 包
echo "步骤 2/3: 安装 DEB 包..."
if sudo dpkg -i "$DEB_FILE" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} DEB 包安装成功"
else
    echo -e "${YELLOW}⚠${NC}  检测到依赖问题，正在修复..."
    sudo apt-get install -f -y
    echo -e "${GREEN}✓${NC} 依赖问题已解决"
fi
echo ""

# 步骤 3: 初始化 Waydroid
echo "步骤 3/3: 初始化 Waydroid..."
if command -v waydroid &> /dev/null; then
    if [ ! -d "/var/lib/waydroid" ] && [ ! -d "$HOME/.local/share/waydroid" ]; then
        echo "首次运行，正在初始化 Waydroid..."
        read -p "是否现在初始化 Waydroid? (Y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            waydroid init
            echo -e "${GREEN}✓${NC} Waydroid 初始化完成"
        else
            echo -e "${YELLOW}跳过 Waydroid 初始化${NC}"
            echo "稍后可以运行: waydroid init"
        fi
    else
        echo -e "${GREEN}✓${NC} Waydroid 已初始化"
    fi
else
    echo -e "${YELLOW}⚠${NC}  Waydroid 未安装，跳过初始化"
fi
echo ""

# 安装完成
echo -e "${GREEN}=================================="
echo "✓ 安装完成！"
echo -e "==================================${NC}"
echo ""
echo "使用方法:"
echo "  1. 命令行启动: ${BLUE}programming-card-host${NC}"
echo "  2. 应用菜单: 搜索 '编程卡上位机'"
echo ""
echo "首次运行提示:"
echo "  - 应用会自动安装到 Waydroid"
echo "  - 需要授予蓝牙、位置、存储权限"
echo "  - 首次启动可能需要 30 秒"
echo ""

# 询问是否立即启动
read -p "是否现在启动应用? (Y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    echo ""
    echo "正在启动编程卡上位机..."
    programming-card-host &
    echo ""
    echo -e "${GREEN}✓${NC} 应用已启动"
    echo "请在 Waydroid 窗口中查看应用"
fi

echo ""
echo "文档位置:"
echo "  /usr/share/doc/programming-card-host/"
echo ""
echo "如需帮助，请查看: DEB_INSTALL_GUIDE.md"
echo ""
