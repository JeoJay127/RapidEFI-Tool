import 'hardware_model_parsing.dart';

/// 网卡信息
class NetworkAdapter {
  String? busType;
  String? deviceID;
  String? subsystemID;
  String? acpiPath;
  String? pciPath;

  NetworkAdapter({
    this.busType,
    this.deviceID,
    this.subsystemID,
    this.acpiPath,
    this.pciPath,
  });

  factory NetworkAdapter.fromJson(Map<String, dynamic> json) {
    return NetworkAdapter(
      busType: HardwareModelParsing.string(json['Bus Type']),
      deviceID: HardwareModelParsing.string(json['Device ID']),
      subsystemID: HardwareModelParsing.string(json['Subsystem ID']),
      acpiPath: HardwareModelParsing.string(json['ACPI Path']),
      pciPath: HardwareModelParsing.string(json['PCI Path']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Bus Type': busType,
      'Device ID': deviceID,
      'Subsystem ID': subsystemID,
      'ACPI Path': acpiPath,
      'PCI Path': pciPath,
    };
  }
}

class NetworkAdaptersInfo {
  Map<String, NetworkAdapter>? networkAdapters;

  NetworkAdaptersInfo({this.networkAdapters});

  factory NetworkAdaptersInfo.fromJson(Object? json) => NetworkAdaptersInfo(
        networkAdapters: HardwareModelParsing.objectMap(
          json,
          NetworkAdapter.fromJson,
        ),
      );

  Map<String, dynamic> toJson() =>
      networkAdapters?.map((key, value) => MapEntry(key, value.toJson())) ?? {};
}
