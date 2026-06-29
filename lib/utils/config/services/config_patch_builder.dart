import 'dart:typed_data';
import 'package:rapidefi/extension/string_extension.dart';
import 'package:rapidefi/utils/config/support/platform_properties.dart';
import 'package:rapidefi/utils/config/models/nvram/nvram_add_item.dart';
import 'package:rapidefi/utils/config/models/nvram/nvram_delete_item.dart';
import 'package:rapidefi/utils/config/presets/patches/patch_op.dart';
import 'package:rapidefi/utils/config/config_model.dart';
import 'package:rapidefi/utils/config/presets/patches/plist_typed_value.dart';
import 'package:rapidefi/utils/config/presets/sections/config_device_properties.dart';

class ConfigPatchBuilder {
  final ConfigModel model;
  ConfigPatchBuilder({required this.model});
  List<PatchOp> build() {
    final ops = <PatchOp>[];

    _buildAcpi(ops);
    _buildBooter(ops);
    _buildDeviceProperties(ops);
    _buildKernel(ops);
    _buildMisc(ops);
    _buildNvram(ops);
    _buildPlatformInfo(ops);
    _buildUefi(ops);

    return ops;
  }

  void _buildAcpi(List<PatchOp> ops) {
    ops.add(PatchOp.replaceArray(
      ['ACPI', 'Add'],
      model.acpi.acpiAddItems.map((e) => e.toJson()).toList(),
    ));

    ops.add(PatchOp.replaceArray(
      ['ACPI', 'Delete'],
      model.acpi.acpiDeleteItems.map(_acpiDeleteToPlist).toList(),
    ));

    ops.add(PatchOp.replaceArray(
      ['ACPI', 'Patch'],
      model.acpi.acpiPatchItems.map(_acpiPatchToPlist).toList(),
    ));

    ops.add(PatchOp.mergeDict(
      ['ACPI', 'Quirks'],
      _normalizePlistMap(model.acpi.acpiQuirks.toJson()),
    ));
  }

  void _buildKernel(List<PatchOp> ops) {
    ops.add(PatchOp.replaceArray(
      ['Kernel', 'Add'],
      model.kernel.kernelKexts.map(_kextToPlist).toList(),
    ));

    ops.add(PatchOp.replaceArray(
      ['Kernel', 'Block'],
      model.kernel.kernelBlockItems?.map(_kernelBlockToPlist).toList() ?? [],
    ));

    ops.add(PatchOp.replaceArray(
      ['Kernel', 'Force'],
      model.kernel.kernelForceItems?.map(_kernelForceToPlist).toList() ?? [],
    ));

    ops.add(PatchOp.replaceArray(
      ['Kernel', 'Patch'],
      model.kernel.kernelPatchItems?.map(_kernelPatchToPlist).toList() ?? [],
    ));

    ops.add(PatchOp.mergeDict(
      ['Kernel', 'Quirks'],
      _normalizePlistMap(model.kernel.kernelQuirks.toJson()),
    ));

    ops.add(PatchOp.mergeDict(
      ['Kernel', 'Emulate'],
      _kernelEmulateToPlist(model.kernel.kernelEmulate),
    ));

    ops.add(PatchOp.mergeDict(
      ['Kernel', 'Scheme'],
      _normalizePlistMap(model.kernel.kernelScheme.toJson()),
    ));
  }

  void _buildNvram(List<PatchOp> ops) {
    final addMap = <String, dynamic>{};
    model.nvram.nvramAdd.addList?.forEach(
      (String guid, List<NvramAddItem>? items) {
        final dict = <String, dynamic>{};

        items?.forEach((NvramAddItem item) {
          dict[item.key.nullSafe] = PlistTypedValue(
            type: item.dataType.nullSafe,
            value: item.value.nullSafe,
          );
        });

        addMap[guid] = dict;
      },
    );

    final deleteMap = <String, dynamic>{};
    model.nvram.nvramDelete.deleteList?.forEach(
      (String guid, List<NvramDeleteItem>? items) {
        deleteMap[guid] = items
                ?.map((NvramDeleteItem item) => item.value.nullSafe)
                .toList() ??
            <String>[];
      },
    );

    ops.add(PatchOp.set(
      ['NVRAM', 'LegacyOverwrite'],
      model.nvram.legacyOverwrite,
    ));

    ops.add(PatchOp.set(
      ['NVRAM', 'WriteFlash'],
      model.nvram.writeFlash,
    ));

    ops.add(PatchOp.set(
      ['NVRAM', 'Add'],
      addMap,
    ));

    ops.add(PatchOp.set(
      ['NVRAM', 'Delete'],
      deleteMap,
    ));
  }

  void _buildBooter(List<PatchOp> ops) {
    ops.add(PatchOp.replaceArray(
      ['Booter', 'MmioWhitelist'],
      model.booter.booterMmioWhitelistItems
          .map((item) => _normalizePlistMap(item.toJson()))
          .toList(),
    ));

    ops.add(PatchOp.replaceArray(
      ['Booter', 'Patch'],
      model.booter.booterPatchItems.map(_booterPatchToPlist).toList(),
    ));

    ops.add(PatchOp.mergeDict(
      ['Booter', 'Quirks'],
      _normalizePlistMap(model.booter.booterQuirks.toJson()),
    ));
  }

  void _buildDeviceProperties(List<PatchOp> ops) {
    final addMap = <String, dynamic>{};

    final addList = model.deviceProperties.addList?.toSet().toList();

    addList?.forEach((deviceProperty) {
      if (deviceProperty.pciPath.trim().isEmpty ||
          deviceProperty.propertyItems.isEmpty) {
        return;
      }

      final propertyDict = <String, dynamic>{};

      /// 基础属性
      for (final item in deviceProperty.propertyItems) {
        propertyDict[item.key.nullSafe] = PlistTypedValue(
          type: item.dataType.nullSafe,
          value: item.value.nullSafe,
        );
      }

      /// 核显高级属性
      if (deviceProperty.pciPath == ConfigDp.pciPath) {
        final hasFramebufferPatch = deviceProperty.propertyItems.any(
          (element) => element.key.nullSafe.startsWith('framebuffer-'),
        );
        if (hasFramebufferPatch) {
          propertyDict[framebuffer_patch_enable.key.nullSafe] = PlistTypedValue(
            type: framebuffer_patch_enable.dataType.nullSafe,
            value: framebuffer_patch_enable.value.nullSafe,
          );
        }
      }

      addMap[deviceProperty.pciPath] = propertyDict;
    });

    ops.add(PatchOp.set(
      ['DeviceProperties', 'Add'],
      addMap,
    ));

    ops.add(PatchOp.set(
      ['DeviceProperties', 'Delete'],
      <String, dynamic>{},
    ));
  }

  void _buildMisc(List<PatchOp> ops) {
    ops.add(PatchOp.mergeDict(
      ['Misc', 'Boot'],
      _normalizePlistMap(model.misc.miscBoot.toJson()),
    ));

    ops.add(PatchOp.mergeDict(
      ['Misc', 'Debug'],
      _normalizePlistMap(model.misc.miscDebug.toJson()),
    ));

    ops.add(PatchOp.mergeDict(
      ['Misc', 'Security'],
      _miscSecurityToPlist(model.misc.miscSecurity),
    ));

    ops.add(PatchOp.replaceArray(
      ['Misc', 'Tools'],
      model.misc.miscToolsItems
          .map((item) => _normalizePlistMap(item.toJson()))
          .toList(),
    ));
  }

  void _buildPlatformInfo(List<PatchOp> ops) {
    final platformInfoMap = _normalizePlistMap(model.platformInfo.toJson());

    final genericMap = model.platformInfo.generic?.toJson();

    platformInfoMap.remove('Generic');
    platformInfoMap.remove('generic');

    ops.add(PatchOp.mergeDict(
      ['PlatformInfo'],
      platformInfoMap,
    ));

    if (genericMap != null) {
      ops.add(PatchOp.mergeDict(
        ['PlatformInfo', 'Generic'],
        _platformInfoGenericToPlist(genericMap),
      ));
    }
  }

  void _buildUefi(List<PatchOp> ops) {
    ops.add(PatchOp.mergeDict(
      ['UEFI', 'APFS'],
      _normalizePlistMap(model.uefi.uefiApfs.toJson()),
    ));

    ///

    ops.add(PatchOp.mergeDict(
      ['UEFI', 'AppleInput'],
      _normalizePlistMap(model.uefi.uefiAppleInput.toJson()),
    ));

    ops.add(PatchOp.mergeDict(
      ['UEFI', 'Audio'],
      _normalizePlistMap(model.uefi.uefiAudio.toJson()),
    ));

    ops.add(PatchOp.replaceArray(
      ['UEFI', 'Drivers'],
      model.uefi.uefiDriversItems
          .map((item) => _normalizePlistMap(item.toJson()))
          .toList(),
    ));

    ops.add(PatchOp.mergeDict(
      ['UEFI', 'Input'],
      _normalizePlistMap(model.uefi.uefiInput.toJson()),
    ));

    ops.add(PatchOp.mergeDict(
      ['UEFI', 'Output'],
      _normalizePlistMap(model.uefi.uefiOutput.toJson()),
    ));

    ops.add(PatchOp.mergeDict(
      ['UEFI', 'ProtocolOverrides'],
      _normalizePlistMap(model.uefi.uefiProtocolOverrides.toJson()),
    ));

    ops.add(PatchOp.mergeDict(
      ['UEFI', 'Quirks'],
      _normalizePlistMap(model.uefi.uefiQuirks.toJson()),
    ));

    ops.add(PatchOp.replaceArray(
      ['UEFI', 'ReservedMemory'],
      model.uefi.uefiReservedMemory.uefiMemoryItems
          .map((item) => _normalizePlistMap(item.toJson()))
          .toList(),
    ));
  }

  Map<String, dynamic> _kextToPlist(dynamic item) {
    return {
      'Arch': item.arch,
      'BundlePath': item.bundlePath,
      'Comment': item.comment,
      'Enabled': item.enabled,
      'ExecutablePath': item.executablePath,
      'MaxKernel': item.maxKernel,
      'MinKernel': item.minKernel,
      'PlistPath': item.plistPath,
    };
  }

  Map<String, dynamic> _kernelBlockToPlist(dynamic item) {
    return {
      'Arch': item.arch,
      'Comment': item.comment,
      'Enabled': item.enabled,
      'Identifier': item.identifier,
      'MaxKernel': item.maxKernel,
      'MinKernel': item.minKernel,
      'Strategy': item.strategy,
    };
  }

  Map<String, dynamic> _kernelForceToPlist(dynamic item) {
    return {
      'Arch': item.arch,
      'BundlePath': item.bundlePath,
      'Comment': item.comment,
      'Enabled': item.enabled,
      'ExecutablePath': item.executablePath,
      'Identifier': item.identifier,
      'MaxKernel': item.maxKernel,
      'MinKernel': item.minKernel,
      'PlistPath': item.plistPath,
    };
  }

  Map<String, dynamic> _kernelPatchToPlist(dynamic item) {
    return {
      'Arch': item.arch,
      'Base': item.base,
      'Comment': item.comment,
      'Count': item.count,
      'Enabled': item.enabled,
      'Find': _dataValue(item.find),
      'Identifier': item.identifier,
      'Limit': item.limit,
      'Mask': _dataValue(item.mask),
      'MaxKernel': item.maxKernel,
      'MinKernel': item.minKernel,
      'Replace': _dataValue(item.replace),
      'ReplaceMask': _dataValue(item.replaceMask),
      'Skip': item.skip,
    };
  }

  Map<String, dynamic> _acpiDeleteToPlist(dynamic item) {
    return {
      'All': item.all,
      'Comment': item.comment,
      'Enabled': item.enabled,
      'OemTableId': _dataValue(item.oemTableId),
      'TableLength': item.tableLength,
      'TableSignature': _dataValue(item.tableSignature),
    };
  }

  Map<String, dynamic> _acpiPatchToPlist(dynamic item) {
    return {
      'Base': item.base,
      'BaseSkip': item.baseSkip,
      'Comment': item.comment,
      'Count': item.count,
      'Enabled': item.enabled,
      'Find': _dataValue(item.find),
      'Limit': item.limit,
      'Mask': _dataValue(item.mask),
      'OemTableId': _dataValue(item.oemTableId),
      'Replace': _dataValue(item.replace),
      'ReplaceMask': _dataValue(item.replaceMask),
      'Skip': item.skip,
      'TableLength': item.tableLength,
      'TableSignature': _dataValue(item.tableSignature),
    };
  }

  Map<String, dynamic> _booterPatchToPlist(dynamic item) {
    return {
      'Arch': item.arch,
      'Comment': item.comment,
      'Count': item.count,
      'Enabled': item.enabled,
      'Find': _dataValue(item.find),
      'Identifier': item.identifier,
      'Limit': item.limit,
      'Mask': _dataValue(item.mask),
      'Replace': _dataValue(item.replace),
      'ReplaceMask': _dataValue(item.replaceMask),
      'Skip': item.skip,
    };
  }

  Map<String, dynamic> _kernelEmulateToPlist(dynamic item) {
    return {
      'Cpuid1Data': _dataValue(item.cpuid1Data),
      'Cpuid1Mask': _dataValue(item.cpuid1Mask),
      'DummyPowerManagement': item.dummyPowerManagement,
      'MaxKernel': item.maxKernel,
      'MinKernel': item.minKernel,
    };
  }

  Map<String, dynamic> _miscSecurityToPlist(dynamic item) {
    return {
      'AllowSetDefault': item.allowSetDefault,
      'ApECID': item.apECID,
      'AuthRestart': item.authRestart,
      'BlacklistAppleUpdate': item.blacklistAppleUpdate,
      'DmgLoading': item.dmgLoading,
      'EnablePassword': item.enablePassword,
      'ExposeSensitiveData': item.exposeSensitiveData,
      'HaltLevel': item.haltLevel,
      'PasswordHash': _dataValue(item.passwordHash),
      'PasswordSalt': _dataValue(item.passwordSalt),
      'ScanPolicy': item.scanPolicy,
      'SecureBootModel': item.secureBootModel,
      'Vault': item.vault,
    };
  }

  Map<String, dynamic> _platformInfoGenericToPlist(Map source) {
    final result = _normalizePlistMap(source);
    result['ROM'] = _dataValue(source['ROM']);
    return result;
  }

  PlistTypedValue _dataValue(dynamic value) {
    return PlistTypedValue(
      type: 'data',
      value: value ?? Uint8List(0),
    );
  }

  Map<String, dynamic> _normalizePlistMap(Map source) {
    final result = <String, dynamic>{};

    source.forEach((key, value) {
      result[key.toString()] = _normalizePlistValue(value);
    });

    return result;
  }

  dynamic _normalizePlistValue(dynamic value) {
    if (value == null) {
      return '';
    }

    if (value is Uint8List) {
      return PlistTypedValue(
        type: 'data',
        value: value,
      );
    }

    if (value is List<int>) {
      return PlistTypedValue(
        type: 'data',
        value: Uint8List.fromList(value),
      );
    }

    if (value is Map) {
      return _normalizePlistMap(value);
    }

    if (value is List) {
      return value.map(_normalizePlistValue).toList();
    }

    return value;
  }
}
