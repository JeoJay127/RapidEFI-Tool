import 'hardware_model_parsing.dart';

/// 内存信息
class MemoryModule {
  String? bankLabel;
  int? capacity;
  int? configuredClockSpeed;
  String? deviceLocator;
  String? manufacturer;
  int? memoryType;
  String? partNumber;
  String? serialNumber;
  int? smbiosMemoryType;
  int? speed;

  MemoryModule({
    this.bankLabel,
    this.capacity,
    this.configuredClockSpeed,
    this.deviceLocator,
    this.manufacturer,
    this.memoryType,
    this.partNumber,
    this.serialNumber,
    this.smbiosMemoryType,
    this.speed,
  });

  factory MemoryModule.fromJson(Map<String, dynamic> json) {
    return MemoryModule(
      bankLabel: HardwareModelParsing.string(json['BankLabel']),
      capacity: HardwareModelParsing.intValue(json['Capacity']),
      configuredClockSpeed: HardwareModelParsing.intValue(
        json['ConfiguredClockSpeed'],
      ),
      deviceLocator: HardwareModelParsing.string(json['DeviceLocator']),
      manufacturer: HardwareModelParsing.string(json['Manufacturer']),
      memoryType: HardwareModelParsing.intValue(json['MemoryType']),
      partNumber: HardwareModelParsing.string(json['PartNumber']),
      serialNumber: HardwareModelParsing.string(json['SerialNumber']),
      smbiosMemoryType: HardwareModelParsing.intValue(
        json['SMBIOSMemoryType'],
      ),
      speed: HardwareModelParsing.intValue(json['Speed']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'BankLabel': bankLabel,
      'Capacity': capacity,
      'ConfiguredClockSpeed': configuredClockSpeed,
      'DeviceLocator': deviceLocator,
      'Manufacturer': manufacturer,
      'MemoryType': memoryType,
      'PartNumber': partNumber,
      'SerialNumber': serialNumber,
      'SMBIOSMemoryType': smbiosMemoryType,
      'Speed': speed,
    };
  }
}

class MemoryModulesInfo {
  List<MemoryModule>? memoryModules;

  MemoryModulesInfo({this.memoryModules});

  factory MemoryModulesInfo.fromJson(Object? json) => MemoryModulesInfo(
        memoryModules: HardwareModelParsing.objectList(
          json,
          MemoryModule.fromJson,
        ),
      );
  List<dynamic> toJson() =>
      memoryModules?.map((e) => e.toJson()).toList() ?? [];
}
