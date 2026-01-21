/// 固件文件模型
class FirmwareFile {
  /// 显示名称
  final String name;

  /// 文件路径（assets路径或文件系统路径）
  final String path;

  /// 文件大小（字节）
  final int size;

  /// 版本号（可选）
  final String? version;

  /// 描述信息（可选）
  final String? description;

  /// 是否为内置资源
  final bool isAsset;

  const FirmwareFile({
    required this.name,
    required this.path,
    required this.size,
    this.version,
    this.description,
    this.isAsset = false,
  });

  /// 格式化文件大小显示
  String get sizeFormatted {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// 从 JSON 创建（用于解析配置文件）
  factory FirmwareFile.fromJson(Map<String, dynamic> json) {
    return FirmwareFile(
      name: json['name'] as String,
      path: 'assets/firmware/${json['filename']}',
      size: json['size'] as int? ?? 0,
      version: json['version'] as String?,
      description: json['description'] as String?,
      isAsset: true,
    );
  }

  /// 从文件路径创建（用于外部选择的文件）
  factory FirmwareFile.fromPath(String filePath, int fileSize) {
    final fileName = filePath.split('/').last;
    return FirmwareFile(
      name: fileName,
      path: filePath,
      size: fileSize,
      isAsset: false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FirmwareFile && other.path == path;
  }

  @override
  int get hashCode => path.hashCode;

  @override
  String toString() {
    return 'FirmwareFile(name: $name, size: $sizeFormatted, version: $version, isAsset: $isAsset)';
  }
}
