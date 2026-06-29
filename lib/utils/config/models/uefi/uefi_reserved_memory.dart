import 'package:rapidefi/utils/config/models/uefi/uefi_memory_item.dart';

class UefiReservedMemory {
  List<UefiMemoryItem> uefiMemoryItems;
  UefiReservedMemory({this.uefiMemoryItems = const []});

  UefiReservedMemory copyWith({
    List<UefiMemoryItem>? uefiMemoryItems,
  }) {
    return UefiReservedMemory(
      uefiMemoryItems: uefiMemoryItems ?? this.uefiMemoryItems,
    );
  }

  factory UefiReservedMemory.fromJson(Map<String, dynamic> json) {
    return UefiReservedMemory(
      uefiMemoryItems: (json['ReservedMemory'] as List<dynamic>?)
              ?.map((item) =>
                  UefiMemoryItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'ReservedMemory': uefiMemoryItems.map((item) => item.toJson()).toList(),
    };
  }
}
