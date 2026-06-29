import 'dart:typed_data';

class KernelEmulate {
  Uint8List? cpuid1Data;
  Uint8List? cpuid1Mask;
  bool dummyPowerManagement;
  String maxKernel;
  String minKernel;

  KernelEmulate({
    this.cpuid1Data,
    this.cpuid1Mask,
    this.dummyPowerManagement = false,
    this.maxKernel = '',
    this.minKernel = '',
  });

  KernelEmulate copyWith({
    Uint8List? cpuid1Data,
    Uint8List? cpuid1Mask,
    bool? dummyPowerManagement,
    String? maxKernel,
    String? minKernel,
  }) {
    return KernelEmulate(
      cpuid1Data: cpuid1Data ?? this.cpuid1Data,
      cpuid1Mask: cpuid1Mask ?? this.cpuid1Mask,
      dummyPowerManagement: dummyPowerManagement ?? this.dummyPowerManagement,
      maxKernel: maxKernel ?? this.maxKernel,
      minKernel: minKernel ?? this.minKernel,
    );
  }

  factory KernelEmulate.fromJson(Map<String, dynamic> json) {
    return KernelEmulate(
      cpuid1Data: json['Cpuid1Data'] != null
          ? Uint8List.fromList(List<int>.from(json['Cpuid1Data']))
          : null,
      cpuid1Mask: json['Cpuid1Mask'] != null
          ? Uint8List.fromList(List<int>.from(json['Cpuid1Mask']))
          : null,
      dummyPowerManagement: json['DummyPowerManagement'] ?? false,
      maxKernel: json['MaxKernel'] ?? '',
      minKernel: json['MinKernel'] ?? '',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'Cpuid1Data': cpuid1Data,
      'Cpuid1Mask': cpuid1Mask,
      'DummyPowerManagement': dummyPowerManagement,
      'MaxKernel': maxKernel,
      'MinKernel': minKernel,
    };
  }
}
