import 'package:rapidefi/extension/string_extension.dart';
import 'package:rapidefi/utils/config/models/acpi/acpi.dart';
import 'package:rapidefi/utils/config/models/acpi/acpi_add_item.dart';
import 'package:rapidefi/utils/config/models/acpi/acpi_quirks.dart';
import 'package:rapidefi/utils/config/models/booter/booter.dart';
import 'package:rapidefi/utils/config/models/booter/booter_mmio_item.dart';
import 'package:rapidefi/utils/config/models/booter/booter_patch_item.dart';
import 'package:rapidefi/utils/config/models/booter/booter_quirks.dart';
import 'package:rapidefi/utils/config/models/device_properties/device_properties.dart';
import 'package:rapidefi/utils/config/models/device_properties/device_property_item.dart';
import 'package:rapidefi/utils/config/models/device_properties/igpu_model.dart';
import 'package:rapidefi/utils/config/models/enums/brand_enum.dart';
import 'package:rapidefi/utils/config/models/enums/cpu_type_enum.dart';
import 'package:rapidefi/utils/config/models/enums/motherboard_enum.dart';
import 'package:rapidefi/utils/config/models/enums/platform_type_enum.dart';
import 'package:rapidefi/utils/config/models/kernel/kernel.dart';
import 'package:rapidefi/utils/config/models/kernel/kernel_emulate.dart';
import 'package:rapidefi/utils/config/models/kernel/kernel_kext.dart';
import 'package:rapidefi/utils/config/models/kernel/kernel_quirks.dart';
import 'package:rapidefi/utils/config/models/kernel/kernel_scheme.dart';
import 'package:rapidefi/utils/config/models/misc/misc.dart';
import 'package:rapidefi/utils/config/models/misc/misc_boot.dart';
import 'package:rapidefi/utils/config/models/misc/misc_debug.dart';
import 'package:rapidefi/utils/config/models/misc/misc_security.dart';
import 'package:rapidefi/utils/config/models/misc/misc_tools_item.dart';
import 'package:rapidefi/utils/config/models/nvram/nvram.dart';
import 'package:rapidefi/utils/config/models/nvram/nvram_add.dart';
import 'package:rapidefi/utils/config/models/nvram/nvram_add_item.dart';
import 'package:rapidefi/utils/config/models/nvram/nvram_delete.dart';
import 'package:rapidefi/utils/config/models/platform_info/pi.dart';
import 'package:rapidefi/utils/config/models/platform_info/pi_generic.dart';
import 'package:rapidefi/utils/config/models/uefi/uefi.dart';
import 'package:rapidefi/utils/config/models/uefi/uefi_apfs.dart';
import 'package:rapidefi/utils/config/models/uefi/uefi_appleinput.dart';
import 'package:rapidefi/utils/config/models/uefi/uefi_audio.dart';
import 'package:rapidefi/utils/config/models/uefi/uefi_drivers_item.dart';
import 'package:rapidefi/utils/config/models/uefi/uefi_input.dart';
import 'package:rapidefi/utils/config/models/uefi/uefi_output.dart';
import 'package:rapidefi/utils/config/models/uefi/uefi_protocol_overrides.dart';
import 'package:rapidefi/utils/config/models/uefi/uefi_quirks.dart';
import 'package:rapidefi/utils/config/models/uefi/uefi_reserved_memory.dart';
import 'package:rapidefi/utils/config/presets/patches/acpi_patch.dart';
import 'package:rapidefi/utils/config/presets/patches/kernel_patch.dart';
import 'package:rapidefi/utils/config/presets/patches/uefi_memory_patch.dart';
import 'package:rapidefi/utils/config/presets/sections/config_nvram.dart';
import '../../config_model.dart';

ConfigModel intel_ = ConfigModel()
  ..cpuType = CpuType.intel
  ..platformType = PlatformType.laptop
  ..pentiumOrCeleron = false
  ..macOSVersion = 'Ventura 13'
  ..legacy = false
  ..brand = Brand.gigabyte
  ..specialMotherboard = SpecialMotherboard.intelS6
  ..acpi = Acpi(acpiAddItems: [
    AcpiAddItem(comment: 'fix', enabled: true, path: 'SSDT-XOSI.aml'),
    AcpiAddItem(comment: 'fix sleep', enabled: false, path: 'SSDT-GRPW.aml'),
    AcpiAddItem(comment: 'fix AppleALC', enabled: true, path: 'SSDT-HPET.aml'),
    AcpiAddItem(comment: 'fix I2C', enabled: false, path: 'SSDT-GPIO.aml'),
  ], acpiPatchItems: [
    AcpiPatch.rtcFixHPPostError,
    AcpiPatch.osiToXOSI,
  ], acpiDeleteItems: [
    AcpiPatch.deleteCpuPm,
    AcpiPatch.deleteCpu0Ist
  ], acpiQuirks: AcpiQuirks(fadtEnableReset: true))
  ..booter = Booter(
      booterMmioWhitelistItems: [
        BooterMmioWhitelistItem(
            comment: 'fix mmio1', enabled: true, address: 4278190080),
        BooterMmioWhitelistItem(
            comment: 'fix mmio2', enabled: true, address: 4278192080)
      ],
      booterPatchItems: [
        BooterPatchItem(
            arch: 'Any',
            comment: 'macOS toto hacOS',
            count: 1,
            enabled: true,
            find: '6D61634F53'.toBytes(),
            identifier: 'Apple',
            limit: 0,
            mask: ''.toBytes(),
            replace: '6861634F53'.toBytes(),
            replaceMask: ''.toBytes(),
            skip: 0)
      ],
      booterQuirks: BooterQuirks(
          avoidRuntimeDefrag: true,
          devirtualiseMmio: true,
          setupVirtualMap: true,
          provideCustomSlide: true,
          rebuildAppleMemoryMap: true,
          provideMaxSlide: 10,
          resizeAppleGpuBars: 0))
  ..deviceProperties = DeviceProperties(addList: [
    IgpuPropertyModel(pciPath: "PciRoot(0x0)/Pci(0x2,0x0)", propertyItems: [
      DevicePropertyItem(
          key: 'AAPL,ig-platform-id',
          dataType: 'data',
          value: '0300220D',
          comment: '测试'),
      DevicePropertyItem(
          key: 'device-id', dataType: 'data', value: '12040000', comment: '测试'),
    ]),
    IgpuPropertyModel(pciPath: "PciRoot(0x0)/Pci(0x1B,0x0)", propertyItems: [
      DevicePropertyItem(
          key: 'layout-id', dataType: 'integer', value: '1', comment: '测试'),
    ])
  ])
  ..kernel = Kernel(
      kernelKexts: [
        KernelKext(
            bundlePath: 'Lilu.kext',
            comment: 'base',
            enabled: true,
            executablePath: 'Contents/MacOS/Lilu',
            plistPath: 'Contents/Info.plist',
            minKernel: '8.0.0',
            maxKernel: '23.99.99',
            arch: 'Any'),
        KernelKext(
            bundlePath: 'VirtualSMC.kext',
            comment: 'base',
            enabled: false,
            executablePath: 'Contents/MacOS/VirtualSMC',
            plistPath: 'Contents/Info.plist',
            minKernel: '8.0.0',
            maxKernel: '23.99.99',
            arch: 'Any')
      ],
      kernelBlockItems: [
        KernelPatch.fixBrcmWiFiForSonoma,
      ],
      kernelForceItems: [
        KernelPatch.forceIO80211FamilyToLoad
      ],
      kernelPatchItems: [
        KernelPatch.fixRTCWakeScheduling,
        KernelPatch.fixBroadcomBCM57785
      ],
      kernelEmulate: KernelEmulate(
        cpuid1Data: '55 06 0A 00 00 00 00 00 00 00 00 00 00 00 00 00'.toBytes(),
        cpuid1Mask: 'FF FF FF FF 00 00 00 00 00 00 00 00 00 00 00 00'.toBytes(),
        dummyPowerManagement: true,
        maxKernel: '25.99.99',
        minKernel: '19.0.0',
      ),
      kernelQuirks: KernelQuirks(
          disableLinkeditJettison: true,
          xhciPortLimit: true,
          appleXcpmCfgLock: true,
          setApfsTrimTimeout: 0),
      kernelScheme: KernelScheme(
          customKernel: true,
          fuzzyMatch: false,
          kernelArch: 'x86_64',
          kernelCache: 'Auto'))
  ..misc = Misc(
      miscBoot: MiscBoot(
          hideAuxiliary: false,
          pollAppleHotKeys: true,
          showPicker: false,
          hibernateSkipsPicker: true,
          pickerAttributes: 145,
          hibernateMode: 'RTC',
          launcherOption: 'Full',
          launcherPath: 'Custom',
          pickerMode: 'External',
          pickerVariant: 'Default',
          takeoffDelay: 5,
          timeout: 10,
          consoleAttributes: 0,
          instanceIdentifier: 'Test'),
      miscDebug: MiscDebug(
          appleDebug: true,
          applePanic: true,
          disableWatchDog: true,
          sysReport: true,
          displayDelay: 5,
          displayLevel: 2147483650,
          target: 64,
          logModules: 'Test'),
      miscSecurity: MiscSecurity(
          authRestart: true,
          allowSetDefault: true,
          blacklistAppleUpdate: true,
          enablePassword: true,
          secureBootModel: 'Disabled',
          scanPolicy: 0,
          exposeSensitiveData: 7,
          haltLevel: 10,
          apECID: 7,
          passwordHash: '011111111111'.toBytes(),
          passwordSalt: '122423423234'.toBytes(),
          vault: 'Basic'),
      miscToolsItems: [
        MiscToolsItem(
            name: 'UEFI Shell-xxx',
            path: 'OpenShell.efi',
            arguments: 'agr',
            auxiliary: true,
            comment: 'uefi shell',
            enabled: false,
            flavour: 'OpenShell:UEFIShell:Shell--xxx',
            fullNvramAccess: true,
            realPath: true,
            textMode: true),
        MiscToolsItem(
            name: 'ControlMsrE2',
            path: 'ControlMsrE2.efi',
            arguments: '',
            auxiliary: true,
            comment: 'uefi shell',
            enabled: true,
            flavour: 'Auto',
            fullNvramAccess: true,
            realPath: true,
            textMode: true)
      ])
  ..nvram = NVRAM(
      legacyOverwrite: true,
      writeFlash: false,
      nvramAdd: NvramAdd(addList: {
        '4D1EDE05-38C7-4A6A-9CC6-4BCCA8B38C14': [
          NvramAddItem(
              key: 'DefaultBackgroundColor',
              dataType: 'data',
              value: '01000000',
              comment: 'nvram测试'),
          NvramAddItem(
              key: 'UIScale',
              dataType: 'data',
              value: '02',
              comment: 'nvram测试'),
        ],
        '4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102': [
          NvramAddItem(
              key: 'rtc-blacklist',
              dataType: 'data',
              value: '01000000',
              comment: 'nvram测试'),
        ],
        '7C436110-AB2A-4BBB-A880-FE41995C9F82': [
          NvramAddItem(
              key: 'boot-args',
              dataType: 'string',
              value: '-v keepsyms=1 debug=0x100 alcid=1',
              comment: 'nvram测试'),
          NvramAddItem(
              key: 'prev-lang:kbd',
              dataType: 'string',
              value: 'zh-Hans:252',
              comment: 'nvram测试'),
        ]
      }),
      nvramDelete: NvramDelete(deleteList: ConfigNvram.createDeleteList()))
  ..platformInfo = PlatformInfo(
      automatic: false,
      customMemory: true,
      updateSMBIOSMode: 'Custom',
      generic: PlatformInfoGeneric(
          spoofVendor: false,
          maxBIOSVersion: true,
          adviseFeatures: true,
          systemProductName: 'iMac20,1',
          systemSerialNumber: 'C02GH02QPN5T',
          mlb: 'C02140306GUPHC1AD',
          systemUUID: '2F8B0E52-512F-4AE9-B88F-E477FB9F367B',
          rom: '666666666666'.toBytes(),
          systemMemoryStatus: 'Test',
          processorType: 3841))
  ..uefi = Uefi(
      uefiApfs: UefiApfs(
        minDate: -1,
        minVersion: -1,
      ),
      uefiAppleInput: UefiAppleInput(
          graphicsInputMirroring: false,
          customDelays: true,
          appleEvent: 'Auto',
          keyInitialDelay: 10,
          keySubsequentDelay: 8,
          pointerPollMask: 0,
          pointerPollMax: 100,
          pointerPollMin: 0,
          pointerSpeedDiv: 2,
          pointerSpeedMul: 2,
          pointerDwellClickTimeout: 5,
          pointerDwellDoubleClickTimeout: 5,
          pointerDwellRadius: 5),
      uefiAudio: UefiAudio(setupDelay: 10, audioCodec: 11),
      uefiDriversItems: [
        UefiDriversItem(path: 'OpenRuntime.efi'),
        UefiDriversItem(path: 'HfsPlus.efi'),
        UefiDriversItem(path: 'OpenCanopy.efi'),
        UefiDriversItem(path: 'ResetNvramEntry.efi', enabled: false)
      ],
      uefiInput: UefiInput(),
      uefiOutput: UefiOutput(initialMode: 'Auto', consoleMode: 'Max'),
      uefiProtocolOverrides: UefiProtocolOverrides(),
      uefiQuirks: UefiQuirks(
          ignoreInvalidFlexRatio: true,
          releaseUsbOwnership: true,
          unblockFsConnect: true,
          resizeGpuBars: 0,
          tscSyncTimeout: 6),
      uefiReservedMemory: UefiReservedMemory(uefiMemoryItems: [
        UefiMemoryPatch.fixHD3000IGPUmemory,
        UefiMemoryPatch.fixBlackScreenForLenovoT490,
      ]));
