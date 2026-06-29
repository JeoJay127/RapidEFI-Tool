class UefiQuirks {
  bool activateHpetSupport;
  bool disableSecurityPolicy;
  bool enableVectorAcceleration;
  bool enableVmx;
  int exitBootServicesDelay;
  bool forceOcWriteFlash;
  bool forgeUefiSupport;
  bool ignoreInvalidFlexRatio;
  bool releaseUsbOwnership;
  bool reloadOptionRoms;
  bool requestBootVarRouting;
  int resizeGpuBars;
  bool resizeUsePciRbIo;
  bool shimRetainProtocol;
  int tscSyncTimeout;
  bool unblockFsConnect;

  UefiQuirks({
    this.activateHpetSupport = false,
    this.disableSecurityPolicy = false,
    this.enableVectorAcceleration = true,
    this.enableVmx = false,
    this.exitBootServicesDelay = 0,
    this.forceOcWriteFlash = false,
    this.forgeUefiSupport = false,
    this.ignoreInvalidFlexRatio = false,
    this.releaseUsbOwnership = true,
    this.reloadOptionRoms = false,
    this.requestBootVarRouting = true,
    this.resizeGpuBars = -1,
    this.resizeUsePciRbIo = false,
    this.shimRetainProtocol = false,
    this.tscSyncTimeout = 0,
    this.unblockFsConnect = false,
  });

  UefiQuirks copyWith({
    bool? activateHpetSupport,
    bool? disableSecurityPolicy,
    bool? enableVectorAcceleration,
    bool? enableVmx,
    int? exitBootServicesDelay,
    bool? forceOcWriteFlash,
    bool? forgeUefiSupport,
    bool? ignoreInvalidFlexRatio,
    bool? releaseUsbOwnership,
    bool? reloadOptionRoms,
    bool? requestBootVarRouting,
    int? resizeGpuBars,
    bool? resizeUsePciRbIo,
    bool? shimRetainProtocol,
    int? tscSyncTimeout,
    bool? unblockFsConnect,
  }) {
    return UefiQuirks(
      activateHpetSupport: activateHpetSupport ?? this.activateHpetSupport,
      disableSecurityPolicy:
          disableSecurityPolicy ?? this.disableSecurityPolicy,
      enableVectorAcceleration:
          enableVectorAcceleration ?? this.enableVectorAcceleration,
      enableVmx: enableVmx ?? this.enableVmx,
      exitBootServicesDelay:
          exitBootServicesDelay ?? this.exitBootServicesDelay,
      forceOcWriteFlash: forceOcWriteFlash ?? this.forceOcWriteFlash,
      forgeUefiSupport: forgeUefiSupport ?? this.forgeUefiSupport,
      ignoreInvalidFlexRatio:
          ignoreInvalidFlexRatio ?? this.ignoreInvalidFlexRatio,
      releaseUsbOwnership: releaseUsbOwnership ?? this.releaseUsbOwnership,
      reloadOptionRoms: reloadOptionRoms ?? this.reloadOptionRoms,
      requestBootVarRouting:
          requestBootVarRouting ?? this.requestBootVarRouting,
      resizeGpuBars: resizeGpuBars ?? this.resizeGpuBars,
      resizeUsePciRbIo: resizeUsePciRbIo ?? this.resizeUsePciRbIo,
      shimRetainProtocol: shimRetainProtocol ?? this.shimRetainProtocol,
      tscSyncTimeout: tscSyncTimeout ?? this.tscSyncTimeout,
      unblockFsConnect: unblockFsConnect ?? this.unblockFsConnect,
    );
  }

  factory UefiQuirks.fromJson(Map<String, dynamic> json) {
    return UefiQuirks(
      activateHpetSupport: json['ActivateHpetSupport'] as bool? ?? false,
      disableSecurityPolicy: json['DisableSecurityPolicy'] as bool? ?? false,
      enableVectorAcceleration:
          json['EnableVectorAcceleration'] as bool? ?? false,
      enableVmx: json['EnableVmx'] as bool? ?? false,
      exitBootServicesDelay: json['ExitBootServicesDelay'] as int? ?? 0,
      forceOcWriteFlash: json['ForceOcWriteFlash'] as bool? ?? false,
      forgeUefiSupport: json['ForgeUefiSupport'] as bool? ?? false,
      ignoreInvalidFlexRatio: json['IgnoreInvalidFlexRatio'] as bool? ?? false,
      releaseUsbOwnership: json['ReleaseUsbOwnership'] as bool? ?? true,
      reloadOptionRoms: json['ReloadOptionRoms'] as bool? ?? false,
      requestBootVarRouting: json['RequestBootVarRouting'] as bool? ?? true,
      resizeGpuBars: json['ResizeGpuBars'] as int? ?? -1,
      resizeUsePciRbIo: json['ResizeUsePciRbIo'] as bool? ?? false,
      shimRetainProtocol: json['ShimRetainProtocol'] as bool? ?? false,
      tscSyncTimeout: json['TscSyncTimeout'] as int? ?? 0,
      unblockFsConnect: json['UnblockFsConnect'] as bool? ?? false,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'ActivateHpetSupport': activateHpetSupport,
      'DisableSecurityPolicy': disableSecurityPolicy,
      'EnableVectorAcceleration': enableVectorAcceleration,
      'EnableVmx': enableVmx,
      'ExitBootServicesDelay': exitBootServicesDelay,
      'ForceOcWriteFlash': forceOcWriteFlash,
      'ForgeUefiSupport': forgeUefiSupport,
      'IgnoreInvalidFlexRatio': ignoreInvalidFlexRatio,
      'ReleaseUsbOwnership': releaseUsbOwnership,
      'ReloadOptionRoms': reloadOptionRoms,
      'RequestBootVarRouting': requestBootVarRouting,
      'ResizeGpuBars': resizeGpuBars,
      'ResizeUsePciRbIo': resizeUsePciRbIo,
      'ShimRetainProtocol': shimRetainProtocol,
      'TscSyncTimeout': tscSyncTimeout,
      'UnblockFsConnect': unblockFsConnect,
    };
  }

}
