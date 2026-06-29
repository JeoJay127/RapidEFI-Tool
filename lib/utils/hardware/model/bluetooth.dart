import 'hardware_model_parsing.dart';

/// 蓝牙设备
class BluetoothDevice {
  String? busType;
  String? deviceID;
  String? deviceDesc;
  String? acpiPath;
  String? pciPath;

  BluetoothDevice({
    this.busType,
    this.deviceID,
    this.deviceDesc,
    this.acpiPath,
    this.pciPath,
  });

  factory BluetoothDevice.fromJson(Map<String, dynamic> json) {
    return BluetoothDevice(
      busType: HardwareModelParsing.string(json['Bus Type']),
      deviceID: HardwareModelParsing.string(json['Device ID']),
      deviceDesc: HardwareModelParsing.string(json['DeviceDesc']),
      acpiPath: HardwareModelParsing.string(json['ACPI Path']),
      pciPath: HardwareModelParsing.string(json['PCI Path']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Bus Type': busType,
      'Device ID': deviceID,
      'DeviceDesc': deviceDesc,
      'ACPI Path': acpiPath,
      'PCI Path': pciPath,
    };
  }
}

/// 蓝牙设备列表
class BluetoothDevicesInfo {
  Map<String, BluetoothDevice>? bluetoothDevices;

  BluetoothDevicesInfo({this.bluetoothDevices});

  factory BluetoothDevicesInfo.fromJson(Object? json) => BluetoothDevicesInfo(
        bluetoothDevices: HardwareModelParsing.objectMap(
          json,
          BluetoothDevice.fromJson,
        ),
      );

  Map<String, dynamic> toJson() =>
      bluetoothDevices?.map((key, value) => MapEntry(key, value.toJson())) ??
      {};
}
