class KernelKext {
  String name;
  String url;
  String bundlePath;
  String comment;
  bool enabled;
  String executablePath;
  String plistPath;
  String minKernel;
  String maxKernel;
  String arch;
  bool essential;
  String type;
  String function;
  List<String> note;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KernelKext &&
          runtimeType == other.runtimeType &&
          bundlePath == other.bundlePath;

  @override
  int get hashCode => bundlePath.hashCode;

  KernelKext({
    this.name = '',
    this.url = '',
    this.bundlePath = '',
    this.comment = '',
    this.enabled = true,
    this.executablePath = '',
    this.plistPath = '',
    this.minKernel = '',
    this.maxKernel = '',
    this.arch = 'Any',
    this.essential = false,
    this.type = '',
    this.function = '',
    this.note = const [],
  });

  KernelKext copyWith(
      {String? name,
      String? url,
      String? bundlePath,
      String? comment,
      bool? enabled,
      String? executablePath,
      String? plistPath,
      String? minKernel,
      String? maxKernel,
      String? arch,
      String? osSupport,
      bool? essential,
      String? type,
      String? function,
      List<String>? note}) {
    return KernelKext(
        name: name ?? this.name,
        url: url ?? this.url,
        bundlePath: bundlePath ?? this.bundlePath,
        comment: comment ?? this.comment,
        enabled: enabled ?? this.enabled,
        executablePath: executablePath ?? this.executablePath,
        plistPath: plistPath ?? this.plistPath,
        minKernel: minKernel ?? this.minKernel,
        maxKernel: maxKernel ?? this.maxKernel,
        arch: arch ?? this.arch,
        essential: essential ?? this.essential,
        type: type ?? this.type,
        function: function ?? this.function,
        note: note ?? this.note);
  }

  factory KernelKext.fromJson(Map<String, dynamic> json) {
    String readStr(String capitalKey, String lowerKey) =>
        (json[capitalKey] ?? json[lowerKey] ?? '').toString();
    bool readBool(String capitalKey, String lowerKey) =>
        (json[capitalKey] ?? json[lowerKey]) as bool? ?? false;
    List<String> readList(String capitalKey, String lowerKey) {
      final v = json[capitalKey] ?? json[lowerKey];
      return (v is List) ? v.map((e) => e.toString()).toList() : [];
    }

    final archVal = readStr('Arch', 'arch');
    final plistVal = readStr('PlistPath', 'plistPath');

    return KernelKext(
      name: readStr('Name', 'name'),
      url: readStr('Url', 'url'),
      bundlePath: readStr('BundlePath', 'bundlePath'),
      comment: readStr('Comment', 'comment'),
      enabled: readBool('Enabled', 'enabled'),
      executablePath: readStr('ExecutablePath', 'executablePath'),
      plistPath: plistVal.isEmpty ? 'Contents/Info.plist' : plistVal,
      minKernel: readStr('MinKernel', 'minKernel'),
      maxKernel: readStr('MaxKernel', 'maxKernel'),
      arch: archVal.isEmpty ? 'Any' : archVal,
      essential: readBool('Essential', 'essential'),
      type: readStr('Type', 'type'),
      function: readStr('Function', 'function'),
      note: readList('Note', 'note'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'BundlePath': bundlePath,
      'Comment': comment,
      'Enabled': enabled,
      'ExecutablePath': executablePath,
      'PlistPath': plistPath,
      'MinKernel': minKernel,
      'MaxKernel': maxKernel,
      'Arch': arch,
    };
  }
}
