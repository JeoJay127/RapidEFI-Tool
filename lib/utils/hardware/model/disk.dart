import 'hardware_model_parsing.dart';

class Disk {
  String? model;
  String? busType;
  String? mediaType;
  int? size;
  String? friendlyName;
  String? manufacturer;
  String? serialNumber;

  Disk({
    this.model,
    this.busType,
    this.mediaType,
    this.size,
    this.friendlyName,
    this.manufacturer,
    this.serialNumber,
  });

  factory Disk.fromJson(Map<String, dynamic> json) {
    return Disk(
      model: HardwareModelParsing.string(json['Model']),
      busType: HardwareModelParsing.string(json['BusType']),
      mediaType: HardwareModelParsing.string(json['MediaType']),
      size: HardwareModelParsing.intValue(json['Size']),
      friendlyName: HardwareModelParsing.string(json['FriendlyName']),
      manufacturer: HardwareModelParsing.string(json['Manufacturer']),
      serialNumber: HardwareModelParsing.string(json['SerialNumber']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Model': model,
      'BusType': busType,
      'MediaType': mediaType,
      'Size': size,
      'FriendlyName': friendlyName,
      'Manufacturer': manufacturer,
      'SerialNumber': serialNumber,
    };
  }
}

class DisksInfo {
  List<Disk>? disks;

  DisksInfo({this.disks});

  factory DisksInfo.fromJson(Object? json) => DisksInfo(
        disks: HardwareModelParsing.objectList(json, Disk.fromJson),
      );

  List<dynamic> toJson() => disks?.map((e) => e.toJson()).toList() ?? [];
}
