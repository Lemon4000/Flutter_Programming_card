#!/bin/bash

# 蓝牙连接问题诊断脚本

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=================================="
echo "蓝牙连接问题诊断"
echo -e "==================================${NC}"
echo ""

# 1. 检查蓝牙服务
echo -e "${YELLOW}1. 检查蓝牙服务${NC}"
if systemctl is-active --quiet bluetooth; then
    echo -e "${GREEN}✓${NC} 蓝牙服务正在运行"
else
    echo -e "${RED}✗${NC} 蓝牙服务未运行"
    echo "  请运行: sudo systemctl start bluetooth"
fi
echo ""

# 2. 检查蓝牙控制器
echo -e "${YELLOW}2. 检查蓝牙控制器${NC}"
if bluetoothctl show | grep -q "Powered: yes"; then
    echo -e "${GREEN}✓${NC} 蓝牙已开启"
else
    echo -e "${RED}✗${NC} 蓝牙未开启"
    echo "  请运行: bluetoothctl power on"
fi
echo ""

# 3. 检查用户组
echo -e "${YELLOW}3. 检查用户权限${NC}"
if groups | grep -q "bluetooth"; then
    echo -e "${GREEN}✓${NC} 用户在 bluetooth 组中"
else
    echo -e "${YELLOW}⚠${NC}  用户不在 bluetooth 组中"
    echo "  这可能不是必需的，但建议添加:"
    echo "  ${GREEN}sudo usermod -a -G bluetooth $USER${NC}"
    echo "  然后注销并重新登录"
fi
echo ""

# 4. 检查 DBus
echo -e "${YELLOW}4. 检查 DBus${NC}"
if command -v dbus-send &> /dev/null; then
    echo -e "${GREEN}✓${NC} DBus 已安装"

    # 检查 BlueZ DBus 接口
    if dbus-send --system --print-reply --dest=org.bluez / org.freedesktop.DBus.Introspectable.Introspect &> /dev/null; then
        echo -e "${GREEN}✓${NC} BlueZ DBus 接口可访问"
    else
        echo -e "${RED}✗${NC} BlueZ DBus 接口不可访问"
        echo "  这可能是权限问题"
    fi
else
    echo -e "${RED}✗${NC} DBus 未安装"
    echo "  请运行: sudo apt-get install dbus"
fi
echo ""

# 5. 检查 BlueZ
echo -e "${YELLOW}5. 检查 BlueZ${NC}"
if command -v bluetoothctl &> /dev/null; then
    BLUEZ_VERSION=$(bluetoothctl --version 2>&1 | head -1)
    echo -e "${GREEN}✓${NC} BlueZ 已安装: $BLUEZ_VERSION"
else
    echo -e "${RED}✗${NC} BlueZ 未安装"
    echo "  请运行: sudo apt-get install bluez"
fi
echo ""

# 6. 检查蓝牙设备
echo -e "${YELLOW}6. 扫描蓝牙设备${NC}"
echo "正在扫描 5 秒..."
timeout 5 bluetoothctl scan on 2>&1 | grep -E "Device|Discovery" | head -10 || echo "扫描超时或无设备"
echo ""

# 7. 检查 Flutter 应用权限
echo -e "${YELLOW}7. 检查应用文件${NC}"
APP_PATH="build/linux/x64/release/bundle/programming_card_host"
if [ -f "$APP_PATH" ]; then
    echo -e "${GREEN}✓${NC} 应用文件存在"

    # 检查是否可执行
    if [ -x "$APP_PATH" ]; then
        echo -e "${GREEN}✓${NC} 应用可执行"
    else
        echo -e "${RED}✗${NC} 应用不可执行"
        echo "  请运行: chmod +x $APP_PATH"
    fi
else
    echo -e "${RED}✗${NC} 应用文件不存在"
    echo "  请先构建应用"
fi
echo ""

# 8. 检查依赖库
echo -e "${YELLOW}8. 检查应用依赖${NC}"
if [ -f "$APP_PATH" ]; then
    MISSING_LIBS=$(ldd "$APP_PATH" 2>&1 | grep "not found" | wc -l)
    if [ "$MISSING_LIBS" -eq 0 ]; then
        echo -e "${GREEN}✓${NC} 所有依赖库已安装"
    else
        echo -e "${RED}✗${NC} 缺少 $MISSING_LIBS 个依赖库"
        echo "  缺少的库:"
        ldd "$APP_PATH" 2>&1 | grep "not found"
    fi
fi
echo ""

# 9. 常见问题和解决方案
echo -e "${BLUE}=================================="
echo "常见问题和解决方案"
echo -e "==================================${NC}"
echo ""

echo -e "${YELLOW}问题 1: 应用无法扫描蓝牙设备${NC}"
echo "解决方案:"
echo "  1. 确保蓝牙已开启: bluetoothctl power on"
echo "  2. 添加用户到 bluetooth 组:"
echo "     ${GREEN}sudo usermod -a -G bluetooth \$USER${NC}"
echo "     然后注销并重新登录"
echo ""

echo -e "${YELLOW}问题 2: DBus 权限错误${NC}"
echo "解决方案:"
echo "  创建 DBus 策略文件:"
echo "  ${GREEN}sudo nano /etc/dbus-1/system.d/flutter-bluetooth.conf${NC}"
echo ""
echo "  添加以下内容:"
echo '  <!DOCTYPE busconfig PUBLIC "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN"'
echo '   "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">'
echo '  <busconfig>'
echo '    <policy user="'$USER'">'
echo '      <allow send_destination="org.bluez"/>'
echo '      <allow send_interface="org.bluez.Adapter1"/>'
echo '      <allow send_interface="org.bluez.Device1"/>'
echo '      <allow send_interface="org.bluez.GattService1"/>'
echo '      <allow send_interface="org.bluez.GattCharacteristic1"/>'
echo '    </policy>'
echo '  </busconfig>'
echo ""
echo "  然后重启 DBus:"
echo "  ${GREEN}sudo systemctl restart dbus${NC}"
echo ""

echo -e "${YELLOW}问题 3: flutter_blue_plus 在 Linux 上的限制${NC}"
echo "说明:"
echo "  flutter_blue_plus 在 Linux 上通过 BlueZ DBus API 工作"
echo "  某些功能可能受限或需要额外配置"
echo ""
echo "  如果问题持续，考虑:"
echo "  1. 使用 Android APK (完整蓝牙支持)"
echo "  2. 使用 DEB 包 + Waydroid"
echo "  3. 检查 flutter_blue_plus Linux 文档"
echo ""

echo -e "${BLUE}=================================="
echo "诊断完成"
echo -e "==================================${NC}"
echo ""
echo "如需更多帮助，请查看:"
echo "  - flutter_blue_plus 文档: https://pub.dev/packages/flutter_blue_plus"
echo "  - BlueZ 文档: http://www.bluez.org/"
echo ""
