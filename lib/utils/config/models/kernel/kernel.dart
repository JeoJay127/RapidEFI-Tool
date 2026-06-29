import 'package:rapidefi/utils/config/models/kernel/kernel_emulate.dart';
import 'package:rapidefi/utils/config/models/kernel/kernel_quirks.dart';
import 'package:rapidefi/utils/config/models/kernel/kernel_scheme.dart';
import 'kernel_block_item.dart';
import 'kernel_force_item.dart';
import 'kernel_kext.dart';
import 'kernel_patch_item.dart';

class Kernel {
  List<KernelKext> kernelKexts;
  List<KernelBlockItem>? kernelBlockItems;
  List<KernelForceItem>? kernelForceItems;
  List<KernelPatchItem>? kernelPatchItems;
  KernelEmulate kernelEmulate;
  KernelQuirks kernelQuirks;
  KernelScheme kernelScheme;
  Kernel(
      {List<KernelKext>? kernelKexts,
      List<KernelBlockItem>? kernelBlockItems,
      List<KernelForceItem>? kernelForceItems,
      List<KernelPatchItem>? kernelPatchItems,
      KernelEmulate? kernelEmulate,
      KernelQuirks? kernelQuirks,
      KernelScheme? kernelScheme})
      : kernelKexts = kernelKexts ?? [],
        kernelBlockItems = kernelBlockItems ?? [],
        kernelForceItems = kernelForceItems ?? [],
        kernelPatchItems = kernelPatchItems ?? [],
        kernelEmulate = kernelEmulate ?? KernelEmulate(),
        kernelQuirks = kernelQuirks ?? KernelQuirks(),
        kernelScheme = kernelScheme ?? KernelScheme();
  Kernel copyWith({
    List<KernelKext>? kernelKexts,
    List<KernelBlockItem>? kernelBlockItems,
    List<KernelForceItem>? kernelForceItems,
    List<KernelPatchItem>? kernelPatchItems,
    KernelEmulate? kernelEmulate,
    KernelQuirks? kernelQuirks,
    KernelScheme? kernelScheme,
  }) {
    return Kernel(
      kernelKexts: kernelKexts ?? List.from(this.kernelKexts),
      kernelBlockItems:
          kernelBlockItems ?? List.from(this.kernelBlockItems ?? []),
      kernelForceItems:
          kernelForceItems ?? List.from(this.kernelForceItems ?? []),
      kernelPatchItems:
          kernelPatchItems ?? List.from(this.kernelPatchItems ?? []),
      kernelEmulate: kernelEmulate ?? this.kernelEmulate,
      kernelQuirks: kernelQuirks ?? this.kernelQuirks,
      kernelScheme: kernelScheme ?? this.kernelScheme,
    );
  }

  factory Kernel.fromJson(Map<String, dynamic> json) {
    return Kernel(
      kernelKexts: (json['kernelKexts'] as List<dynamic>?)
              ?.map((item) => KernelKext.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      kernelBlockItems: (json['kernelBlockItems'] as List<dynamic>?)
              ?.map((item) =>
                  KernelBlockItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      kernelForceItems: (json['kernelForceItems'] as List<dynamic>?)
              ?.map((item) =>
                  KernelForceItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      kernelPatchItems: (json['kernelPatchItems'] as List<dynamic>?)
              ?.map((item) =>
                  KernelPatchItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      kernelEmulate:
          KernelEmulate.fromJson(json['kernelEmulate'] as Map<String, dynamic>),
      kernelQuirks:
          KernelQuirks.fromJson(json['kernelQuirks'] as Map<String, dynamic>),
      kernelScheme:
          KernelScheme.fromJson(json['kernelScheme'] as Map<String, dynamic>),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'kernelKexts': kernelKexts.map((kext) => kext.toJson()).toList(),
      'kernelBlockItems':
          kernelBlockItems?.map((blockItem) => blockItem.toJson()).toList(),
      'kernelForceItems':
          kernelForceItems?.map((forceItem) => forceItem.toJson()).toList(),
      'kernelPatchItems':
          kernelPatchItems?.map((patchItem) => patchItem.toJson()).toList(),
      'kernelEmulate': kernelEmulate.toJson(),
      'kernelQuirks': kernelQuirks.toJson(),
      'kernelScheme': kernelScheme.toJson(),
    };
  }
}
