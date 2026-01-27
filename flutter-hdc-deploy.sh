#!/bin/bash

# Flutter + HDC 开发部署脚本
# 用于在鸿蒙设备上部署和调试Flutter应用

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# HDC路径
HDC="$HOME/harmonyos-tools/hwsdk/openharmony/9/toolchains/hdc"

# 检查HDC是否可用
if [ ! -f "$HDC" ]; then
    echo -e "${RED}错误: HDC工具未找到${NC}"
    echo "请先运行 install_hdc.sh 安装HDC工具"
    exit 1
fi

# 显示帮助信息
show_help() {
    echo "Flutter + HDC 开发部署脚本"
    echo ""
    echo "用法: $0 [命令] [选项]"
    echo ""
    echo "命令:"
    echo "  build         - 构建Flutter APK"
    echo "  install       - 安装APK到设备"
    echo "  deploy        - 构建并安装（默认）"
    echo "  log           - 查看应用日志"
    echo "  devices       - 列出连接的设备"
    echo "  clean         - 清理构建文件"
    echo "  help          - 显示此帮助信息"
    echo ""
    echo "选项:"
    echo "  --debug       - 构建debug版本（默认）"
    echo "  --release     - 构建release版本"
    echo "  --profile     - 构建profile版本"
    echo ""
    echo "示例:"
    echo "  $0 deploy              # 构建debug版本并安装"
    echo "  $0 deploy --release    # 构建release版本并安装"
    echo "  $0 log                 # 查看应用日志"
}

# 检查设备连接
check_device() {
    echo -e "${BLUE}检查设备连接...${NC}"
    DEVICE=$($HDC list targets 2>&1 | grep -v "^\[" | head -1)

    if [ -z "$DEVICE" ]; then
        echo -e "${RED}错误: 未找到连接的设备${NC}"
        echo "请确保:"
        echo "1. 设备已通过USB连接"
        echo "2. 设备已开启USB调试（HDC模式）"
        echo "3. 运行 'hdc list targets' 查看设备"
        exit 1
    fi

    echo -e "${GREEN}✓ 找到设备: $DEVICE${NC}"
}

# 构建Flutter应用
build_flutter() {
    local BUILD_MODE=${1:-debug}

    echo -e "${BLUE}构建Flutter应用 ($BUILD_MODE 模式)...${NC}"

    case $BUILD_MODE in
        debug)
            flutter build apk --debug
            APK_PATH="build/app/outputs/flutter-apk/app-debug.apk"
            ;;
        release)
            flutter build apk --release
            APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
            ;;
        profile)
            flutter build apk --profile
            APK_PATH="build/app/outputs/flutter-apk/app-profile.apk"
            ;;
        *)
            echo -e "${RED}错误: 未知的构建模式: $BUILD_MODE${NC}"
            exit 1
            ;;
    esac

    if [ ! -f "$APK_PATH" ]; then
        echo -e "${RED}错误: APK文件未找到: $APK_PATH${NC}"
        exit 1
    fi

    echo -e "${GREEN}✓ 构建完成: $APK_PATH${NC}"
}

# 安装应用到设备
install_app() {
    if [ -z "$APK_PATH" ]; then
        echo -e "${RED}错误: 未指定APK路径${NC}"
        exit 1
    fi

    echo -e "${BLUE}安装应用到设备...${NC}"
    echo "APK: $APK_PATH"

    # 尝试安装，忽略版本警告
    if $HDC install -r "$APK_PATH" 2>&1 | grep -q "Success\|success"; then
        echo -e "${GREEN}✓ 应用安装成功${NC}"
    else
        echo -e "${YELLOW}注意: 安装命令已执行，但可能因版本兼容性问题无法确认状态${NC}"
        echo -e "${YELLOW}请在设备上检查应用是否已安装${NC}"
    fi
}

# 查看应用日志
view_logs() {
    echo -e "${BLUE}查看应用日志...${NC}"
    echo "按 Ctrl+C 停止"
    echo ""

    # 尝试使用hilog，如果失败则提示
    if ! $HDC hilog 2>&1; then
        echo ""
        echo -e "${YELLOW}注意: hilog命令可能因版本兼容性问题无法使用${NC}"
        echo -e "${YELLOW}建议:${NC}"
        echo "1. 在设备上手动启动应用"
        echo "2. 观察应用行为"
        echo "3. 或使用DevEco Studio查看日志"
    fi
}

# 列出设备
list_devices() {
    echo -e "${BLUE}连接的设备:${NC}"
    $HDC list targets 2>&1 | grep -v "^\["
}

# 清理构建文件
clean_build() {
    echo -e "${BLUE}清理构建文件...${NC}"
    flutter clean
    echo -e "${GREEN}✓ 清理完成${NC}"
}

# 主函数
main() {
    local COMMAND=${1:-deploy}
    local BUILD_MODE="debug"

    # 解析参数
    shift || true
    while [[ $# -gt 0 ]]; do
        case $1 in
            --debug)
                BUILD_MODE="debug"
                shift
                ;;
            --release)
                BUILD_MODE="release"
                shift
                ;;
            --profile)
                BUILD_MODE="profile"
                shift
                ;;
            *)
                echo -e "${RED}错误: 未知选项: $1${NC}"
                show_help
                exit 1
                ;;
        esac
    done

    # 执行命令
    case $COMMAND in
        build)
            build_flutter $BUILD_MODE
            ;;
        install)
            check_device
            # 查找最新的APK
            if [ -f "build/app/outputs/flutter-apk/app-debug.apk" ]; then
                APK_PATH="build/app/outputs/flutter-apk/app-debug.apk"
            elif [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
                APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
            else
                echo -e "${RED}错误: 未找到APK文件，请先运行 build 命令${NC}"
                exit 1
            fi
            install_app
            ;;
        deploy)
            check_device
            build_flutter $BUILD_MODE
            install_app
            echo ""
            echo -e "${GREEN}========================================${NC}"
            echo -e "${GREEN}部署完成！${NC}"
            echo -e "${GREEN}========================================${NC}"
            echo ""
            echo "下一步:"
            echo "1. 在设备上手动启动应用"
            echo "2. 运行 '$0 log' 查看日志（如果可用）"
            echo "3. 测试应用功能"
            ;;
        log)
            check_device
            view_logs
            ;;
        devices)
            list_devices
            ;;
        clean)
            clean_build
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo -e "${RED}错误: 未知命令: $COMMAND${NC}"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"
