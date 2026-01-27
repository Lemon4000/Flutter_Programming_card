#!/bin/bash

# HarmonyOS HDC工具安装脚本
# 此脚本帮助您下载和安装HDC工具

set -e

echo "=========================================="
echo "HarmonyOS HDC工具安装脚本"
echo "=========================================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 工具目录
TOOLS_DIR="$HOME/harmonyos-tools"
# 支持中英文下载目录
if [ -d "$HOME/下载" ]; then
    DOWNLOAD_DIR="$HOME/下载"
else
    DOWNLOAD_DIR="$HOME/Downloads"
fi

echo -e "${YELLOW}步骤 1: 检查系统环境${NC}"
echo "操作系统: $(uname -s)"
echo "架构: $(uname -m)"
echo ""

# 检查是否已经下载了文件
COMMANDLINE_TOOLS_FILE="commandline-tools-linux-2.0.0.2.zip"
COMMANDLINE_TOOLS_PATH="$DOWNLOAD_DIR/$COMMANDLINE_TOOLS_FILE"

if [ -f "$COMMANDLINE_TOOLS_PATH" ]; then
    echo -e "${GREEN}✓ 找到已下载的文件: $COMMANDLINE_TOOLS_PATH${NC}"
else
    echo -e "${RED}✗ 未找到下载文件${NC}"
    echo ""
    echo "请按照以下步骤手动下载："
    echo ""
    echo "1. 打开浏览器访问："
    echo "   https://developer.huawei.com/consumer/cn/deveco-studio/archive/"
    echo ""
    echo "2. 在页面中找到并下载："
    echo "   文件名: commandline-tools-linux-2.0.0.2.zip"
    echo "   大小: 29.7M"
    echo "   SHA-256: 897efe0e4df015e44869f9322026fbd80c365a1d67387031168ab53c6eb6d0d4"
    echo ""
    echo "3. 将下载的文件保存到: $DOWNLOAD_DIR"
    echo ""
    echo "4. 下载完成后，重新运行此脚本"
    echo ""
    exit 1
fi

echo ""
echo -e "${YELLOW}步骤 2: 验证文件完整性${NC}"
EXPECTED_SHA256="897efe0e4df015e44869f9322026fbd80c365a1d67387031168ab53c6eb6d0d4"
ACTUAL_SHA256=$(sha256sum "$COMMANDLINE_TOOLS_PATH" | awk '{print $1}')

if [ "$ACTUAL_SHA256" = "$EXPECTED_SHA256" ]; then
    echo -e "${GREEN}✓ 文件校验通过${NC}"
else
    echo -e "${RED}✗ 文件校验失败${NC}"
    echo "期望: $EXPECTED_SHA256"
    echo "实际: $ACTUAL_SHA256"
    echo ""
    echo "文件可能已损坏，请重新下载"
    exit 1
fi

echo ""
echo -e "${YELLOW}步骤 3: 创建工具目录${NC}"
mkdir -p "$TOOLS_DIR"
echo -e "${GREEN}✓ 目录已创建: $TOOLS_DIR${NC}"

echo ""
echo -e "${YELLOW}步骤 4: 解压文件${NC}"
cd "$TOOLS_DIR"
unzip -q "$COMMANDLINE_TOOLS_PATH"
echo -e "${GREEN}✓ 文件已解压${NC}"

echo ""
echo -e "${YELLOW}步骤 5: 查找HDC工具${NC}"
# 查找hdc可执行文件
HDC_PATH=$(find "$TOOLS_DIR" -name "hdc" -type f 2>/dev/null | head -n 1)

if [ -z "$HDC_PATH" ]; then
    echo -e "${RED}✗ 未找到HDC工具${NC}"
    echo "解压后的文件结构："
    ls -la "$TOOLS_DIR"
    exit 1
fi

echo -e "${GREEN}✓ 找到HDC工具: $HDC_PATH${NC}"

# 获取HDC所在目录
HDC_DIR=$(dirname "$HDC_PATH")
echo "HDC目录: $HDC_DIR"

# 赋予执行权限
chmod +x "$HDC_PATH"
echo -e "${GREEN}✓ 已设置执行权限${NC}"

echo ""
echo -e "${YELLOW}步骤 6: 配置环境变量${NC}"

# 检查是否已经添加到PATH
if grep -q "$HDC_DIR" "$HOME/.bashrc"; then
    echo -e "${YELLOW}! 环境变量已存在于 ~/.bashrc${NC}"
else
    echo "" >> "$HOME/.bashrc"
    echo "# HarmonyOS HDC工具" >> "$HOME/.bashrc"
    echo "export PATH=\"$HDC_DIR:\$PATH\"" >> "$HOME/.bashrc"
    echo -e "${GREEN}✓ 已添加到 ~/.bashrc${NC}"
fi

# 同时添加到 ~/.profile
if [ -f "$HOME/.profile" ]; then
    if grep -q "$HDC_DIR" "$HOME/.profile"; then
        echo -e "${YELLOW}! 环境变量已存在于 ~/.profile${NC}"
    else
        echo "" >> "$HOME/.profile"
        echo "# HarmonyOS HDC工具" >> "$HOME/.profile"
        echo "export PATH=\"$HDC_DIR:\$PATH\"" >> "$HOME/.profile"
        echo -e "${GREEN}✓ 已添加到 ~/.profile${NC}"
    fi
fi

echo ""
echo -e "${YELLOW}步骤 7: 测试HDC工具${NC}"
export PATH="$HDC_DIR:$PATH"

if command -v hdc &> /dev/null; then
    echo -e "${GREEN}✓ HDC工具可用${NC}"
    echo ""
    echo "HDC版本信息："
    hdc -v || hdc version || echo "无法获取版本信息"
else
    echo -e "${RED}✗ HDC工具不可用${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}步骤 8: 检查设备连接${NC}"
echo "正在查找连接的设备..."
hdc list targets || echo "未找到设备或命令失败"

echo ""
echo "=========================================="
echo -e "${GREEN}安装完成！${NC}"
echo "=========================================="
echo ""
echo "重要提示："
echo "1. 请重新打开终端或运行以下命令使环境变量生效："
echo "   source ~/.bashrc"
echo ""
echo "2. 验证安装："
echo "   hdc -v"
echo ""
echo "3. 列出连接的设备："
echo "   hdc list targets"
echo ""
echo "4. 如果看到您的设备ID，说明连接成功！"
echo ""
echo "注意：Flutter目前不直接支持HDC协议。"
echo "如果您想使用Flutter开发，建议在设备上启用ADB模式。"
echo "详见: enable_adb_on_harmonyos.md"
echo ""
