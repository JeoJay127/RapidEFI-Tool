class KernelScheme {
  bool customKernel;
  bool fuzzyMatch;
  String kernelArch;
  String kernelCache;

  KernelScheme(
      {this.customKernel = false,
      this.fuzzyMatch = true,
      this.kernelArch = 'Auto',
      this.kernelCache = 'Auto'});

  KernelScheme copyWith({
    bool? customKernel,
    bool? fuzzyMatch,
    String? kernelArch,
    String? kernelCache,
  }) {
    return KernelScheme(
      customKernel: customKernel ?? this.customKernel,
      fuzzyMatch: fuzzyMatch ?? this.fuzzyMatch,
      kernelArch: kernelArch ?? this.kernelArch,
      kernelCache: kernelCache ?? this.kernelCache,
    );
  }

  factory KernelScheme.fromJson(Map<String, dynamic> json) {
    return KernelScheme(
      customKernel: json['CustomKernel'] ?? false,
      fuzzyMatch: json['FuzzyMatch'] ?? true,
      kernelArch: json['KernelArch'] ?? 'Auto',
      kernelCache: json['KernelCache'] ?? 'Auto',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'CustomKernel': customKernel,
      'FuzzyMatch': fuzzyMatch,
      'KernelArch': kernelArch,
      'KernelCache': kernelCache,
    };
  }
}
