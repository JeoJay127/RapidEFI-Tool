import 'dart:typed_data';

class PlatformInfoGeneric {
  bool adviseFeatures;
  String mlb;
  bool maxBIOSVersion;
  int processorType;
  Uint8List? rom;
  bool spoofVendor;
  String systemMemoryStatus;
  String systemProductName;
  String systemSerialNumber;
  String systemUUID;
  String comment;
  String systemProductNameRelatedCPU;

  PlatformInfoGeneric(
      {this.adviseFeatures = false,
      this.mlb = '',
      this.maxBIOSVersion = false,
      this.processorType = 0,
      this.rom,
      this.spoofVendor = true,
      this.systemMemoryStatus = 'Auto',
      this.systemProductName = '',
      this.systemSerialNumber = '',
      this.systemUUID = '',
      this.comment = '',
      this.systemProductNameRelatedCPU = ''});

  PlatformInfoGeneric copyWith(
      {bool? adviseFeatures,
      String? mlb,
      bool? maxBIOSVersion,
      int? processorType,
      Uint8List? rom,
      bool? spoofVendor,
      String? systemMemoryStatus,
      String? systemProductName,
      String? systemSerialNumber,
      String? systemUUID,
      String? comment,
      String? systemProductNameRelatedCPU}) {
    return PlatformInfoGeneric(
        adviseFeatures: adviseFeatures ?? this.adviseFeatures,
        mlb: mlb ?? this.mlb,
        maxBIOSVersion: maxBIOSVersion ?? this.maxBIOSVersion,
        processorType: processorType ?? this.processorType,
        rom: rom == null
            ? (this.rom == null ? null : Uint8List.fromList(this.rom!))
            : Uint8List.fromList(rom),
        spoofVendor: spoofVendor ?? this.spoofVendor,
        systemMemoryStatus: systemMemoryStatus ?? this.systemMemoryStatus,
        systemProductName: systemProductName ?? this.systemProductName,
        systemSerialNumber: systemSerialNumber ?? this.systemSerialNumber,
        systemUUID: systemUUID ?? this.systemUUID,
        comment: comment ?? this.comment,
        systemProductNameRelatedCPU:
            systemProductNameRelatedCPU ?? this.systemProductNameRelatedCPU);
  }

  factory PlatformInfoGeneric.fromJson(Map<String, dynamic> json) {
    return PlatformInfoGeneric(
        adviseFeatures: json['AdviseFeatures'] ?? false,
        mlb: json['MLB'] ?? '',
        maxBIOSVersion: json['MaxBIOSVersion'] ?? false,
        processorType: json['ProcessorType'] ?? 0,
        rom: json['ROM'] != null
            ? Uint8List.fromList(List<int>.from(json['ROM']))
            : null,
        spoofVendor: json['SpoofVendor'] ?? true,
        systemMemoryStatus: json['SystemMemoryStatus'] ?? 'Auto',
        systemProductName: json['SystemProductName'] ?? '',
        systemSerialNumber: json['SystemSerialNumber'] ?? '',
        systemUUID: json['SystemUUID'] ?? '',
        comment: json['comment'] ?? '',
        systemProductNameRelatedCPU: json['systemProductNameRelatedCPU'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {
      'AdviseFeatures': adviseFeatures,
      'MLB': mlb,
      'MaxBIOSVersion': maxBIOSVersion,
      'ProcessorType': processorType,
      'ROM': rom,
      'SpoofVendor': spoofVendor,
      'SystemMemoryStatus': systemMemoryStatus,
      'SystemProductName': systemProductName,
      'SystemSerialNumber': systemSerialNumber,
      'SystemUUID': systemUUID,
    };
  }
}
