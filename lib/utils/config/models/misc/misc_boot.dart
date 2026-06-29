class MiscBoot {
  int consoleAttributes;
  String hibernateMode;
  bool hibernateSkipsPicker;
  bool hideAuxiliary;
  String instanceIdentifier;
  String launcherOption;
  String launcherPath;
  int pickerAttributes;
  bool pickerAudioAssist;
  String pickerMode;
  String pickerVariant;
  bool pollAppleHotKeys;
  bool showPicker;
  int takeoffDelay;
  int timeout;

  MiscBoot({
    this.consoleAttributes = 0,
    this.hibernateMode = 'None',
    this.hibernateSkipsPicker = false,
    this.hideAuxiliary = false,
    this.instanceIdentifier = '',
    this.launcherOption = 'Disabled',
    this.launcherPath = 'Default',
    this.pickerAttributes = 17,
    this.pickerAudioAssist = false,
    this.pickerMode = 'Builtin',
    this.pickerVariant = 'Auto',
    this.pollAppleHotKeys = false,
    this.showPicker = false,
    this.takeoffDelay = 0,
    this.timeout = 5,
  });
  MiscBoot copyWith({
    int? consoleAttributes,
    String? hibernateMode,
    bool? hibernateSkipsPicker,
    bool? hideAuxiliary,
    String? instanceIdentifier,
    String? launcherOption,
    String? launcherPath,
    int? pickerAttributes,
    bool? pickerAudioAssist,
    String? pickerMode,
    String? pickerVariant,
    bool? pollAppleHotKeys,
    bool? showPicker,
    int? takeoffDelay,
    int? timeout,
  }) {
    return MiscBoot(
      consoleAttributes: consoleAttributes ?? this.consoleAttributes,
      hibernateMode: hibernateMode ?? this.hibernateMode,
      hibernateSkipsPicker: hibernateSkipsPicker ?? this.hibernateSkipsPicker,
      hideAuxiliary: hideAuxiliary ?? this.hideAuxiliary,
      instanceIdentifier: instanceIdentifier ?? this.instanceIdentifier,
      launcherOption: launcherOption ?? this.launcherOption,
      launcherPath: launcherPath ?? this.launcherPath,
      pickerAttributes: pickerAttributes ?? this.pickerAttributes,
      pickerAudioAssist: pickerAudioAssist ?? this.pickerAudioAssist,
      pickerMode: pickerMode ?? this.pickerMode,
      pickerVariant: pickerVariant ?? this.pickerVariant,
      pollAppleHotKeys: pollAppleHotKeys ?? this.pollAppleHotKeys,
      showPicker: showPicker ?? this.showPicker,
      takeoffDelay: takeoffDelay ?? this.takeoffDelay,
      timeout: timeout ?? this.timeout,
    );
  }

  factory MiscBoot.fromJson(Map<String, dynamic> json) {
    return MiscBoot(
      consoleAttributes: json['ConsoleAttributes'] ?? 0,
      hibernateMode: json['HibernateMode'] ?? 'None',
      hibernateSkipsPicker: json['HibernateSkipsPicker'] ?? false,
      hideAuxiliary: json['HideAuxiliary'] ?? false,
      instanceIdentifier: json['InstanceIdentifier'] ?? '',
      launcherOption: json['LauncherOption'] ?? 'Disabled',
      launcherPath: json['LauncherPath'] ?? 'Default',
      pickerAttributes: json['PickerAttributes'] ?? 17,
      pickerAudioAssist: json['PickerAudioAssist'] ?? false,
      pickerMode: json['PickerMode'] ?? 'Builtin',
      pickerVariant: json['PickerVariant'] ?? 'Auto',
      pollAppleHotKeys: json['PollAppleHotKeys'] ?? false,
      showPicker: json['ShowPicker'] ?? false,
      takeoffDelay: json['TakeoffDelay'] ?? 0,
      timeout: json['Timeout'] ?? 5,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'ConsoleAttributes': consoleAttributes,
      'HibernateMode': hibernateMode,
      'HibernateSkipsPicker': hibernateSkipsPicker,
      'HideAuxiliary': hideAuxiliary,
      'InstanceIdentifier': instanceIdentifier,
      'LauncherOption': launcherOption,
      'LauncherPath': launcherPath,
      'PickerAttributes': pickerAttributes,
      'PickerAudioAssist': pickerAudioAssist,
      'PickerMode': pickerMode,
      'PickerVariant': pickerVariant,
      'PollAppleHotKeys': pollAppleHotKeys,
      'ShowPicker': showPicker,
      'TakeoffDelay': takeoffDelay,
      'Timeout': timeout,
    };
  }
}
