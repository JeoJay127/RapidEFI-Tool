import 'package:rapidefi/utils/config/models/booter/booter_mmio_item.dart';
import 'package:rapidefi/utils/config/models/booter/booter_quirks.dart';
import 'booter_patch_item.dart';

class Booter {
  List<BooterMmioWhitelistItem> booterMmioWhitelistItems;
  List<BooterPatchItem> booterPatchItems;
  BooterQuirks booterQuirks;

  Booter(
      {this.booterMmioWhitelistItems = const <BooterMmioWhitelistItem>[],
      this.booterPatchItems = const <BooterPatchItem>[],
      BooterQuirks? booterQuirks})
      : booterQuirks = booterQuirks ?? BooterQuirks();

  Booter copyWith({
    List<BooterMmioWhitelistItem>? booterMmioWhitelistItems,
    List<BooterPatchItem>? booterPatchItems,
    BooterQuirks? booterQuirks,
  }) {
    return Booter(
      booterMmioWhitelistItems:
          booterMmioWhitelistItems ?? this.booterMmioWhitelistItems,
      booterPatchItems: booterPatchItems ?? this.booterPatchItems,
      booterQuirks: booterQuirks ?? this.booterQuirks.copyWith(),
    );
  }

  factory Booter.fromJson(Map<String, dynamic> json) {
    return Booter(
      booterMmioWhitelistItems:
          (json['booterMmioWhitelistItems'] as List<dynamic>?)
                  ?.map((item) => BooterMmioWhitelistItem.fromJson(
                      item as Map<String, dynamic>))
                  .toList() ??
              const <BooterMmioWhitelistItem>[],
      booterPatchItems: (json['booterPatchItems'] as List<dynamic>?)
              ?.map((item) =>
                  BooterPatchItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const <BooterPatchItem>[],
      booterQuirks: json['booterQuirks'] != null
          ? BooterQuirks.fromJson(json['booterQuirks'] as Map<String, dynamic>)
          : BooterQuirks(),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'booterMmioWhitelistItems':
          booterMmioWhitelistItems.map((item) => item.toJson()).toList(),
      'booterPatchItems':
          booterPatchItems.map((item) => item.toJson()).toList(),
      'booterQuirks': booterQuirks.toJson(),
    };
  }
}
