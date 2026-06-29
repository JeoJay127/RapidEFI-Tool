import 'hardware_model_parsing.dart';

class CPU {
  String? manufacturer;
  String? name;
  int? numberOfCores;
  int? numberOfEnabledCore;
  int? numberOfLogicalProcessors;
  String? processorId;
  int? threadCount;
  int? family;
  String? description;
  String? caption;
  String? architecture;
  String? deviceId;
  int? processorType;
  String? socketDesignation;
  int? maxClockSpeed;
  bool virtualizationFirmwareEnabled;
  //扩展信息
  String? codename; // 代号
  String? simdFeatures; // 指令集
  // 构造函数
  CPU({
    this.manufacturer,
    this.name,
    this.numberOfCores,
    this.numberOfEnabledCore,
    this.numberOfLogicalProcessors,
    this.processorId,
    this.threadCount,
    this.family,
    this.description,
    this.caption,
    this.architecture,
    this.deviceId,
    this.processorType,
    this.socketDesignation,
    this.maxClockSpeed,
    this.virtualizationFirmwareEnabled = false,
    this.codename,
    this.simdFeatures,
  });

  factory CPU.fromJson(Map<String, dynamic> json) {
    return CPU(
      manufacturer: HardwareModelParsing.string(json['Manufacturer']),
      name: HardwareModelParsing.string(json['Name']),
      numberOfCores: HardwareModelParsing.intValue(json['NumberOfCores']),
      numberOfEnabledCore: HardwareModelParsing.intValue(
        json['NumberOfEnabledCore'],
      ),
      numberOfLogicalProcessors: HardwareModelParsing.intValue(
        json['NumberOfLogicalProcessors'],
      ),
      processorId: HardwareModelParsing.string(json['ProcessorId']),
      threadCount: HardwareModelParsing.intValue(json['ThreadCount']),
      family: HardwareModelParsing.intValue(json['Family']),
      description: HardwareModelParsing.string(json['Description']),
      caption: HardwareModelParsing.string(json['Caption']),
      architecture: HardwareModelParsing.string(json['Architecture']),
      deviceId: HardwareModelParsing.string(json['DeviceID']),
      processorType: HardwareModelParsing.intValue(json['ProcessorType']),
      socketDesignation: HardwareModelParsing.string(
        json['SocketDesignation'],
      ),
      maxClockSpeed: HardwareModelParsing.intValue(json['MaxClockSpeed']),
      virtualizationFirmwareEnabled: HardwareModelParsing.boolValue(
        json['VirtualizationFirmwareEnabled'],
      ),
      codename: HardwareModelParsing.string(json['Codename']),
      simdFeatures: HardwareModelParsing.string(json['SIMD Features']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Manufacturer': manufacturer,
      'Name': name,
      'NumberOfCores': numberOfCores,
      'NumberOfEnabledCore': numberOfEnabledCore,
      'NumberOfLogicalProcessors': numberOfLogicalProcessors,
      'ProcessorId': processorId,
      'ThreadCount': threadCount,
      'Family': family,
      'Description': description,
      'Caption': caption,
      'Architecture': architecture,
      'DeviceID': deviceId,
      'ProcessorType': processorType,
      'SocketDesignation': socketDesignation,
      'MaxClockSpeed': maxClockSpeed,
      'VirtualizationFirmwareEnabled': virtualizationFirmwareEnabled,
      'Codename': codename,
      'SIMD Features': simdFeatures,
    };
  }
}

class CPUs {
  List<CPU> cpuList = [];
  CPUs({required this.cpuList});

  factory CPUs.fromJson(Object? json) =>
      CPUs(cpuList: HardwareModelParsing.objectList(json, CPU.fromJson));
  List<dynamic> toJson() => cpuList.map((e) => e.toJson()).toList();
}
