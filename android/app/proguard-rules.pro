# 禁用 Android 蓝牙日志
-assumenosideeffects class android.bluetooth.BluetoothGatt {
    public void writeCharacteristic(...);
}
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}
