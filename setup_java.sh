#!/bin/bash

echo "=== 安装Java和配置Android开发环境 ==="

# 1. 安装OpenJDK 17
echo "1. 安装OpenJDK 17..."
sudo apt update
sudo apt install -y openjdk-17-jdk

# 2. 验证Java安装
echo ""
echo "2. 验证Java安装..."
java -version

# 3. 设置JAVA_HOME
echo ""
echo "3. 设置JAVA_HOME环境变量..."
JAVA_PATH=$(update-alternatives --query java | grep 'Value:' | awk '{print $2}' | sed 's|/bin/java||')
echo "Java路径: $JAVA_PATH"

# 添加到bashrc（如果还没有）
if ! grep -q "JAVA_HOME" ~/.bashrc; then
    echo "export JAVA_HOME=$JAVA_PATH" >> ~/.bashrc
    echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> ~/.bashrc
    echo "已添加JAVA_HOME到 ~/.bashrc"
fi

# 4. 应用环境变量
echo ""
echo "4. 应用环境变量..."
export JAVA_HOME=$JAVA_PATH
export PATH=$JAVA_HOME/bin:$PATH

echo ""
echo "JAVA_HOME=$JAVA_HOME"
echo ""

# 5. 运行flutter doctor
echo "5. 检查Flutter环境..."
cd /home/lemon/桌面/docs/plans/flutter
flutter doctor

echo ""
echo "=== 安装完成 ==="
echo ""
echo "现在可以运行: flutter run"
echo ""
echo "如果需要重新加载环境变量，运行: source ~/.bashrc"
