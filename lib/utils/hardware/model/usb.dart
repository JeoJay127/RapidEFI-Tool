import 'hardware_model_parsing.dart';

class USBController {
  String? busType;
  String? deviceID;
  String? subsystemID;
  String? acpiPath;
  String? pciPath;

  USBController({
    this.busType,
    this.deviceID,
    this.subsystemID,
    this.acpiPath,
    this.pciPath,
  });

  factory USBController.fromJson(Map<String, dynamic> json) {
    return USBController(
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

class USBControllersInfo {
  Map<String, USBController>? usbControllers;

  USBControllersInfo({this.usbControllers});

  factory USBControllersInfo.fromJson(Object? json) => USBControllersInfo(
        usbControllers: HardwareModelParsing.objectMap(
          json,
          USBController.fromJson,
        ),
      );

  Map<String, dynamic> toJson() =>
      usbControllers?.map((key, value) => MapEntry(key, value.toJson())) ?? {};
}
