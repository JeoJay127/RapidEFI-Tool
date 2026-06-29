import 'hardware_model_parsing.dart';

/// 主板信息
class MotherBoard {
  String? manufacturer;
  String? model;
  String? name;
  String? product;
  String? serialNumber;

  ///扩展信息
  String? chipset; // 芯片组
  String? deviceID;
  String? platform; // 平台

  MotherBoard({
    this.manufacturer,
    this.model,
    this.name,
    this.product,
    this.serialNumber,
    this.chipset,
    this.deviceID,
    this.platform,
  });

  factory MotherBoard.fromJson(Map<String, dynamic> json) {
    return MotherBoard(
      manufacturer: HardwareModelParsing.string(json['Manufacturer']),
      model: HardwareModelParsing.string(json['Model']),
      name: HardwareModelParsing.string(json['Name']),
      product: HardwareModelParsing.string(json['Product']),
      serialNumber: HardwareModelParsing.string(json['SerialNumber']),
      chipset: HardwareModelParsing.string(json['Chipset']),
      deviceID: HardwareModelParsing.string(json['Device ID']),
      platform: HardwareModelParsing.string(json['Platform']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Manufacturer': manufacturer,
      'Model': model,
      'Name': name,
      'Product': product,
      'SerialNumber': serialNumber,
      'Chipset': chipset,
      'Device ID': deviceID,
      'Platform': platform,
    };
  }
}
