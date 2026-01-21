#!/bin/bash

# 蓝牙权限快速修复脚本
# 此脚本包含需要您手动执行的 sudo 命令

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=================================="
echo "蓝牙权限快速修复"
echo -e "==================================${NC}"
echo ""

echo "此脚本将帮助您修复蓝牙连接问题"
echo "需要执行以下步骤（需要 sudo 权限）:"
echo ""

# 步骤 1: 添加用户到 bluetooth 组
echo -e "${YELLOW}步骤 1: 添加用户到 bluetooth 组${NC}"
echo ""
echo "请在新终端中执行:"
echo -e "${GREEN}sudo usermod -a -G bluetooth $USER${NC}"
echo ""
read -p "完成后按 Enter 继续..."
echo ""

# 步骤 2: 创建 DBus 策略文件
echo -e "${YELLOW}步骤 2: 创建 DBus 策略文件${NC}"
echo ""
echo "请在新终端中执行以下命令:"
echo ""
echo -e "${GREEN}sudo tee /etc/dbus-1/system.d/flutter-bluetooth.conf > /dev/null <<'EOF'
<!DOCTYPE busconfig PUBLIC \"-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN\"
 \"http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd\">
<busconfig>
  <policy user=\"$USER\">
    <allow send_destination=\"org.bluez\"/>
    <allow send_interface=\"org.bluez.Adapter1\"/>
    <allow send_interface=\"org.bluez.Device1\"/>
    <allow send_interface=\"org.bluez.GattService1\"/>
    <allow send_interface=\"org.bluez.GattCharacteristic1\"/>
    <allow send_interface=\"org.bluez.GattDescriptor1\"/>
    <allow send_interface=\"org.freedesktop.DBus.Properties\"/>
    <allow send_interface=\"org.freedesktop.DBus.ObjectManager\"/>
  </policy>
</busconfig>
EOF${NC}"
echo ""
read -p "完成后按 Enter 继续..."
echo ""

# 步骤 3: 重启 DBus
echo -e "${YELLOW}步骤 3: 重启 DBus 服务${NC}"
echo ""
echo "请在新终端中执行:"
echo -e "${GREEN}sudo systemctl restart dbus${NC}"
echo ""
read -p "完成后按 Enter 继续..."
echo ""

# 步骤 4: 验证配置
echo -e "${YELLOW}步骤 4: 验证配置${NC}"
echo ""

# 检查 DBus 策略文件
if [ -f /etc/dbus-1/system.d/flutter-bluetooth.conf ]; then
    echo -e "${GREEN}✓${NC} DBus 策略文件已创建"
else
    echo -e "${RED}✗${NC} DBus 策略文件未找到"
fi

# 检查用户组（需要重新登录后才生效）
echo ""
echo -e "${YELLOW}注意${NC}: 用户组更改需要注销并重新登录后才能生效"
echo ""

# 完成
echo -e "${GREEN}=================================="
echo "配置完成！"
echo -e "==================================${NC}"
echo ""
echo "下一步:"
echo "  1. ${YELLOW}注销并重新登录${NC}（使用户组更改生效）"
echo "  2. 重新运行应用: ${BLUE}./run-linux.sh${NC}"
echo "  3. 尝试扫描蓝牙设备"
echo ""
echo "如果仍然无法连接，请查看:"
echo "  - BLUETOOTH_TROUBLESHOOTING.md"
echo "  - 或考虑使用 Android APK 版本"
echo ""
