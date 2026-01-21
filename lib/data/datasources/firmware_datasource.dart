import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../models/firmware_file.dart';

/// 固件数据源
///
/// 负责加载预设固件和选择外部固件文件
class FirmwareDataSource {
  /// 加载预设固件列表
  ///
  /// 从 assets/firmware/firmware_list.json 读取配置
  Future<List<FirmwareFile>> loadPresetFirmwares() async {
    try {
      // 读取配置文件
      final jsonString = await rootBundle.loadString('assets/firmware/firmware_list.json');
      final List<dynamic> jsonList = json.decode(jsonString);

      // 解析固件列表
      final firmwares = <FirmwareFile>[];
      for (var item in jsonList) {
        try {
          final firmware = FirmwareFile.fromJson(item as Map<String, dynamic>);

          // 获取实际文件大小
          final byteData = await rootBundle.load(firmware.path);
          final actualSize = byteData.lengthInBytes;

          // 创建带实际大小的固件对象
          firmwares.add(FirmwareFile(
            name: firmware.name,
            path: firmware.path,
            size: actualSize,
            version: firmware.version,
            description: firmware.description,
            isAsset: true,
          ));
        } catch (e) {
          print('加载固件失败: $e');
          // 跳过加载失败的固件
          continue;
        }
      }

      return firmwares;
    } catch (e) {
      print('加载预设固件列表失败: $e');
      return [];
    }
  }

  /// 选择外部固件文件
  ///
  /// 使用文件选择器让用户选择 .hex 文件
  Future<FirmwareFile?> pickFirmwareFile() async {
    try {
      // 使用 FileType.any 因为 Android 不支持 .hex 扩展名
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = result.files.first;
      final filePath = file.path;

      if (filePath == null) {
        return null;
      }

      // 验证文件扩展名
      if (!filePath.toLowerCase().endsWith('.hex')) {
        print('选择的文件不是 .hex 文件: $filePath');
        throw Exception('请选择 .hex 格式的固件文件');
      }

      // 获取文件大小
      final fileSize = await File(filePath).length();

      return FirmwareFile.fromPath(filePath, fileSize);
    } catch (e) {
      print('选择固件文件失败: $e');
      rethrow;
    }
  }

  /// 读取固件文件内容
  ///
  /// 参数:
  /// - [firmware]: 固件文件对象
  ///
  /// 返回:
  /// - 文件内容字符串
  Future<String> readFirmwareContent(FirmwareFile firmware) async {
    try {
      if (firmware.isAsset) {
        // 从 assets 读取
        return await rootBundle.loadString(firmware.path);
      } else {
        // 从文件系统读取
        final file = File(firmware.path);
        return await file.readAsString();
      }
    } catch (e) {
      throw Exception('读取固件文件失败: $e');
    }
  }
}
