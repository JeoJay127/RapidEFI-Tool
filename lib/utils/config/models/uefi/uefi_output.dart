class UefiOutput {
  bool clearScreenOnModeSwitch;
  String consoleFont;
  String consoleMode;
  bool directGopRendering;
  bool forceResolution;
  bool gopBurstMode;
  String gopPassThrough;
  bool ignoreTextInGraphics;
  String initialMode;
  bool provideConsoleGop;
  bool reconnectGraphicsOnConnect;
  bool reconnectOnResChange;
  bool replaceTabWithSpace;
  String resolution;
  bool sanitiseClearScreen;
  String textRenderer;
  bool ugaPassThrough;
  int uIScale;

  UefiOutput({
    this.clearScreenOnModeSwitch = false,
    this.consoleFont = '',
    this.consoleMode = '',
    this.directGopRendering = false,
    this.forceResolution = false,
    this.gopBurstMode = false,
    this.gopPassThrough = 'Disabled',
    this.ignoreTextInGraphics = false,
    this.initialMode = 'Auto',
    this.provideConsoleGop = true,
    this.reconnectGraphicsOnConnect = false,
    this.reconnectOnResChange = false,
    this.replaceTabWithSpace = false,
    this.resolution = 'Max',
    this.sanitiseClearScreen = false,
    this.textRenderer = 'BuiltinGraphics',
    this.ugaPassThrough = false,
    this.uIScale = 0,
  });
  UefiOutput copyWith({
    bool? clearScreenOnModeSwitch,
    String? consoleFont,
    String? consoleMode,
    bool? directGopRendering,
    bool? forceResolution,
    bool? gopBurstMode,
    String? gopPassThrough,
    bool? ignoreTextInGraphics,
    String? initialMode,
    bool? provideConsoleGop,
    bool? reconnectGraphicsOnConnect,
    bool? reconnectOnResChange,
    bool? replaceTabWithSpace,
    String? resolution,
    bool? sanitiseClearScreen,
    String? textRenderer,
    bool? ugaPassThrough,
    int? uIScale,
  }) {
    return UefiOutput(
      clearScreenOnModeSwitch:
          clearScreenOnModeSwitch ?? this.clearScreenOnModeSwitch,
      consoleFont: consoleFont ?? this.consoleFont,
      consoleMode: consoleMode ?? this.consoleMode,
      directGopRendering: directGopRendering ?? this.directGopRendering,
      forceResolution: forceResolution ?? this.forceResolution,
      gopBurstMode: gopBurstMode ?? this.gopBurstMode,
      gopPassThrough: gopPassThrough ?? this.gopPassThrough,
      ignoreTextInGraphics: ignoreTextInGraphics ?? this.ignoreTextInGraphics,
      initialMode: initialMode ?? this.initialMode,
      provideConsoleGop: provideConsoleGop ?? this.provideConsoleGop,
      reconnectGraphicsOnConnect:
          reconnectGraphicsOnConnect ?? this.reconnectGraphicsOnConnect,
      reconnectOnResChange: reconnectOnResChange ?? this.reconnectOnResChange,
      replaceTabWithSpace: replaceTabWithSpace ?? this.replaceTabWithSpace,
      resolution: resolution ?? this.resolution,
      sanitiseClearScreen: sanitiseClearScreen ?? this.sanitiseClearScreen,
      textRenderer: textRenderer ?? this.textRenderer,
      ugaPassThrough: ugaPassThrough ?? this.ugaPassThrough,
      uIScale: uIScale ?? this.uIScale,
    );
  }

  factory UefiOutput.fromJson(Map<String, dynamic> json) {
    return UefiOutput(
      clearScreenOnModeSwitch:
          json['ClearScreenOnModeSwitch'] as bool? ?? false,
      consoleFont: json['ConsoleFont'] as String? ?? '',
      consoleMode: json['ConsoleMode'] as String? ?? '',
      directGopRendering: json['DirectGopRendering'] as bool? ?? false,
      forceResolution: json['ForceResolution'] as bool? ?? false,
      gopBurstMode: json['GopBurstMode'] as bool? ?? false,
      gopPassThrough: json['GopPassThrough'] as String? ?? 'Disabled',
      ignoreTextInGraphics: json['IgnoreTextInGraphics'] as bool? ?? false,
      initialMode: json['InitialMode'] as String? ?? 'Auto',
      provideConsoleGop: json['ProvideConsoleGop'] as bool? ?? true,
      reconnectGraphicsOnConnect:
          json['ReconnectGraphicsOnConnect'] as bool? ?? false,
      reconnectOnResChange: json['ReconnectOnResChange'] as bool? ?? false,
      replaceTabWithSpace: json['ReplaceTabWithSpace'] as bool? ?? false,
      resolution: json['Resolution'] as String? ?? 'Max',
      sanitiseClearScreen: json['SanitiseClearScreen'] as bool? ?? false,
      textRenderer: json['TextRenderer'] as String? ?? 'BuiltinGraphics',
      ugaPassThrough: json['UgaPassThrough'] as bool? ?? false,
      uIScale: json['UIScale'] as int? ?? 0,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'ClearScreenOnModeSwitch': clearScreenOnModeSwitch,
      'ConsoleFont': consoleFont,
      'ConsoleMode': consoleMode,
      'DirectGopRendering': directGopRendering,
      'ForceResolution': forceResolution,
      'GopBurstMode': gopBurstMode,
      'GopPassThrough': gopPassThrough,
      'IgnoreTextInGraphics': ignoreTextInGraphics,
      'InitialMode': initialMode,
      'ProvideConsoleGop': provideConsoleGop,
      'ReconnectGraphicsOnConnect': reconnectGraphicsOnConnect,
      'ReconnectOnResChange': reconnectOnResChange,
      'ReplaceTabWithSpace': replaceTabWithSpace,
      'Resolution': resolution,
      'SanitiseClearScreen': sanitiseClearScreen,
      'TextRenderer': textRenderer,
      'UgaPassThrough': ugaPassThrough,
      'UIScale': uIScale,
    };
  }
}
