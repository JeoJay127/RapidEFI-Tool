class UefiAppleInput {
  String appleEvent;
  bool customDelays;
  bool graphicsInputMirroring;
  int keyInitialDelay;
  int keySubsequentDelay;
  int pointerDwellClickTimeout;
  int pointerDwellDoubleClickTimeout;
  int pointerDwellRadius;
  int pointerPollMask;
  int pointerPollMax;
  int pointerPollMin;
  int pointerSpeedDiv;
  int pointerSpeedMul;

  UefiAppleInput({
    this.appleEvent = 'Builtin',
    this.customDelays = false,
    this.graphicsInputMirroring = true,
    this.keyInitialDelay = 50,
    this.keySubsequentDelay = 5,
    this.pointerDwellClickTimeout = 0,
    this.pointerDwellDoubleClickTimeout = 0,
    this.pointerDwellRadius = 0,
    this.pointerPollMask = -1,
    this.pointerPollMax = 80,
    this.pointerPollMin = 10,
    this.pointerSpeedDiv = 1,
    this.pointerSpeedMul = 1,
  });
  UefiAppleInput copyWith({
    String? appleEvent,
    bool? customDelays,
    bool? graphicsInputMirroring,
    int? keyInitialDelay,
    int? keySubsequentDelay,
    int? pointerDwellClickTimeout,
    int? pointerDwellDoubleClickTimeout,
    int? pointerDwellRadius,
    int? pointerPollMask,
    int? pointerPollMax,
    int? pointerPollMin,
    int? pointerSpeedDiv,
    int? pointerSpeedMul,
  }) {
    return UefiAppleInput(
      appleEvent: appleEvent ?? this.appleEvent,
      customDelays: customDelays ?? this.customDelays,
      graphicsInputMirroring:
          graphicsInputMirroring ?? this.graphicsInputMirroring,
      keyInitialDelay: keyInitialDelay ?? this.keyInitialDelay,
      keySubsequentDelay: keySubsequentDelay ?? this.keySubsequentDelay,
      pointerDwellClickTimeout:
          pointerDwellClickTimeout ?? this.pointerDwellClickTimeout,
      pointerDwellDoubleClickTimeout:
          pointerDwellDoubleClickTimeout ?? this.pointerDwellDoubleClickTimeout,
      pointerDwellRadius: pointerDwellRadius ?? this.pointerDwellRadius,
      pointerPollMask: pointerPollMask ?? this.pointerPollMask,
      pointerPollMax: pointerPollMax ?? this.pointerPollMax,
      pointerPollMin: pointerPollMin ?? this.pointerPollMin,
      pointerSpeedDiv: pointerSpeedDiv ?? this.pointerSpeedDiv,
      pointerSpeedMul: pointerSpeedMul ?? this.pointerSpeedMul,
    );
  }

  factory UefiAppleInput.fromJson(Map<String, dynamic> json) {
    return UefiAppleInput(
      appleEvent: json['AppleEvent'] as String? ?? 'Builtin',
      customDelays: json['CustomDelays'] as bool? ?? false,
      graphicsInputMirroring: json['GraphicsInputMirroring'] as bool? ?? true,
      keyInitialDelay: json['KeyInitialDelay'] as int? ?? 50,
      keySubsequentDelay: json['KeySubsequentDelay'] as int? ?? 5,
      pointerDwellClickTimeout: json['PointerDwellClickTimeout'] as int? ?? 0,
      pointerDwellDoubleClickTimeout:
          json['PointerDwellDoubleClickTimeout'] as int? ?? 0,
      pointerDwellRadius: json['PointerDwellRadius'] as int? ?? 0,
      pointerPollMask: json['PointerPollMask'] as int? ?? -1,
      pointerPollMax: json['PointerPollMax'] as int? ?? 80,
      pointerPollMin: json['PointerPollMin'] as int? ?? 10,
      pointerSpeedDiv: json['PointerSpeedDiv'] as int? ?? 1,
      pointerSpeedMul: json['PointerSpeedMul'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'AppleEvent': appleEvent,
      'CustomDelays': customDelays,
      'GraphicsInputMirroring': graphicsInputMirroring,
      'KeyInitialDelay': keyInitialDelay,
      'KeySubsequentDelay': keySubsequentDelay,
      'PointerDwellClickTimeout': pointerDwellClickTimeout,
      'PointerDwellDoubleClickTimeout': pointerDwellDoubleClickTimeout,
      'PointerDwellRadius': pointerDwellRadius,
      'PointerPollMask': pointerPollMask,
      'PointerPollMax': pointerPollMax,
      'PointerPollMin': pointerPollMin,
      'PointerSpeedDiv': pointerSpeedDiv,
      'PointerSpeedMul': pointerSpeedMul,
    };
  }
}
