class KernelForceItem {
  String arch;
  String bundlePath;
  String comment;
  bool enabled;
  String executablePath;
  String identifier;
  String maxKernel;
  String minKernel;
  String plistPath;
  String note;

  KernelForceItem({
    this.arch = '',
    this.bundlePath = '',
    this.comment = '',
    this.enabled = false,
    this.executablePath = '',
    this.identifier = '',
    this.maxKernel = '',
    this.minKernel = '',
    this.plistPath = '',
    this.note = '',
  });
  KernelForceItem copyWith({
    String? arch,
    String? bundlePath,
    String? comment,
    bool? enabled,
    String? executablePath,
    String? identifier,
    String? maxKernel,
    String? minKernel,
    String? plistPath,
    String? note,
  }) {
    return KernelForceItem(
      arch: arch ?? this.arch,
      bundlePath: bundlePath ?? this.bundlePath,
      comment: comment ?? this.comment,
      enabled: enabled ?? this.enabled,
      executablePath: executablePath ?? this.executablePath,
      identifier: identifier ?? this.identifier,
      maxKernel: maxKernel ?? this.maxKernel,
      minKernel: minKernel ?? this.minKernel,
      plistPath: plistPath ?? this.plistPath,
      note: note ?? this.note,
    );
  }

  factory KernelForceItem.fromJson(Map<String, dynamic> json) {
    return KernelForceItem(
      arch: json['Arch'] ?? '',
      bundlePath: json['BundlePath'] ?? '',
      comment: json['Comment'] ?? '',
      enabled: json['Enabled'] ?? false,
      executablePath: json['ExecutablePath'] ?? '',
      identifier: json['Identifier'] ?? '',
      maxKernel: json['MaxKernel'] ?? '',
      minKernel: json['MinKernel'] ?? '',
      plistPath: json['PlistPath'] ?? '',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'Arch': arch,
      'BundlePath': bundlePath,
      'Comment': comment,
      'Enabled': enabled,
      'ExecutablePath': executablePath,
      'Identifier': identifier,
      'MaxKernel': maxKernel,
      'MinKernel': minKernel,
      'PlistPath': plistPath,
    };
  }
}
