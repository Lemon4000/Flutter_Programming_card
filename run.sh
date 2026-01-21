#!/bin/bash

# 配置 Flutter 国内镜像
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

# 运行 Flutter
flutter run -v "$@"
