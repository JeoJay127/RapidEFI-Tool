class UefiAudio {
  int audioCodec;
  String audioDevice;
  int audioOutMask;
  bool audioSupport;
  bool disconnectHda;
  int maximumGain;
  int minimumAssistGain;
  int minimumAudibleGain;
  String playChime;
  bool resetTrafficClass;
  int setupDelay;

  UefiAudio({
    this.audioCodec = 0,
    this.audioDevice = 'PciRoot(0x0)/Pci(0x1b,0x0)',
    this.audioOutMask = 1,
    this.audioSupport = false,
    this.disconnectHda = false,
    this.maximumGain = -15,
    this.minimumAssistGain = -30,
    this.minimumAudibleGain = -55,
    this.playChime = 'Auto',
    this.resetTrafficClass = false,
    this.setupDelay = 0,
  });
  UefiAudio copyWith({
    int? audioCodec,
    String? audioDevice,
    int? audioOutMask,
    bool? audioSupport,
    bool? disconnectHda,
    int? maximumGain,
    int? minimumAssistGain,
    int? minimumAudibleGain,
    String? playChime,
    bool? resetTrafficClass,
    int? setupDelay,
  }) {
    return UefiAudio(
      audioCodec: audioCodec ?? this.audioCodec,
      audioDevice: audioDevice ?? this.audioDevice,
      audioOutMask: audioOutMask ?? this.audioOutMask,
      audioSupport: audioSupport ?? this.audioSupport,
      disconnectHda: disconnectHda ?? this.disconnectHda,
      maximumGain: maximumGain ?? this.maximumGain,
      minimumAssistGain: minimumAssistGain ?? this.minimumAssistGain,
      minimumAudibleGain: minimumAudibleGain ?? this.minimumAudibleGain,
      playChime: playChime ?? this.playChime,
      resetTrafficClass: resetTrafficClass ?? this.resetTrafficClass,
      setupDelay: setupDelay ?? this.setupDelay,
    );
  }

  factory UefiAudio.fromJson(Map<String, dynamic> json) {
    return UefiAudio(
      audioCodec: json['AudioCodec'] as int? ?? 0,
      audioDevice:
          json['AudioDevice'] as String? ?? 'PciRoot(0x0)/Pci(0x1b,0x0)',
      audioOutMask: json['AudioOutMask'] as int? ?? 1,
      audioSupport: json['AudioSupport'] as bool? ?? false,
      disconnectHda: json['DisconnectHda'] as bool? ?? false,
      maximumGain: json['MaximumGain'] as int? ?? -15,
      minimumAssistGain: json['MinimumAssistGain'] as int? ?? -30,
      minimumAudibleGain: json['MinimumAudibleGain'] as int? ?? -55,
      playChime: json['PlayChime'] as String? ?? 'Auto',
      resetTrafficClass: json['ResetTrafficClass'] as bool? ?? false,
      setupDelay: json['SetupDelay'] as int? ?? 0,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'AudioCodec': audioCodec,
      'AudioDevice': audioDevice,
      'AudioOutMask': audioOutMask,
      'AudioSupport': audioSupport,
      'DisconnectHda': disconnectHda,
      'MaximumGain': maximumGain,
      'MinimumAssistGain': minimumAssistGain,
      'MinimumAudibleGain': minimumAudibleGain,
      'PlayChime': playChime,
      'ResetTrafficClass': resetTrafficClass,
      'SetupDelay': setupDelay,
    };
  }
}
