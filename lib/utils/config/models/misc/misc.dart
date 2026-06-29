import 'package:rapidefi/utils/config/models/misc/misc_boot.dart';
import 'package:rapidefi/utils/config/models/misc/misc_debug.dart';
import 'package:rapidefi/utils/config/models/misc/misc_security.dart';
import 'package:rapidefi/utils/config/models/misc/misc_tools_item.dart';

class Misc {
  MiscBoot miscBoot;
  MiscDebug miscDebug;
  MiscSecurity miscSecurity;
  List<MiscToolsItem> miscToolsItems;

  Misc(
      {MiscBoot? miscBoot,
      MiscDebug? miscDebug,
      MiscSecurity? miscSecurity,
      this.miscToolsItems = const <MiscToolsItem>[]})
      : miscBoot = miscBoot ?? MiscBoot(),
        miscDebug = miscDebug ?? MiscDebug(),
        miscSecurity = miscSecurity ?? MiscSecurity();
  Misc copyWith({
    MiscBoot? miscBoot,
    MiscDebug? miscDebug,
    MiscSecurity? miscSecurity,
    List<MiscToolsItem>? miscToolsItems,
  }) {
    return Misc(
      miscBoot: miscBoot ?? this.miscBoot,
      miscDebug: miscDebug ?? this.miscDebug,
      miscSecurity: miscSecurity ?? this.miscSecurity,
      miscToolsItems: miscToolsItems ?? this.miscToolsItems,
    );
  }

  factory Misc.fromJson(Map<String, dynamic> json) {
    return Misc(
      miscBoot: json['MiscBoot'] != null
          ? MiscBoot.fromJson(json['MiscBoot'])
          : MiscBoot(),
      miscDebug: json['MiscDebug'] != null
          ? MiscDebug.fromJson(json['MiscDebug'])
          : MiscDebug(),
      miscSecurity: json['MiscSecurity'] != null
          ? MiscSecurity.fromJson(json['MiscSecurity'])
          : MiscSecurity(),
      miscToolsItems: (json['MiscToolsItems'] as List<dynamic>?)
              ?.map((item) => MiscToolsItem.fromJson(item))
              .toList() ??
          const <MiscToolsItem>[],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'MiscBoot': miscBoot.toJson(),
      'MiscDebug': miscDebug.toJson(),
      'MiscSecurity': miscSecurity.toJson(),
      'MiscToolsItems': miscToolsItems.map((item) => item.toJson()).toList(),
    };
  }
}
