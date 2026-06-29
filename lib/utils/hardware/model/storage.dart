import 'hardware_model_parsing.dart';

class StorageController {
  String? busType;
  String? deviceID;
  String? subsystemID;
  String? acpiPath;
  String? pciPath;

  StorageController({
    this.busType,
    this.deviceID,
    this.subsystemID,
    this.acpiPath,
    this.pciPath,
  });

  factory StorageController.fromJson(Map<String, dynamic> json) {
    return StorageController(
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

class StorageControllersInfo {
  Map<String, StorageController>? storageControllers;

  StorageControllersInfo({this.storageControllers});

  factory StorageControllersInfo.fromJson(Object? json) =>
      StorageControllersInfo(
        storageControllers: HardwareModelParsing.objectMap(
          json,
          StorageController.fromJson,
        ),
      );

  Map<String, dynamic> toJson() =>
      storageControllers?.map((key, value) => MapEntry(key, value.toJson())) ??
      {};
}
