class AcpiQuirks {
  bool fadtEnableReset;
  bool normalizeHeaders;
  bool rebaseRegions;
  bool resetHwSig;
  bool resetLogoStatus;
  bool syncTableIds;

  AcpiQuirks({
    this.fadtEnableReset = false,
    this.normalizeHeaders = false,
    this.rebaseRegions = false,
    this.resetHwSig = false,
    this.resetLogoStatus = true,
    this.syncTableIds = false,
  });

  AcpiQuirks copyWith({
    bool? fadtEnableReset,
    bool? normalizeHeaders,
    bool? rebaseRegions,
    bool? resetHwSig,
    bool? resetLogoStatus,
    bool? syncTableIds,
  }) {
    return AcpiQuirks(
      fadtEnableReset: fadtEnableReset ?? this.fadtEnableReset,
      normalizeHeaders: normalizeHeaders ?? this.normalizeHeaders,
      rebaseRegions: rebaseRegions ?? this.rebaseRegions,
      resetHwSig: resetHwSig ?? this.resetHwSig,
      resetLogoStatus: resetLogoStatus ?? this.resetLogoStatus,
      syncTableIds: syncTableIds ?? this.syncTableIds,
    );
  }

  factory AcpiQuirks.fromJson(Map<String, dynamic> map) {
    return AcpiQuirks(
      fadtEnableReset: map['FadtEnableReset'] ?? false,
      normalizeHeaders: map['NormalizeHeaders'] ?? false,
      rebaseRegions: map['RebaseRegions'] ?? false,
      resetHwSig: map['ResetHwSig'] ?? false,
      resetLogoStatus: map['ResetLogoStatus'] ?? false,
      syncTableIds: map['SyncTableIds'] ?? false,
    );
  }

  Map<String, bool> toJson() {
    return {
      'FadtEnableReset': fadtEnableReset,
      'NormalizeHeaders': normalizeHeaders,
      'RebaseRegions': rebaseRegions,
      'ResetHwSig': resetHwSig,
      'ResetLogoStatus': resetLogoStatus,
      'SyncTableIds': syncTableIds,
    };
  }
}
