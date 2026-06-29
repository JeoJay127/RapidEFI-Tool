import 'package:rapidefi/utils/config/models/nvram/nvram_delete.dart';
import 'package:rapidefi/utils/config/models/nvram/nvram_legacy_schema.dart';
import 'nvram_add.dart';

class NVRAM {
  NvramAdd nvramAdd;
  NvramDelete nvramDelete;
  NvramLegacyschema nvramLegacyschema;
  bool legacyOverwrite;
  bool writeFlash;
  NVRAM(
      {this.legacyOverwrite = false,
      this.writeFlash = true,
      NvramAdd? nvramAdd,
      NvramDelete? nvramDelete,
      NvramLegacyschema? nvramLegacyschema})
      : nvramAdd = nvramAdd ?? NvramAdd(),
        nvramDelete = nvramDelete ?? NvramDelete(),
        nvramLegacyschema = nvramLegacyschema ?? NvramLegacyschema();

  NVRAM copyWith({
    bool? legacyOverwrite,
    bool? writeFlash,
    NvramAdd? nvramAdd,
    NvramDelete? nvramDelete,
    NvramLegacyschema? nvramLegacyschema,
  }) {
    return NVRAM(
      legacyOverwrite: legacyOverwrite ?? this.legacyOverwrite,
      writeFlash: writeFlash ?? this.writeFlash,
      nvramAdd: nvramAdd ?? this.nvramAdd.copyWith(),
      nvramDelete: nvramDelete ?? this.nvramDelete.copyWith(),
      nvramLegacyschema: nvramLegacyschema ?? this.nvramLegacyschema,
    );
  }

  factory NVRAM.fromJson(Map<String, dynamic> json) {
    return NVRAM(
      legacyOverwrite: json['LegacyOverwrite'] ?? false,
      writeFlash: json['WriteFlash'] ?? true,
      nvramAdd:
          json['Add'] != null ? NvramAdd.fromJson(json['Add']) : NvramAdd(),
      nvramDelete: json['Delete'] != null
          ? NvramDelete.fromJson(json['Delete'])
          : NvramDelete(),
      nvramLegacyschema: json['LegacySchema'] != null
          ? NvramLegacyschema.fromJson(json['LegacySchema'])
          : NvramLegacyschema(),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'LegacyOverwrite': legacyOverwrite,
      'WriteFlash': writeFlash,
      'Add': nvramAdd.toJson(),
      'Delete': nvramDelete.toJson(),
      'LegacySchema': nvramLegacyschema.toJson(),
    };
  }
}
