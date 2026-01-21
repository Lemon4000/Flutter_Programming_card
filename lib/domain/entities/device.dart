/// 设备实体
///
/// 领域层的设备模型
class Device {
  /// 设备ID
  final String id;

  /// 设备名称
  final String name;

  /// 信号强度
  final int rssi;

  /// 是否已连接
  final bool isConnected;

  const Device({
    required this.id,
    required this.name,
    required this.rssi,
    required this.isConnected,
  });

  /// 复制并更新
  Device copyWith({
    String? id,
    String? name,
    int? rssi,
    bool? isConnected,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      rssi: rssi ?? this.rssi,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Device &&
        other.id == id &&
        other.name == name &&
        other.rssi == rssi &&
        other.isConnected == isConnected;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, rssi, isConnected);
  }

  @override
  String toString() {
    return 'Device(id: $id, name: $name, rssi: $rssi, isConnected: $isConnected)';
  }
}
