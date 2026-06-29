class UefiApfs {
  bool enableJumpstart;
  bool globalConnect;
  bool hideVerbose;
  bool jumpstartHotPlug;
  int minDate;
  int minVersion;

  UefiApfs({
    this.enableJumpstart = true,
    this.globalConnect = false,
    this.hideVerbose = true,
    this.jumpstartHotPlug = false,
    this.minDate = 0,
    this.minVersion = 0,
  });

  UefiApfs copyWith({
    bool? enableJumpstart,
    bool? globalConnect,
    bool? hideVerbose,
    bool? jumpstartHotPlug,
    int? minDate,
    int? minVersion,
  }) {
    return UefiApfs(
      enableJumpstart: enableJumpstart ?? this.enableJumpstart,
      globalConnect: globalConnect ?? this.globalConnect,
      hideVerbose: hideVerbose ?? this.hideVerbose,
      jumpstartHotPlug: jumpstartHotPlug ?? this.jumpstartHotPlug,
      minDate: minDate ?? this.minDate,
      minVersion: minVersion ?? this.minVersion,
    );
  }

  factory UefiApfs.fromJson(Map<String, dynamic> json) {
    return UefiApfs(
      enableJumpstart: json['EnableJumpstart'] as bool? ?? true,
      globalConnect: json['GlobalConnect'] as bool? ?? false,
      hideVerbose: json['HideVerbose'] as bool? ?? true,
      jumpstartHotPlug: json['JumpstartHotPlug'] as bool? ?? false,
      minDate: json['MinDate'] as int? ?? 0,
      minVersion: json['MinVersion'] as int? ?? 0,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'EnableJumpstart': enableJumpstart,
      'GlobalConnect': globalConnect,
      'HideVerbose': hideVerbose,
      'JumpstartHotPlug': jumpstartHotPlug,
      'MinDate': minDate,
      'MinVersion': minVersion,
    };
  }
}
