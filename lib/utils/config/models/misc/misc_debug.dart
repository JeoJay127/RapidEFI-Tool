class MiscDebug {
  bool appleDebug;
  bool applePanic;
  bool disableWatchDog;
  int displayDelay;
  int displayLevel;
  String logModules;
  bool sysReport;
  int target;

  MiscDebug({
    this.appleDebug = false,
    this.applePanic = false,
    this.disableWatchDog = false,
    this.displayDelay = 0,
    this.displayLevel = 2147483650,
    this.logModules = '*',
    this.sysReport = false,
    this.target = 3,
  });
  MiscDebug copyWith({
    bool? appleDebug,
    bool? applePanic,
    bool? disableWatchDog,
    int? displayDelay,
    int? displayLevel,
    String? logModules,
    bool? sysReport,
    int? target,
  }) {
    return MiscDebug(
      appleDebug: appleDebug ?? this.appleDebug,
      applePanic: applePanic ?? this.applePanic,
      disableWatchDog: disableWatchDog ?? this.disableWatchDog,
      displayDelay: displayDelay ?? this.displayDelay,
      displayLevel: displayLevel ?? this.displayLevel,
      logModules: logModules ?? this.logModules,
      sysReport: sysReport ?? this.sysReport,
      target: target ?? this.target,
    );
  }

  factory MiscDebug.fromJson(Map<String, dynamic> json) {
    return MiscDebug(
      appleDebug: json['AppleDebug'] ?? false,
      applePanic: json['ApplePanic'] ?? false,
      disableWatchDog: json['DisableWatchDog'] ?? false,
      displayDelay: json['DisplayDelay'] ?? 0,
      displayLevel: json['DisplayLevel'] ?? 2147483650,
      logModules: json['LogModules'] ?? '*',
      sysReport: json['SysReport'] ?? false,
      target: json['Target'] ?? 3,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'AppleDebug': appleDebug,
      'ApplePanic': applePanic,
      'DisableWatchDog': disableWatchDog,
      'DisplayDelay': displayDelay,
      'DisplayLevel': displayLevel,
      'LogModules': logModules,
      'SysReport': sysReport,
      'Target': target,
    };
  }
}
