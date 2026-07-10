import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rapidefi/pages/manual/manual_config_controller.dart';
import 'package:rapidefi/pages/manual/widgets/platform/motherboard_selector.dart';
import 'package:rapidefi/utils/config/models/acpi/acpi_add_item.dart';
import 'package:rapidefi/utils/config/models/kernel/kernel_kext.dart';
import 'package:rapidefi/utils/config/models/kernel/kernel_patch_item.dart';
import 'package:rapidefi/utils/config/models/motherboard/mbconf_model.dart';
import 'package:rapidefi/utils/config/models/nvram/nvram_add_item.dart';
import 'package:rapidefi/utils/config/accessors/device_properties_accessor.dart';

/// 主板配置选择区块 — 连接 ManualConfigController
class MotherboardSectionView extends StatelessWidget {
  const MotherboardSectionView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<ManualConfigController>();
    return MotherboardSelectorWidget(
      onApply: (selected) => _applyItems(context, controller, selected),
    );
  }

  void _applyItems(
    BuildContext context,
    ManualConfigController controller,
    List<MbConfSelectableItem> items,
  ) {
    controller.update((editor) {
      final model = editor.configModel;

      for (final item in items) {
        switch (item.category) {
          // ── ACPI.Add ──────────────────────────────────────────
          case MbItemCategory.acpiAdd:
            final filename = item.data as String;
            final exists = model.acpi.acpiAddItems
                .any((a) => a.path == filename);
            if (!exists) {
              model.acpi.acpiAddItems = [
                ...model.acpi.acpiAddItems,
                AcpiAddItem(
                  path: filename,
                  enabled: true,
                  comment: filename.replaceAll('.aml', ''),
                ),
              ];
            }

          // ── Kernel.Add ────────────────────────────────────────
          case MbItemCategory.kextAdd:
            final bundlePath = item.data as String;
            final exists = model.kernel.kernelKexts
                .any((k) => k.bundlePath == bundlePath);
            if (!exists) {
              model.kernel.kernelKexts = [
                ...model.kernel.kernelKexts,
                KernelKext(
                  bundlePath: bundlePath,
                  executablePath: 'Contents/MacOS/${bundlePath.replaceAll('.kext', '')}',
                  plistPath: 'Contents/Info.plist',
                  enabled: true,
                  comment: '来自 mbconfs',
                  arch: 'Any',
                ),
              ];
            }

          // ── Kernel.Patch ──────────────────────────────────────
          case MbItemCategory.kernelPatch:
            final p = item.data as MbKernelPatch;
            model.kernel.kernelPatchItems = [
              ...(model.kernel.kernelPatchItems ?? []),
              KernelPatchItem(
                arch: p.arch,
                base: p.base,
                comment: p.comment,
                count: p.count,
                enabled: p.enabled,
                find: p.find,
                identifier: p.identifier,
                limit: p.limit,
                mask: p.mask,
                maxKernel: p.maxKernel,
                minKernel: p.minKernel,
                replace: p.replace,
                replaceMask: p.replaceMask,
                skip: p.skip,
              ),
            ];

          // ── Kernel.Quirks ─────────────────────────────────────
          case MbItemCategory.kernelQuirk:
            final q = item.data as MbQuirkEntry;
            _applyKernelQuirk(model, q);

          // ── Booter.Quirks ─────────────────────────────────────
          case MbItemCategory.booterQuirk:
            final q = item.data as MbQuirkEntry;
            _applyBooterQuirk(model, q);

          // ── DeviceProperties ──────────────────────────────────
          case MbItemCategory.dpPath:
            final dp = item.data as MbDpPath;
            for (final prop in dp.properties) {
              DevicePropertiesAccessor.setProperty(model, dp.pciPath, prop);
            }

          // ── Misc.Boot ─────────────────────────────────────────
          case MbItemCategory.miscBoot:
            final e = item.data as MbMiscEntry;
            _applyMiscBoot(model, e);

          // ── Misc.Security ─────────────────────────────────────
          case MbItemCategory.miscSecurity:
            final e = item.data as MbMiscEntry;
            _applyMiscSecurity(model, e);

          // ── NVRAM ─────────────────────────────────────────────
          case MbItemCategory.nvramGuid:
            final n = item.data as MbNvramGuid;
            _applyNvram(model, n);

          // ── PlatformInfo ──────────────────────────────────────
          case MbItemCategory.platformInfo:
            final pi = item.data as MbPlatformInfoData;
            _applyPlatformInfo(model, pi);

          // ── UEFI.Quirks ───────────────────────────────────────
          case MbItemCategory.uefiQuirk:
            final q = item.data as MbQuirkEntry;
            _applyUefiQuirk(model, q);
        }
      }
    });
  }

  // ────────────────────────────────────────────────────────────────
  // Kernel.Quirks 字段映射（JSON PascalCase → Dart camelCase）
  // ────────────────────────────────────────────────────────────────
  void _applyKernelQuirk(dynamic model, MbQuirkEntry q) {
    final kq = model.kernel.kernelQuirks;
    final v = q.value;
    switch (q.jsonKey) {
      case 'AppleCpuPmCfgLock':       kq.appleCpuPmCfgLock       = v as bool; break;
      case 'AppleXcpmCfgLock':        kq.appleXcpmCfgLock        = v as bool; break;
      case 'AppleXcpmExtraMsrs':      kq.appleXcpmExtraMsrs      = v as bool; break;
      case 'AppleXcpmForceBoost':     kq.appleXcpmForceBoost     = v as bool; break;
      case 'CustomSMBIOSGuid':        kq.customSMBIOSGuid        = v as bool; break;
      case 'CustomPciSerialDevice':   kq.customPciSerialDevice   = v as bool; break;
      case 'DisableIoMapper':         kq.disableIoMapper         = v as bool; break;
      case 'DisableIoMapperMapping':  kq.disableIoMapperMapping  = v as bool; break;
      case 'DisableLinkeditJettison': kq.disableLinkeditJettison = v as bool; break;
      case 'DisableRtcChecksum':      kq.disableRtcChecksum      = v as bool; break;
      case 'ExtendBTFeatureFlags':    kq.extendBTFeatureFlags    = v as bool; break;
      case 'ExternalDiskIcons':       kq.externalDiskIcons       = v as bool; break;
      case 'ForceAquantiaEthernet':   kq.forceAquantiaEthernet   = v as bool; break;
      case 'ForceSecureBootScheme':   kq.forceSecureBootScheme   = v as bool; break;
      case 'IncreasePciBarSize':      kq.increasePciBarSize      = v as bool; break;
      case 'LapicKernelPanic':        kq.lapicKernelPanic        = v as bool; break;
      case 'LegacyCommpage':          kq.legacyCommpage          = v as bool; break;
      case 'PanicNoKextDump':         kq.panicNoKextDump         = v as bool; break;
      case 'PowerTimeoutKernelPanic': kq.powerTimeoutKernelPanic = v as bool; break;
      case 'ProvideCurrentCpuInfo':   kq.provideCurrentCpuInfo   = v as bool; break;
      case 'SetApfsTrimTimeout':      kq.setApfsTrimTimeout      = (v as num).toInt(); break;
      case 'ThirdPartyDrives':        kq.thirdPartyDrives        = v as bool; break;
      case 'XhciPortLimit':           kq.xhciPortLimit           = v as bool; break;
    }
  }

  // ────────────────────────────────────────────────────────────────
  // Booter.Quirks
  // ────────────────────────────────────────────────────────────────
  void _applyBooterQuirk(dynamic model, MbQuirkEntry q) {
    final bq = model.booter.booterQuirks;
    final v = q.value;
    switch (q.jsonKey) {
      case 'AllowRelocationBlock':   bq.allowRelocationBlock   = v as bool; break;
      case 'AvoidRuntimeDefrag':     bq.avoidRuntimeDefrag     = v as bool; break;
      case 'ClearTaskSwitchBit':     bq.clearTaskSwitchBit     = v as bool; break;
      case 'DevirtualiseMmio':       bq.devirtualiseMmio       = v as bool; break;
      case 'DisableSingleUser':      bq.disableSingleUser      = v as bool; break;
      case 'DisableVariableWrite':   bq.disableVariableWrite   = v as bool; break;
      case 'DiscardHibernateMap':    bq.discardHibernateMap    = v as bool; break;
      case 'EnableSafeModeSlide':    bq.enableSafeModeSlide    = v as bool; break;
      case 'EnableWriteUnprotector': bq.enableWriteUnprotector = v as bool; break;
      case 'FixupAppleEfiImages':    bq.fixupAppleEfiImages    = v as bool; break;
      case 'ForceBooterSignature':   bq.forceBooterSignature   = v as bool; break;
      case 'ForceExitBootServices':  bq.forceExitBootServices  = v as bool; break;
      case 'ProtectMemoryRegions':   bq.protectMemoryRegions   = v as bool; break;
      case 'ProtectSecureBoot':      bq.protectSecureBoot      = v as bool; break;
      case 'ProtectUefiServices':    bq.protectUefiServices    = v as bool; break;
      case 'ProvideCustomSlide':     bq.provideCustomSlide     = v as bool; break;
      case 'ProvideMaxSlide':        bq.provideMaxSlide        = (v as num).toInt(); break;
      case 'RebuildAppleMemoryMap':  bq.rebuildAppleMemoryMap  = v as bool; break;
      case 'ResizeAppleGpuBars':     bq.resizeAppleGpuBars     = (v as num).toInt(); break;
      case 'SetupVirtualMap':        bq.setupVirtualMap        = v as bool; break;
      case 'SignalAppleOS':          bq.signalAppleOS          = v as bool; break;
      case 'SyncRuntimePermissions': bq.syncRuntimePermissions = v as bool; break;
    }
  }

  // ────────────────────────────────────────────────────────────────
  // UEFI.Quirks
  // ────────────────────────────────────────────────────────────────
  void _applyUefiQuirk(dynamic model, MbQuirkEntry q) {
    final uq = model.uefi.uefiQuirks;
    final v = q.value;
    switch (q.jsonKey) {
      case 'ActivateHpetSupport':      uq.activateHpetSupport      = v as bool; break;
      case 'DisableSecurityPolicy':    uq.disableSecurityPolicy    = v as bool; break;
      case 'EnableVectorAcceleration': uq.enableVectorAcceleration = v as bool; break;
      case 'EnableVmx':                uq.enableVmx                = v as bool; break;
      case 'ExitBootServicesDelay':    uq.exitBootServicesDelay    = (v as num).toInt(); break;
      case 'ForceOcWriteFlash':        uq.forceOcWriteFlash        = v as bool; break;
      case 'ForgeUefiSupport':         uq.forgeUefiSupport         = v as bool; break;
      case 'IgnoreInvalidFlexRatio':   uq.ignoreInvalidFlexRatio   = v as bool; break;
      case 'ReleaseUsbOwnership':      uq.releaseUsbOwnership      = v as bool; break;
      case 'ReloadOptionRoms':         uq.reloadOptionRoms         = v as bool; break;
      case 'RequestBootVarRouting':    uq.requestBootVarRouting    = v as bool; break;
      case 'ResizeGpuBars':            uq.resizeGpuBars            = (v as num).toInt(); break;
      case 'ResizeUsePciRbIo':         uq.resizeUsePciRbIo         = v as bool; break;
      case 'ShimRetainProtocol':       uq.shimRetainProtocol       = v as bool; break;
      case 'TscSyncTimeout':           uq.tscSyncTimeout           = (v as num).toInt(); break;
      case 'UnblockFsConnect':         uq.unblockFsConnect         = v as bool; break;
    }
  }

  // ────────────────────────────────────────────────────────────────
  // Misc.Boot
  // ────────────────────────────────────────────────────────────────
  void _applyMiscBoot(dynamic model, MbMiscEntry e) {
    final mb = model.misc.miscBoot;
    final v = e.value;
    switch (e.key) {
      case 'HibernateMode':       mb.hibernateMode       = v.toString(); break;
      case 'HibernateSkipsPicker':mb.hibernateSkipsPicker= v as bool; break;
      case 'HideAuxiliary':       mb.hideAuxiliary       = v as bool; break;
      case 'PickerMode':          mb.pickerMode          = v.toString(); break;
      case 'ShowPicker':          mb.showPicker          = v as bool; break;
      case 'Timeout':             mb.timeout             = (v as num).toInt(); break;
      case 'TakeoffDelay':        mb.takeoffDelay        = (v as num).toInt(); break;
      case 'PollAppleHotKeys':    mb.pollAppleHotKeys    = v as bool; break;
      case 'PickerAudioAssist':   mb.pickerAudioAssist   = v as bool; break;
      case 'PickerAttributes':    mb.pickerAttributes    = (v as num).toInt(); break;
      case 'LauncherOption':      mb.launcherOption      = v.toString(); break;
      case 'LauncherPath':        mb.launcherPath        = v.toString(); break;
    }
  }

  // ────────────────────────────────────────────────────────────────
  // Misc.Security
  // ────────────────────────────────────────────────────────────────
  void _applyMiscSecurity(dynamic model, MbMiscEntry e) {
    final ms = model.misc.miscSecurity;
    final v = e.value;
    switch (e.key) {
      case 'AllowSetDefault':       ms.allowSetDefault       = v as bool; break;
      case 'AuthRestart':           ms.authRestart           = v as bool; break;
      case 'BlacklistAppleUpdate':  ms.blacklistAppleUpdate  = v as bool; break;
      case 'DmgLoading':            ms.dmgLoading            = v.toString(); break;
      case 'EnablePassword':        ms.enablePassword        = v as bool; break;
      case 'ExposeSensitiveData':   ms.exposeSensitiveData   = (v as num).toInt(); break;
      case 'HaltLevel':             ms.haltLevel             = (v as num).toInt(); break;
      case 'ScanPolicy':            ms.scanPolicy            = (v as num).toInt(); break;
      case 'SecureBootModel':       ms.secureBootModel       = v.toString(); break;
      case 'Vault':                 ms.vault                 = v.toString(); break;
    }
  }

  // ────────────────────────────────────────────────────────────────
  // NVRAM：将 JSON 值转为 NvramAddItem 写入对应 GUID
  // ────────────────────────────────────────────────────────────────
  void _applyNvram(dynamic model, MbNvramGuid n) {
    final nvramAdd = model.nvram.nvramAdd;
    nvramAdd.addList ??= {};
    final existing =
        List<NvramAddItem>.from(nvramAdd.addList![n.guid] ?? []);

    for (final kv in n.entries.entries) {
      final key = kv.key;
      final val = kv.value;

      // 判断数据类型
      final String dataType;
      final String strValue;
      if (val is int) {
        dataType = 'number';
        strValue = val.toString();
      } else if (val is bool) {
        dataType = 'boolean';
        strValue = val.toString();
      } else {
        final s = val.toString();
        // 全 hex 字符串 → data
        final isHex = RegExp(r'^[0-9A-Fa-f]+$').hasMatch(s);
        dataType = isHex ? 'data' : 'string';
        strValue = s;
      }

      final idx = existing.indexWhere((i) => i.key == key);
      final newItem = NvramAddItem(
        key: key,
        dataType: dataType,
        value: strValue,
        comment: '来自 mbconfs',
      );
      if (idx == -1) {
        existing.add(newItem);
      } else {
        existing[idx] = newItem;
      }
    }

    nvramAdd.addList![n.guid] = existing;
  }

  // ────────────────────────────────────────────────────────────────
  // PlatformInfo
  // ────────────────────────────────────────────────────────────────
  void _applyPlatformInfo(dynamic model, MbPlatformInfoData pi) {
    final platformInfo = model.platformInfo;
    if (pi.automatic != null) platformInfo.automatic = pi.automatic!;
    if (pi.updateSMBIOSMode != null) {
      platformInfo.updateSMBIOSMode = pi.updateSMBIOSMode!;
    }
    if (pi.updateDataHub != null) platformInfo.updateDataHub = pi.updateDataHub!;
    if (pi.updateNVRAM != null)    platformInfo.updateNVRAM   = pi.updateNVRAM!;
    if (pi.updateSMBIOS != null)   platformInfo.updateSMBIOS  = pi.updateSMBIOS!;
    if (pi.useRawUuidEncoding != null) {
      platformInfo.useRawUuidEncoding = pi.useRawUuidEncoding!;
    }
    if (pi.customMemory != null) platformInfo.customMemory = pi.customMemory!;
    // generic (SMBIOS) 字段保留给用户自行选择，此处不覆盖
  }
}
