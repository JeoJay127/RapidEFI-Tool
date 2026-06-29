import 'hardware_model_parsing.dart';

class Bios {
  final String name;
  final String version;
  final String manufacturer;

  Bios({
    this.name = '',
    this.version = '',
    this.manufacturer = '',
  });

  factory Bios.fromJson(Map<String, dynamic> json) {
    return Bios(
      name: HardwareModelParsing.stringValue(json['Name']),
      version: HardwareModelParsing.stringValue(json['Version']),
      manufacturer: HardwareModelParsing.stringValue(json['Manufacturer']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Name': name,
      'Version': version,
      'Manufacturer': manufacturer,
    };
  }
}
