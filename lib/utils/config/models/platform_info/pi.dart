import 'pi_generic.dart';

class PlatformInfo {
  bool automatic;
  bool customMemory;
  bool updateDataHub;
  bool updateNVRAM;
  bool updateSMBIOS;
  bool useRawUuidEncoding;
  String updateSMBIOSMode;
  PlatformInfoGeneric? generic;
  PlatformInfo(
      {this.automatic = true,
      this.customMemory = false,
      this.updateDataHub = true,
      this.updateNVRAM = true,
      this.updateSMBIOS = true,
      this.useRawUuidEncoding = false,
      this.updateSMBIOSMode = 'Create',
      this.generic});

  PlatformInfo copyWith({
    bool? automatic,
    bool? customMemory,
    bool? updateDataHub,
    bool? updateNVRAM,
    bool? updateSMBIOS,
    bool? useRawUuidEncoding,
    String? updateSMBIOSMode,
    PlatformInfoGeneric? generic,
  }) {
    return PlatformInfo(
      automatic: automatic ?? this.automatic,
      customMemory: customMemory ?? this.customMemory,
      updateDataHub: updateDataHub ?? this.updateDataHub,
      updateNVRAM: updateNVRAM ?? this.updateNVRAM,
      updateSMBIOS: updateSMBIOS ?? this.updateSMBIOS,
      useRawUuidEncoding: useRawUuidEncoding ?? this.useRawUuidEncoding,
      updateSMBIOSMode: updateSMBIOSMode ?? this.updateSMBIOSMode,
      generic: generic ?? this.generic?.copyWith(),
    );
  }

  factory PlatformInfo.fromJson(Map<String, dynamic> json) {
    return PlatformInfo(
      automatic: json['Automatic'] ?? true,
      customMemory: json['CustomMemory'] ?? false,
      updateDataHub: json['UpdateDataHub'] ?? true,
      updateNVRAM: json['UpdateNVRAM'] ?? true,
      updateSMBIOS: json['UpdateSMBIOS'] ?? true,
      useRawUuidEncoding: json['UseRawUuidEncoding'] ?? false,
      updateSMBIOSMode: json['UpdateSMBIOSMode'] ?? 'Create',
      generic: json['Generic'] != null
          ? PlatformInfoGeneric.fromJson(json['Generic'])
          : null,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'Automatic': automatic,
      'CustomMemory': customMemory,
      'UpdateDataHub': updateDataHub,
      'UpdateNVRAM': updateNVRAM,
      'UpdateSMBIOS': updateSMBIOS,
      'UseRawUuidEncoding': useRawUuidEncoding,
      'UpdateSMBIOSMode': updateSMBIOSMode,
      'Generic': generic?.toJson(),
    };
  }
}
