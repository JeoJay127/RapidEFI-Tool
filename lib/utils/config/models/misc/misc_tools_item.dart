class MiscToolsItem {
  String arguments;
  bool auxiliary;
  String comment;
  bool enabled;
  String flavour;
  bool fullNvramAccess;
  String name;
  String path;
  bool realPath;
  bool textMode;

  MiscToolsItem({
    this.arguments = '',
    this.auxiliary = false,
    this.comment = '',
    this.enabled = false,
    this.flavour = '',
    this.fullNvramAccess = false,
    this.name = '',
    this.path = '',
    this.realPath = false,
    this.textMode = false,
  });
  MiscToolsItem copyWith({
    String? arguments,
    bool? auxiliary,
    String? comment,
    bool? enabled,
    String? flavour,
    bool? fullNvramAccess,
    String? name,
    String? path,
    bool? realPath,
    bool? textMode,
  }) {
    return MiscToolsItem(
      arguments: arguments ?? this.arguments,
      auxiliary: auxiliary ?? this.auxiliary,
      comment: comment ?? this.comment,
      enabled: enabled ?? this.enabled,
      flavour: flavour ?? this.flavour,
      fullNvramAccess: fullNvramAccess ?? this.fullNvramAccess,
      name: name ?? this.name,
      path: path ?? this.path,
      realPath: realPath ?? this.realPath,
      textMode: textMode ?? this.textMode,
    );
  }

  factory MiscToolsItem.fromJson(Map<String, dynamic> json) {
    return MiscToolsItem(
      arguments: json['Arguments'] ?? '',
      auxiliary: json['Auxiliary'] ?? false,
      comment: json['Comment'] ?? '',
      enabled: json['Enabled'] ?? false,
      flavour: json['Flavour'] ?? '',
      fullNvramAccess: json['FullNvramAccess'] ?? false,
      name: json['Name'] ?? '',
      path: json['Path'] ?? '',
      realPath: json['RealPath'] ?? false,
      textMode: json['TextMode'] ?? false,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'Arguments': arguments,
      'Auxiliary': auxiliary,
      'Comment': comment,
      'Enabled': enabled,
      'Flavour': flavour,
      'FullNvramAccess': fullNvramAccess,
      'Name': name,
      'Path': path,
      'RealPath': realPath,
      'TextMode': textMode,
    };
  }
}
