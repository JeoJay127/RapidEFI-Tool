class BooterQuirks {
  bool allowRelocationBlock;
  bool avoidRuntimeDefrag;
  bool clearTaskSwitchBit;
  bool devirtualiseMmio;
  bool disableSingleUser;
  bool disableVariableWrite;
  bool discardHibernateMap;
  bool enableSafeModeSlide;
  bool enableWriteUnprotector;
  bool fixupAppleEfiImages;
  bool forceBooterSignature;
  bool forceExitBootServices;
  bool protectMemoryRegions;
  bool protectSecureBoot;
  bool protectUefiServices;
  bool provideCustomSlide;
  int provideMaxSlide;
  bool rebuildAppleMemoryMap;
  int resizeAppleGpuBars;
  bool setupVirtualMap;
  bool signalAppleOS;
  bool syncRuntimePermissions;

  BooterQuirks({
    this.allowRelocationBlock = false,
    this.avoidRuntimeDefrag = false,
    this.clearTaskSwitchBit = false,
    this.devirtualiseMmio = false,
    this.disableSingleUser = false,
    this.disableVariableWrite = false,
    this.discardHibernateMap = false,
    this.enableSafeModeSlide = false,
    this.enableWriteUnprotector = false,
    this.fixupAppleEfiImages = false,
    this.forceBooterSignature = false,
    this.forceExitBootServices = false,
    this.protectMemoryRegions = false,
    this.protectSecureBoot = false,
    this.protectUefiServices = false,
    this.provideCustomSlide = false,
    this.provideMaxSlide = 0,
    this.rebuildAppleMemoryMap = false,
    this.resizeAppleGpuBars = -1,
    this.setupVirtualMap = false,
    this.signalAppleOS = false,
    this.syncRuntimePermissions = false,
  });

  BooterQuirks copyWith({
    bool? allowRelocationBlock,
    bool? avoidRuntimeDefrag,
    bool? clearTaskSwitchBit,
    bool? devirtualiseMmio,
    bool? disableSingleUser,
    bool? disableVariableWrite,
    bool? discardHibernateMap,
    bool? enableSafeModeSlide,
    bool? enableWriteUnprotector,
    bool? fixupAppleEfiImages,
    bool? forceBooterSignature,
    bool? forceExitBootServices,
    bool? protectMemoryRegions,
    bool? protectSecureBoot,
    bool? protectUefiServices,
    bool? provideCustomSlide,
    int? provideMaxSlide,
    bool? rebuildAppleMemoryMap,
    int? resizeAppleGpuBars,
    bool? setupVirtualMap,
    bool? signalAppleOS,
    bool? syncRuntimePermissions,
  }) {
    return BooterQuirks(
      allowRelocationBlock: allowRelocationBlock ?? this.allowRelocationBlock,
      avoidRuntimeDefrag: avoidRuntimeDefrag ?? this.avoidRuntimeDefrag,
      clearTaskSwitchBit: clearTaskSwitchBit ?? this.clearTaskSwitchBit,
      devirtualiseMmio: devirtualiseMmio ?? this.devirtualiseMmio,
      disableSingleUser: disableSingleUser ?? this.disableSingleUser,
      disableVariableWrite: disableVariableWrite ?? this.disableVariableWrite,
      discardHibernateMap: discardHibernateMap ?? this.discardHibernateMap,
      enableSafeModeSlide: enableSafeModeSlide ?? this.enableSafeModeSlide,
      enableWriteUnprotector:
          enableWriteUnprotector ?? this.enableWriteUnprotector,
      fixupAppleEfiImages: fixupAppleEfiImages ?? this.fixupAppleEfiImages,
      forceBooterSignature: forceBooterSignature ?? this.forceBooterSignature,
      forceExitBootServices:
          forceExitBootServices ?? this.forceExitBootServices,
      protectMemoryRegions: protectMemoryRegions ?? this.protectMemoryRegions,
      protectSecureBoot: protectSecureBoot ?? this.protectSecureBoot,
      protectUefiServices: protectUefiServices ?? this.protectUefiServices,
      provideCustomSlide: provideCustomSlide ?? this.provideCustomSlide,
      provideMaxSlide: provideMaxSlide ?? this.provideMaxSlide,
      rebuildAppleMemoryMap:
          rebuildAppleMemoryMap ?? this.rebuildAppleMemoryMap,
      resizeAppleGpuBars: resizeAppleGpuBars ?? this.resizeAppleGpuBars,
      setupVirtualMap: setupVirtualMap ?? this.setupVirtualMap,
      signalAppleOS: signalAppleOS ?? this.signalAppleOS,
      syncRuntimePermissions:
          syncRuntimePermissions ?? this.syncRuntimePermissions,
    );
  }

  factory BooterQuirks.fromJson(Map<String, dynamic> json) {
    return BooterQuirks(
      allowRelocationBlock: json['AllowRelocationBlock'] ?? false,
      avoidRuntimeDefrag: json['AvoidRuntimeDefrag'] ?? false,
      clearTaskSwitchBit: json['ClearTaskSwitchBit'] ?? false,
      devirtualiseMmio: json['DevirtualiseMmio'] ?? false,
      disableSingleUser: json['DisableSingleUser'] ?? false,
      disableVariableWrite: json['DisableVariableWrite'] ?? false,
      discardHibernateMap: json['DiscardHibernateMap'] ?? false,
      enableSafeModeSlide: json['EnableSafeModeSlide'] ?? false,
      enableWriteUnprotector: json['EnableWriteUnprotector'] ?? false,
      fixupAppleEfiImages: json['FixupAppleEfiImages'] ?? false,
      forceBooterSignature: json['ForceBooterSignature'] ?? false,
      forceExitBootServices: json['ForceExitBootServices'] ?? false,
      protectMemoryRegions: json['ProtectMemoryRegions'] ?? false,
      protectSecureBoot: json['ProtectSecureBoot'] ?? false,
      protectUefiServices: json['ProtectUefiServices'] ?? false,
      provideCustomSlide: json['ProvideCustomSlide'] ?? false,
      provideMaxSlide: json['ProvideMaxSlide'] ?? 0,
      rebuildAppleMemoryMap: json['RebuildAppleMemoryMap'] ?? false,
      resizeAppleGpuBars: json['ResizeAppleGpuBars'] ?? -1,
      setupVirtualMap: json['SetupVirtualMap'] ?? false,
      signalAppleOS: json['SignalAppleOS'] ?? false,
      syncRuntimePermissions: json['SyncRuntimePermissions'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'AllowRelocationBlock': allowRelocationBlock,
      'AvoidRuntimeDefrag': avoidRuntimeDefrag,
      'ClearTaskSwitchBit': clearTaskSwitchBit,
      'DevirtualiseMmio': devirtualiseMmio,
      'DisableSingleUser': disableSingleUser,
      'DisableVariableWrite': disableVariableWrite,
      'DiscardHibernateMap': discardHibernateMap,
      'EnableSafeModeSlide': enableSafeModeSlide,
      'EnableWriteUnprotector': enableWriteUnprotector,
      'FixupAppleEfiImages': fixupAppleEfiImages,
      'ForceBooterSignature': forceBooterSignature,
      'ForceExitBootServices': forceExitBootServices,
      'ProtectMemoryRegions': protectMemoryRegions,
      'ProtectSecureBoot': protectSecureBoot,
      'ProtectUefiServices': protectUefiServices,
      'ProvideCustomSlide': provideCustomSlide,
      'ProvideMaxSlide': provideMaxSlide,
      'RebuildAppleMemoryMap': rebuildAppleMemoryMap,
      'ResizeAppleGpuBars': resizeAppleGpuBars,
      'SetupVirtualMap': setupVirtualMap,
      'SignalAppleOS': signalAppleOS,
      'SyncRuntimePermissions': syncRuntimePermissions,
    };
  }

  Map<String, dynamic> toQuirksMap() {
    return {
      'AllowRelocationBlock': allowRelocationBlock,
      'AvoidRuntimeDefrag': avoidRuntimeDefrag,
      'ClearTaskSwitchBit': clearTaskSwitchBit,
      'DevirtualiseMmio': devirtualiseMmio,
      'DisableSingleUser': disableSingleUser,
      'DisableVariableWrite': disableVariableWrite,
      'DiscardHibernateMap': discardHibernateMap,
      'EnableSafeModeSlide': enableSafeModeSlide,
      'EnableWriteUnprotector': enableWriteUnprotector,
      'FixupAppleEfiImages': fixupAppleEfiImages,
      'ForceBooterSignature': forceBooterSignature,
      'ForceExitBootServices': forceExitBootServices,
      'ProtectMemoryRegions': protectMemoryRegions,
      'ProtectSecureBoot': protectSecureBoot,
      'ProtectUefiServices': protectUefiServices,
      'ProvideCustomSlide': provideCustomSlide,
      'RebuildAppleMemoryMap': rebuildAppleMemoryMap,
      'SetupVirtualMap': setupVirtualMap,
      'SignalAppleOS': signalAppleOS,
      'SyncRuntimePermissions': syncRuntimePermissions,
    };
  }

  Map<String, dynamic> toEBQuirksMap() {
    return {
      'DevirtualiseMmio': devirtualiseMmio,
      'EnableWriteUnprotector': enableWriteUnprotector,
      'ProtectUefiServices': protectUefiServices,
      'RebuildAppleMemoryMap': rebuildAppleMemoryMap,
      'SetupVirtualMap': setupVirtualMap,
      'SyncRuntimePermissions': syncRuntimePermissions,
    };
  }
}
