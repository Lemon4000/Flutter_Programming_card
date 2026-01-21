#!/bin/bash

# 一键修复 BLE 设备扫描问题
# 此脚本需要 sudo 权限

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=========================================="
echo "修复 BLE 设备扫描问题"
echo -e "==========================================${NC}"
echo ""

# 检查是否有 sudo 权限
if ! sudo -v; then
    echo -e "${RED}错误: 需要 sudo 权限${NC}"
    exit 1
fi

echo -e "${YELLOW}步骤 1: 添加用户到 bluetooth 组${NC}"
sudo usermod -a -G bluetooth $USER
echo -e "${GREEN}✓ 用户已添加到 bluetooth 组${NC}"
echo ""

echo -e "${YELLOW}步骤 2: 创建 DBus 策略文件${NC}"
sudo tee /etc/dbus-1/system.d/flutter-bluetooth.conf > /dev/null <<EOF
<!DOCTYPE busconfig PUBLIC "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN"
 "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
<busconfig>
  <policy user="$USER">
    <allow send_destination="org.bluez"/>
    <allow send_interface="org.bluez.Adapter1"/>
    <allow send_interface="org.bluez.Device1"/>
    <allow send_interface="org.bluez.GattService1"/>
    <allow send_interface="org.bluez.GattCharacteristic1"/>
    <allow send_interface="org.bluez.GattDescriptor1"/>
    <allow send_interface="org.freedesktop.DBus.Properties"/>
    <allow send_interface="org.freedesktop.DBus.ObjectManager"/>
  </policy>
</busconfig>
EOF
echo -e "${GREEN}✓ DBus 策略文件已创建${NC}"
echo ""

echo -e "${YELLOW}步骤 3: 重启 DBus 服务${NC}"
sudo systemctl restart dbus
echo -e "${GREEN}✓ DBus 服务已重启${NC}"
echo ""

echo -e "${YELLOW}步骤 4: 验证配置${NC}"
if [ -f /etc/dbus-1/system.d/flutter-bluetooth.conf ]; then
    echo -e "${GREEN}✓ DBus 策略文件存在${NC}"
else
    echo -e "${RED}✗ DBus 策略文件未找到${NC}"
fi
echo ""

echo -e "${GREEN}=========================================="
echo "修复完成！"
echo -e "==========================================${NC}"
echo ""
echo -e "${YELLOW}重要提示:${NC}"
echo "  用户组更改需要注销并重新登录才能生效"
echo ""
echo -e "${BLUE}下一步:${NC}"
echo "  1. 注销当前会话"
echo "  2. 重新登录"
echo "  3. 运行应用: ./run-linux.sh"
echo "  4. 扫描设备，现在应该能看到 BLE 设备了"
echo ""
echo -e "${YELLOW}验证修复:${NC}"
echo "  重新登录后，运行以下命令验证:"
echo "  ${GREEN}groups${NC}  # 应该包含 'bluetooth'"
echo ""
