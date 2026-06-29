class KernelQuirks {
  bool appleCpuPmCfgLock;
  bool appleXcpmCfgLock;
  bool appleXcpmExtraMsrs;
  bool appleXcpmForceBoost;
  bool customSMBIOSGuid;
  bool customPciSerialDevice;
  bool disableIoMapper;
  bool disableIoMapperMapping;
  bool disableLinkeditJettison;
  bool disableRtcChecksum;
  bool extendBTFeatureFlags;
  bool externalDiskIcons;
  bool forceAquantiaEthernet;
  bool forceSecureBootScheme;
  bool increasePciBarSize;
  bool lapicKernelPanic;
  bool legacyCommpage;
  bool panicNoKextDump;
  bool powerTimeoutKernelPanic;
  bool provideCurrentCpuInfo;
  int setApfsTrimTimeout;
  bool thirdPartyDrives;
  bool xhciPortLimit;

  KernelQuirks({
    this.appleCpuPmCfgLock = false,
    this.appleXcpmCfgLock = false,
    this.appleXcpmExtraMsrs = false,
    this.appleXcpmForceBoost = false,
    this.customSMBIOSGuid = true,
    this.customPciSerialDevice = false,
    this.disableIoMapper = false,
    this.disableIoMapperMapping = false,
    this.disableLinkeditJettison = false,
    this.disableRtcChecksum = false,
    this.extendBTFeatureFlags = false,
    this.externalDiskIcons = false,
    this.forceAquantiaEthernet = false,
    this.forceSecureBootScheme = false,
    this.increasePciBarSize = false,
    this.lapicKernelPanic = false,
    this.legacyCommpage = false,
    this.panicNoKextDump = false,
    this.powerTimeoutKernelPanic = false,
    this.provideCurrentCpuInfo = false,
    this.setApfsTrimTimeout = -1,
    this.thirdPartyDrives = false,
    this.xhciPortLimit = false,
  });
  KernelQuirks copyWith({
    bool? appleCpuPmCfgLock,
    bool? appleXcpmCfgLock,
    bool? appleXcpmExtraMsrs,
    bool? appleXcpmForceBoost,
    bool? customSMBIOSGuid,
    bool? customPciSerialDevice,
    bool? disableIoMapper,
    bool? disableIoMapperMapping,
    bool? disableLinkeditJettison,
    bool? disableRtcChecksum,
    bool? extendBTFeatureFlags,
    bool? externalDiskIcons,
    bool? forceAquantiaEthernet,
    bool? forceSecureBootScheme,
    bool? increasePciBarSize,
    bool? lapicKernelPanic,
    bool? legacyCommpage,
    bool? panicNoKextDump,
    bool? powerTimeoutKernelPanic,
    bool? provideCurrentCpuInfo,
    int? setApfsTrimTimeout,
    bool? thirdPartyDrives,
    bool? xhciPortLimit,
  }) {
    return KernelQuirks(
      appleCpuPmCfgLock: appleCpuPmCfgLock ?? this.appleCpuPmCfgLock,
      appleXcpmCfgLock: appleXcpmCfgLock ?? this.appleXcpmCfgLock,
      appleXcpmExtraMsrs: appleXcpmExtraMsrs ?? this.appleXcpmExtraMsrs,
      appleXcpmForceBoost: appleXcpmForceBoost ?? this.appleXcpmForceBoost,
      customSMBIOSGuid: customSMBIOSGuid ?? this.customSMBIOSGuid,
      customPciSerialDevice:
          customPciSerialDevice ?? this.customPciSerialDevice,
      disableIoMapper: disableIoMapper ?? this.disableIoMapper,
      disableIoMapperMapping:
          disableIoMapperMapping ?? this.disableIoMapperMapping,
      disableLinkeditJettison:
          disableLinkeditJettison ?? this.disableLinkeditJettison,
      disableRtcChecksum: disableRtcChecksum ?? this.disableRtcChecksum,
      extendBTFeatureFlags: extendBTFeatureFlags ?? this.extendBTFeatureFlags,
      externalDiskIcons: externalDiskIcons ?? this.externalDiskIcons,
      forceAquantiaEthernet:
          forceAquantiaEthernet ?? this.forceAquantiaEthernet,
      forceSecureBootScheme:
          forceSecureBootScheme ?? this.forceSecureBootScheme,
      increasePciBarSize: increasePciBarSize ?? this.increasePciBarSize,
      lapicKernelPanic: lapicKernelPanic ?? this.lapicKernelPanic,
      legacyCommpage: legacyCommpage ?? this.legacyCommpage,
      panicNoKextDump: panicNoKextDump ?? this.panicNoKextDump,
      powerTimeoutKernelPanic:
          powerTimeoutKernelPanic ?? this.powerTimeoutKernelPanic,
      provideCurrentCpuInfo:
          provideCurrentCpuInfo ?? this.provideCurrentCpuInfo,
      setApfsTrimTimeout: setApfsTrimTimeout ?? this.setApfsTrimTimeout,
      thirdPartyDrives: thirdPartyDrives ?? this.thirdPartyDrives,
      xhciPortLimit: xhciPortLimit ?? this.xhciPortLimit,
    );
  }

  factory KernelQuirks.fromJson(Map<String, dynamic> json) {
    return KernelQuirks(
      appleCpuPmCfgLock: json['AppleCpuPmCfgLock'] ?? false,
      appleXcpmCfgLock: json['AppleXcpmCfgLock'] ?? false,
      appleXcpmExtraMsrs: json['AppleXcpmExtraMsrs'] ?? false,
      appleXcpmForceBoost: json['AppleXcpmForceBoost'] ?? false,
      customSMBIOSGuid: json['CustomSMBIOSGuid'] ?? false,
      customPciSerialDevice: json['CustomPciSerialDevice'] ?? false,
      disableIoMapper: json['DisableIoMapper'] ?? false,
      disableIoMapperMapping: json['DisableIoMapperMapping'] ?? false,
      disableLinkeditJettison: json['DisableLinkeditJettison'] ?? false,
      disableRtcChecksum: json['DisableRtcChecksum'] ?? false,
      extendBTFeatureFlags: json['ExtendBTFeatureFlags'] ?? false,
      externalDiskIcons: json['ExternalDiskIcons'] ?? false,
      forceAquantiaEthernet: json['ForceAquantiaEthernet'] ?? false,
      forceSecureBootScheme: json['ForceSecureBootScheme'] ?? false,
      increasePciBarSize: json['IncreasePciBarSize'] ?? false,
      lapicKernelPanic: json['LapicKernelPanic'] ?? false,
      legacyCommpage: json['LegacyCommpage'] ?? false,
      panicNoKextDump: json['PanicNoKextDump'] ?? false,
      powerTimeoutKernelPanic: json['PowerTimeoutKernelPanic'] ?? false,
      provideCurrentCpuInfo: json['ProvideCurrentCpuInfo'] ?? false,
      setApfsTrimTimeout: json['SetApfsTrimTimeout'] ?? -1,
      thirdPartyDrives: json['ThirdPartyDrives'] ?? false,
      xhciPortLimit: json['XhciPortLimit'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'AppleCpuPmCfgLock': appleCpuPmCfgLock,
      'AppleXcpmCfgLock': appleXcpmCfgLock,
      'AppleXcpmExtraMsrs': appleXcpmExtraMsrs,
      'AppleXcpmForceBoost': appleXcpmForceBoost,
      'CustomSMBIOSGuid': customSMBIOSGuid,
      'CustomPciSerialDevice': customPciSerialDevice,
      'DisableIoMapper': disableIoMapper,
      'DisableIoMapperMapping': disableIoMapperMapping,
      'DisableLinkeditJettison': disableLinkeditJettison,
      'DisableRtcChecksum': disableRtcChecksum,
      'ExtendBTFeatureFlags': extendBTFeatureFlags,
      'ExternalDiskIcons': externalDiskIcons,
      'ForceAquantiaEthernet': forceAquantiaEthernet,
      'ForceSecureBootScheme': forceSecureBootScheme,
      'IncreasePciBarSize': increasePciBarSize,
      'LapicKernelPanic': lapicKernelPanic,
      'LegacyCommpage': legacyCommpage,
      'PanicNoKextDump': panicNoKextDump,
      'PowerTimeoutKernelPanic': powerTimeoutKernelPanic,
      'ProvideCurrentCpuInfo': provideCurrentCpuInfo,
      'SetApfsTrimTimeout': setApfsTrimTimeout,
      'ThirdPartyDrives': thirdPartyDrives,
      'XhciPortLimit': xhciPortLimit,
    };
  }

  Map<String, dynamic> toQuirksMap() {
    return {
      'AppleCpuPmCfgLock': appleCpuPmCfgLock,
      'AppleXcpmCfgLock': appleXcpmCfgLock,
      'AppleXcpmExtraMsrs': appleXcpmExtraMsrs,
      'AppleXcpmForceBoost': appleXcpmForceBoost,
      'CustomSMBIOSGuid': customSMBIOSGuid,
      'CustomPciSerialDevice': customPciSerialDevice,
      'DisableIoMapper': disableIoMapper,
      'DisableIoMapperMapping': disableIoMapperMapping,
      'DisableLinkeditJettison': disableLinkeditJettison,
      'DisableRtcChecksum': disableRtcChecksum,
      'ExtendBTFeatureFlags': extendBTFeatureFlags,
      'ExternalDiskIcons': externalDiskIcons,
      'ForceAquantiaEthernet': forceAquantiaEthernet,
      'ForceSecureBootScheme': forceSecureBootScheme,
      'IncreasePciBarSize': increasePciBarSize,
      'LapicKernelPanic': lapicKernelPanic,
      'LegacyCommpage': legacyCommpage,
      'PanicNoKextDump': panicNoKextDump,
      'PowerTimeoutKernelPanic': powerTimeoutKernelPanic,
      'ProvideCurrentCpuInfo': provideCurrentCpuInfo,
      'ThirdPartyDrives': thirdPartyDrives,
      'XhciPortLimit': xhciPortLimit,
      'SetApfsTrimTimeout': setApfsTrimTimeout,
    };
  }
}
