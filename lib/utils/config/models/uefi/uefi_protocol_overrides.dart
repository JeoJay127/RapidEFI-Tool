class UefiProtocolOverrides {
  bool appleAudio;
  bool appleBootPolicy;
  bool appleDebugLog;
  bool appleEg2Info;
  bool appleFramebufferInfo;
  bool appleImageConversion;
  bool appleImg4Verification;
  bool appleKeyMap;
  bool appleRtcRam;
  bool appleSecureBoot;
  bool appleSmcIo;
  bool appleUserInterfaceTheme;
  bool dataHub;
  bool deviceProperties;
  bool firmwareVolume;
  bool hashServices;
  bool osInfo;
  bool pciIo;
  bool unicodeCollation;

  UefiProtocolOverrides({
    this.appleAudio = false,
    this.appleBootPolicy = false,
    this.appleDebugLog = false,
    this.appleEg2Info = false,
    this.appleFramebufferInfo = false,
    this.appleImageConversion = false,
    this.appleImg4Verification = false,
    this.appleKeyMap = false,
    this.appleRtcRam = false,
    this.appleSecureBoot = false,
    this.appleSmcIo = false,
    this.appleUserInterfaceTheme = false,
    this.dataHub = false,
    this.deviceProperties = false,
    this.firmwareVolume = true,
    this.hashServices = false,
    this.osInfo = false,
    this.pciIo = false,
    this.unicodeCollation = false,
  });
  UefiProtocolOverrides copyWith({
    bool? appleAudio,
    bool? appleBootPolicy,
    bool? appleDebugLog,
    bool? appleEg2Info,
    bool? appleFramebufferInfo,
    bool? appleImageConversion,
    bool? appleImg4Verification,
    bool? appleKeyMap,
    bool? appleRtcRam,
    bool? appleSecureBoot,
    bool? appleSmcIo,
    bool? appleUserInterfaceTheme,
    bool? dataHub,
    bool? deviceProperties,
    bool? firmwareVolume,
    bool? hashServices,
    bool? osInfo,
    bool? pciIo,
    bool? unicodeCollation,
  }) {
    return UefiProtocolOverrides(
      appleAudio: appleAudio ?? this.appleAudio,
      appleBootPolicy: appleBootPolicy ?? this.appleBootPolicy,
      appleDebugLog: appleDebugLog ?? this.appleDebugLog,
      appleEg2Info: appleEg2Info ?? this.appleEg2Info,
      appleFramebufferInfo: appleFramebufferInfo ?? this.appleFramebufferInfo,
      appleImageConversion: appleImageConversion ?? this.appleImageConversion,
      appleImg4Verification:
          appleImg4Verification ?? this.appleImg4Verification,
      appleKeyMap: appleKeyMap ?? this.appleKeyMap,
      appleRtcRam: appleRtcRam ?? this.appleRtcRam,
      appleSecureBoot: appleSecureBoot ?? this.appleSecureBoot,
      appleSmcIo: appleSmcIo ?? this.appleSmcIo,
      appleUserInterfaceTheme:
          appleUserInterfaceTheme ?? this.appleUserInterfaceTheme,
      dataHub: dataHub ?? this.dataHub,
      deviceProperties: deviceProperties ?? this.deviceProperties,
      firmwareVolume: firmwareVolume ?? this.firmwareVolume,
      hashServices: hashServices ?? this.hashServices,
      osInfo: osInfo ?? this.osInfo,
      pciIo: pciIo ?? this.pciIo,
      unicodeCollation: unicodeCollation ?? this.unicodeCollation,
    );
  }

  factory UefiProtocolOverrides.fromJson(Map<String, dynamic> json) {
    return UefiProtocolOverrides(
      appleAudio: json['AppleAudio'] as bool? ?? false,
      appleBootPolicy: json['AppleBootPolicy'] as bool? ?? false,
      appleDebugLog: json['AppleDebugLog'] as bool? ?? false,
      appleEg2Info: json['AppleEg2Info'] as bool? ?? false,
      appleFramebufferInfo: json['AppleFramebufferInfo'] as bool? ?? false,
      appleImageConversion: json['AppleImageConversion'] as bool? ?? false,
      appleImg4Verification: json['AppleImg4Verification'] as bool? ?? false,
      appleKeyMap: json['AppleKeyMap'] as bool? ?? false,
      appleRtcRam: json['AppleRtcRam'] as bool? ?? false,
      appleSecureBoot: json['AppleSecureBoot'] as bool? ?? false,
      appleSmcIo: json['AppleSmcIo'] as bool? ?? false,
      appleUserInterfaceTheme:
          json['AppleUserInterfaceTheme'] as bool? ?? false,
      dataHub: json['DataHub'] as bool? ?? false,
      deviceProperties: json['DeviceProperties'] as bool? ?? false,
      firmwareVolume: json['FirmwareVolume'] as bool? ?? true,
      hashServices: json['HashServices'] as bool? ?? false,
      osInfo: json['OSInfo'] as bool? ?? false,
      pciIo: json['PciIo'] as bool? ?? false,
      unicodeCollation: json['UnicodeCollation'] as bool? ?? false,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'AppleAudio': appleAudio,
      'AppleBootPolicy': appleBootPolicy,
      'AppleDebugLog': appleDebugLog,
      'AppleEg2Info': appleEg2Info,
      'AppleFramebufferInfo': appleFramebufferInfo,
      'AppleImageConversion': appleImageConversion,
      'AppleImg4Verification': appleImg4Verification,
      'AppleKeyMap': appleKeyMap,
      'AppleRtcRam': appleRtcRam,
      'AppleSecureBoot': appleSecureBoot,
      'AppleSmcIo': appleSmcIo,
      'AppleUserInterfaceTheme': appleUserInterfaceTheme,
      'DataHub': dataHub,
      'DeviceProperties': deviceProperties,
      'FirmwareVolume': firmwareVolume,
      'HashServices': hashServices,
      'OSInfo': osInfo,
      'PciIo': pciIo,
      'UnicodeCollation': unicodeCollation,
    };
  }
}
