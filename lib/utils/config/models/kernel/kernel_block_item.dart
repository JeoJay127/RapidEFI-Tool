class KernelBlockItem {
  String identifier;
  String comment;
  bool enabled;
  String strategy;
  String minKernel;
  String maxKernel;
  String arch;
  String note;

  KernelBlockItem(
      {this.identifier = '',
      this.comment = '',
      this.enabled = false,
      this.strategy = 'Disable',
      this.minKernel = '',
      this.maxKernel = '',
      this.arch = 'Any',
      this.note = '',
      });

  KernelBlockItem copyWith({
    String? identifier,
    String? comment,
    bool? enabled,
    String? strategy,
    String? minKernel,
    String? maxKernel,
    String? arch,
    String? note,
  }) {
    return KernelBlockItem(
      identifier: identifier ?? this.identifier,
      comment: comment ?? this.comment,
      enabled: enabled ?? this.enabled,
      strategy: strategy ?? this.strategy,
      minKernel: minKernel ?? this.minKernel,
      maxKernel: maxKernel ?? this.maxKernel,
      arch: arch ?? this.arch,
      note: note ?? this.note,
    );
  }

  factory KernelBlockItem.fromJson(Map<String, dynamic> json) {
    return KernelBlockItem(
      identifier: json['Identifier'] ?? '',
      comment: json['Comment'] ?? '',
      enabled: json['Enabled'] ?? false,
      strategy: json['Strategy'] ?? 'Disable',
      minKernel: json['MinKernel'] ?? '',
      maxKernel: json['MaxKernel'] ?? '',
      arch: json['Arch'] ?? 'Any',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'Identifier': identifier,
      'Comment': comment,
      'Enabled': enabled,
      'Strategy': strategy,
      'MinKernel': minKernel,
      'MaxKernel': maxKernel,
      'Arch': arch,
    };
  }
}
