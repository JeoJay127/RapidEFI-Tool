import 'hardware_model_parsing.dart';

class GraphicsCard {
  String? deviceID;
  String? subsystemID;
  String? manufacturer;
  String? codename;
  String? deviceType;
  String? acpiPath;
  String? pciPath;

  GraphicsCard({
    this.deviceID,
    this.subsystemID,
    this.manufacturer,
    this.codename,
    this.deviceType,
    this.acpiPath,
    this.pciPath,
  });

  factory GraphicsCard.fromJson(Map<String, dynamic> json) {
    return GraphicsCard(
      deviceID: HardwareModelParsing.string(json['Device ID']),
      subsystemID: HardwareModelParsing.string(json['Subsystem ID']),
      manufacturer: HardwareModelParsing.string(json['Manufacturer']),
      codename: HardwareModelParsing.string(json['Codename']),
      deviceType: HardwareModelParsing.string(json['Device Type']),
      acpiPath: HardwareModelParsing.string(json['ACPI Path']),
      pciPath: HardwareModelParsing.string(json['PCI Path']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Device ID': deviceID,
      'Subsystem ID': subsystemID,
      'Manufacturer': manufacturer,
      'Codename': codename,
      'Device Type': deviceType,
      'ACPI Path': acpiPath,
      'PCI Path': pciPath,
    };
  }
}

class GraphicsCardInfo {
  Map<String, GraphicsCard>? graphicsCards;

  GraphicsCardInfo({this.graphicsCards});

  factory GraphicsCardInfo.fromJson(Object? json) => GraphicsCardInfo(
        graphicsCards: HardwareModelParsing.objectMap(
          json,
          GraphicsCard.fromJson,
        ),
      );

  Map<String, dynamic> toJson() =>
      graphicsCards?.map((key, value) => MapEntry(key, value.toJson())) ?? {};
}
