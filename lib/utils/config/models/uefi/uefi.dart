import 'package:rapidefi/utils/config/models/uefi/uefi_apfs.dart';
import 'package:rapidefi/utils/config/models/uefi/uefi_appleinput.dart';
import 'package:rapidefi/utils/config/models/uefi/uefi_audio.dart';
import 'package:rapidefi/utils/config/models/uefi/uefi_drivers_item.dart';
import 'package:rapidefi/utils/config/models/uefi/uefi_input.dart';
import 'package:rapidefi/utils/config/models/uefi/uefi_protocol_overrides.dart';
import 'package:rapidefi/utils/config/models/uefi/uefi_quirks.dart';
import 'package:rapidefi/utils/config/models/uefi/uefi_reserved_memory.dart';
import 'uefi_output.dart';

class Uefi {
  bool connectDrivers;
  UefiApfs uefiApfs;
  UefiAppleInput uefiAppleInput;
  UefiAudio uefiAudio;
  List<UefiDriversItem> uefiDriversItems;
  UefiInput uefiInput;
  UefiOutput uefiOutput;
  UefiProtocolOverrides uefiProtocolOverrides;
  UefiQuirks uefiQuirks;
  UefiReservedMemory uefiReservedMemory;
  Uefi({
    this.connectDrivers = true,
    UefiApfs? uefiApfs,
    UefiAppleInput? uefiAppleInput,
    UefiAudio? uefiAudio,
    this.uefiDriversItems = const <UefiDriversItem>[],
    UefiInput? uefiInput,
    UefiOutput? uefiOutput,
    UefiProtocolOverrides? uefiProtocolOverrides,
    UefiQuirks? uefiQuirks,
    UefiReservedMemory? uefiReservedMemory,
  })  : uefiApfs = uefiApfs ?? UefiApfs(),
        uefiAppleInput = uefiAppleInput ?? UefiAppleInput(),
        uefiAudio = uefiAudio ?? UefiAudio(),
        uefiInput = uefiInput ?? UefiInput(),
        uefiOutput = uefiOutput ?? UefiOutput(),
        uefiProtocolOverrides =
            uefiProtocolOverrides ?? UefiProtocolOverrides(),
        uefiQuirks = uefiQuirks ?? UefiQuirks(),
        uefiReservedMemory = uefiReservedMemory ?? UefiReservedMemory();

  Uefi copyWith({
    bool? connectDrivers,
    UefiApfs? uefiApfs,
    UefiAppleInput? uefiAppleInput,
    UefiAudio? uefiAudio,
    List<UefiDriversItem>? uefiDriversItems,
    UefiInput? uefiInput,
    UefiOutput? uefiOutput,
    UefiProtocolOverrides? uefiProtocolOverrides,
    UefiQuirks? uefiQuirks,
    UefiReservedMemory? uefiReservedMemory,
  }) {
    return Uefi(
      connectDrivers: connectDrivers ?? this.connectDrivers,
      uefiApfs: uefiApfs ?? this.uefiApfs,
      uefiAppleInput: uefiAppleInput ?? this.uefiAppleInput,
      uefiAudio: uefiAudio ?? this.uefiAudio,
      uefiDriversItems: uefiDriversItems ?? List.from(this.uefiDriversItems),
      uefiInput: uefiInput ?? this.uefiInput,
      uefiOutput: uefiOutput ?? this.uefiOutput,
      uefiProtocolOverrides:
          uefiProtocolOverrides ?? this.uefiProtocolOverrides,
      uefiQuirks: uefiQuirks ?? this.uefiQuirks.copyWith(),
      uefiReservedMemory: uefiReservedMemory ?? this.uefiReservedMemory,
    );
  }

  factory Uefi.fromJson(Map<String, dynamic> json) {
    return Uefi(
      connectDrivers: json['ConnectDrivers'] as bool? ?? true,
      uefiApfs: json['uefiApfs'] != null
          ? UefiApfs.fromJson(json['uefiApfs'] as Map<String, dynamic>)
          : UefiApfs(),
      uefiAppleInput: json['uefiAppleInput'] != null
          ? UefiAppleInput.fromJson(
              json['uefiAppleInput'] as Map<String, dynamic>)
          : UefiAppleInput(),
      uefiAudio: json['uefiAudio'] != null
          ? UefiAudio.fromJson(json['uefiAudio'] as Map<String, dynamic>)
          : UefiAudio(),
      uefiDriversItems: (json['uefiDriversItems'] as List<dynamic>?)
              ?.map((item) =>
                  UefiDriversItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const <UefiDriversItem>[],
      uefiInput: json['uefiInput'] != null
          ? UefiInput.fromJson(json['uefiInput'] as Map<String, dynamic>)
          : UefiInput(),
      uefiOutput: json['uefiOutput'] != null
          ? UefiOutput.fromJson(json['uefiOutput'] as Map<String, dynamic>)
          : UefiOutput(),
      uefiProtocolOverrides: json['uefiProtocolOverrides'] != null
          ? UefiProtocolOverrides.fromJson(
              json['uefiProtocolOverrides'] as Map<String, dynamic>)
          : UefiProtocolOverrides(),
      uefiQuirks: json['uefiQuirks'] != null
          ? UefiQuirks.fromJson(json['uefiQuirks'] as Map<String, dynamic>)
          : UefiQuirks(),
      uefiReservedMemory: json['uefiReservedMemory'] != null
          ? UefiReservedMemory.fromJson(
              json['uefiReservedMemory'] as Map<String, dynamic>)
          : UefiReservedMemory(),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'ConnectDrivers': connectDrivers,
      'uefiApfs': uefiApfs.toJson(),
      'uefiAppleInput': uefiAppleInput.toJson(),
      'uefiAudio': uefiAudio.toJson(),
      'uefiDriversItems':
          uefiDriversItems.map((item) => item.toJson()).toList(),
      'uefiInput': uefiInput.toJson(),
      'uefiOutput': uefiOutput.toJson(),
      'uefiProtocolOverrides': uefiProtocolOverrides.toJson(),
      'uefiQuirks': uefiQuirks.toJson(),
      'uefiReservedMemory': uefiReservedMemory.toJson(),
    };
  }
}
