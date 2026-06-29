import 'package:rapidefi/utils/config/models/acpi/acpi_add_item.dart';
import 'package:rapidefi/utils/config/models/acpi/acpi_delete_item.dart';
import 'package:rapidefi/utils/config/models/acpi/acpi_patch_item.dart';
import 'package:rapidefi/utils/config/models/acpi/acpi_quirks.dart';

class Acpi {
  List<AcpiAddItem> acpiAddItems;
  List<AcpiDeleteItem> acpiDeleteItems;
  List<AcpiPatchItem> acpiPatchItems;
  AcpiQuirks acpiQuirks;
  Acpi({
    this.acpiAddItems = const <AcpiAddItem>[],
    this.acpiDeleteItems = const <AcpiDeleteItem>[],
    this.acpiPatchItems = const <AcpiPatchItem>[],
    AcpiQuirks? acpiQuirks,
  }) : acpiQuirks = acpiQuirks ?? AcpiQuirks();
  Acpi copyWith({
    List<AcpiAddItem>? acpiAddItems,
    List<AcpiDeleteItem>? acpiDeleteItems,
    List<AcpiPatchItem>? acpiPatchItems,
    AcpiQuirks? acpiQuirks,
  }) {
    return Acpi(
      acpiAddItems: acpiAddItems ?? this.acpiAddItems,
      acpiDeleteItems: acpiDeleteItems ?? this.acpiDeleteItems,
      acpiPatchItems: acpiPatchItems ?? this.acpiPatchItems,
      acpiQuirks: acpiQuirks ?? this.acpiQuirks,
    );
  }

  factory Acpi.fromJson(Map<String, dynamic> json) {
    return Acpi(
      acpiAddItems: (json['acpiAddItems'] as List<dynamic>?)
              ?.map(
                  (item) => AcpiAddItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const <AcpiAddItem>[],
      acpiDeleteItems: (json['acpiDeleteItems'] as List<dynamic>?)
              ?.map((item) =>
                  AcpiDeleteItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const <AcpiDeleteItem>[],
      acpiPatchItems: (json['acpiPatchItems'] as List<dynamic>?)
              ?.map((item) =>
                  AcpiPatchItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const <AcpiPatchItem>[],
      acpiQuirks: json['acpiQuirks'] != null
          ? AcpiQuirks.fromJson(json['acpiQuirks'] as Map<String, dynamic>)
          : AcpiQuirks(),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'acpiAddItems': acpiAddItems.map((item) => item.toJson()).toList(),
      'acpiDeleteItems': acpiDeleteItems.map((item) => item.toJson()).toList(),
      'acpiPatchItems': acpiPatchItems.map((item) => item.toJson()).toList(),
      'acpiQuirks': acpiQuirks.toJson(),
    };
  }
}
