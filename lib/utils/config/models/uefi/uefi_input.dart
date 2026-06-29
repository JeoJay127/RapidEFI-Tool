class UefiInput {
  bool keyFiltering;
  int keyForgetThreshold;
  bool keySupport;
  String keySupportMode;
  bool keySwap;
  bool pointerSupport;
  String pointerSupportMode;
  int timerResolution;

  UefiInput({
    this.keyFiltering = false,
    this.keyForgetThreshold = 5,
    this.keySupport = true,
    this.keySupportMode = 'Auto',
    this.keySwap = false,
    this.pointerSupport = false,
    this.pointerSupportMode = 'ASUS',
    this.timerResolution = 50000,
  });
  UefiInput copyWith({
    bool? keyFiltering,
    int? keyForgetThreshold,
    bool? keySupport,
    String? keySupportMode,
    bool? keySwap,
    bool? pointerSupport,
    String? pointerSupportMode,
    int? timerResolution,
  }) {
    return UefiInput(
      keyFiltering: keyFiltering ?? this.keyFiltering,
      keyForgetThreshold: keyForgetThreshold ?? this.keyForgetThreshold,
      keySupport: keySupport ?? this.keySupport,
      keySupportMode: keySupportMode ?? this.keySupportMode,
      keySwap: keySwap ?? this.keySwap,
      pointerSupport: pointerSupport ?? this.pointerSupport,
      pointerSupportMode: pointerSupportMode ?? this.pointerSupportMode,
      timerResolution: timerResolution ?? this.timerResolution,
    );
  }

  factory UefiInput.fromJson(Map<String, dynamic> json) {
    return UefiInput(
      keyFiltering: json['KeyFiltering'] as bool? ?? false,
      keyForgetThreshold: json['KeyForgetThreshold'] as int? ?? 5,
      keySupport: json['KeySupport'] as bool? ?? true,
      keySupportMode: json['KeySupportMode'] as String? ?? 'Auto',
      keySwap: json['KeySwap'] as bool? ?? false,
      pointerSupport: json['PointerSupport'] as bool? ?? false,
      pointerSupportMode: json['PointerSupportMode'] as String? ?? 'ASUS',
      timerResolution: json['TimerResolution'] as int? ?? 50000,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'KeyFiltering': keyFiltering,
      'KeyForgetThreshold': keyForgetThreshold,
      'KeySupport': keySupport,
      'KeySupportMode': keySupportMode,
      'KeySwap': keySwap,
      'PointerSupport': pointerSupport,
      'PointerSupportMode': pointerSupportMode,
      'TimerResolution': timerResolution,
    };
  }
}
