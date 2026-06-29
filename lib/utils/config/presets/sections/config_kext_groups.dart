import 'package:rapidefi/utils/config/models/kernel/kext_group.dart';
import 'package:rapidefi/utils/config/presets/sections/config_kernel.dart';

class ConfigKextGroups {
  ConfigKextGroups._();

  static final cpuFriend = KextGroup(
    id: 'cpu_friend',
    title: 'CPU变频驱动,这里主要提供11至14代 MacPro7,1变频支持',
    description: '',
    kexts: [
      ConfigKernel.CPUFriend,
      ConfigKernel.CPUFriendDataProvider,
    ],
  );

  static final realtekCardReader = KextGroup(
    id: 'realtek_card_reader',
    title: 'RealtekCardReader',
    description: 'Realtek SD 读卡器及其配套驱动',
    kexts: [
      ConfigKernel.RealtekCardReader,
      ConfigKernel.RealtekCardReaderFriend,
    ],
  );

  static final appleIntelCpuPowerManagement = KextGroup(
    id: 'apple_intel_cpu_power_management',
    title: '修复Intel 3代以及更老平台Ventura 13及以上系统CPU电源管理',
    description: '',
    kexts: [
      ConfigKernel.AppleIntelCPUPowerManagement,
      ConfigKernel.AppleIntelCPUPowerManagementClient,
    ],
  );

  static final applePs2SmartTouchPad = KextGroup(
    id: 'apple_ps2_smart_touchpad',
    title: 'ApplePS2SmartTouchPad',
    description:
        '适用于3代及以下老平台,基于PS/2总线协议连接的输入设备,如键盘、鼠标、触摸板等.能实现一定程度的多点触控功能，但支持有限。',
    kexts: [
      ConfigKernel.ApplePS2SmartTouchPad,
      ConfigKernel.ApplePS2SmartTouchPadApplePS2Controller,
      ConfigKernel.ApplePS2SmartTouchPadApplePS2Keyboard,
    ],
  );

  static final voodooPs2Controller = KextGroup(
    id: 'voodoo_ps2_controller',
    title: 'VoodooPS2Controller',
    description:
        '适用于3代及以上平台,基于PS/2总线协议连接的输入设备,如键盘、鼠标、触摸板等.通过子驱动提供对 PS/2 触摸板的支持，并且能实现一定程度的多点触控功能，但支持有限。',
    kexts: [
      ConfigKernel.VoodooPS2Controller,
      ConfigKernel.VoodooPS2ControllerVoodooInput,
      ConfigKernel.VoodooPS2ControllerVoodooPS2Keyboard,
      ConfigKernel.VoodooPS2ControllerVoodooPS2Mouse,
      ConfigKernel.VoodooPS2ControllerVoodooPS2Trackpad,
    ],
  );

  static final voodooPs2ControllerWithI2c = KextGroup(
    id: 'voodoo_ps2_controller_with_i2c',
    title: 'VoodooPS2Controller + VoodooI2C',
    description:
        'PS2键盘,适用于基于I2C总线协议连接的触摸板、触摸屏、传感器和其他输入设备。提供多点触控手势支持，模拟 macOS 原生的触控体验。',
    kexts: [
      ConfigKernel.VoodooPS2Controller,
      ConfigKernel.VoodooPS2ControllerVoodooPS2Keyboard,
      ConfigKernel.VoodooI2C,
      ConfigKernel.VoodooI2CVoodooInput,
      ConfigKernel.VoodooI2CVoodooI2CServices,
      ConfigKernel.VoodooI2CVoodooGPIO,
      ConfigKernel.VoodooI2CHID,
    ],
  );

  static final voodooPs2ControllerWithRmi = KextGroup(
    id: 'voodoo_ps2_controller_with_rmi',
    title: 'VoodooPS2Controller + VoodooRMI',
    description:
        'PS2键盘,适用于基于RMI4协议总线协议连接的Synaptics触摸板。专注于更好地支持 Synaptics 设备，提供类似 macOS 原生触摸板的多点触控和手势功能。',
    kexts: [
      ConfigKernel.VoodooPS2Controller,
      ConfigKernel.VoodooPS2ControllerVoodooPS2Keyboard,
      ConfigKernel.VoodooPS2ControllerVoodooPS2Mouse,
      ConfigKernel.VoodooPS2ControllerVoodooPS2Trackpad,
      ConfigKernel.VoodooRMI,
      ConfigKernel.VoodooRMIVoodooInput,
      ConfigKernel.VoodooSMBus,
      ConfigKernel.VoodooRMIRMISMBus,
    ],
  );

  static final voodooPs2ControllerWithRmiI2c = KextGroup(
    id: 'voodoo_ps2_controller_with_rmi_i2c',
    title: 'VoodooPS2Controller + VoodooRMII2C + VoodooI2C',
    description:
        'PS2键盘,适用于基于I2C总线的触摸设备和使用RMI4协议的Synaptics触摸板。RMII2C结合 VoodooI2C 和 VoodooRMI 的优势。',
    kexts: [
      ConfigKernel.VoodooPS2Controller,
      ConfigKernel.VoodooPS2ControllerVoodooPS2Keyboard,
      ConfigKernel.VoodooPS2ControllerVoodooPS2Mouse,
      ConfigKernel.VoodooPS2ControllerVoodooPS2Trackpad,
      ConfigKernel.VoodooRMI,
      ConfigKernel.VoodooRMIVoodooInput,
      ConfigKernel.VoodooI2C,
      ConfigKernel.VoodooRMIRMII2C,
    ],
  );

  static final voodooPS2KeyboardAndMouse = KextGroup(
    id: 'voodoo_ps2_keyboard_and_mouse',
    title: 'VoodooPS2KeyboardAndMouse',
    description: '基于PS/2总线协议连接的圆口键盘、鼠标驱动',
    kexts: [
      ConfigKernel.VoodooPS2Controller,
      ConfigKernel.VoodooPS2ControllerVoodooPS2Keyboard,
      ConfigKernel.VoodooPS2ControllerVoodooPS2Mouse,
    ],
  );

  static final bigSurface = KextGroup(
    id: 'big_surface',
    title: 'BigSurface',
    description: 'Microsoft Surface 专用键盘、触摸板、触摸屏驱动组合。',
    kexts: [
      ConfigKernel.BigSurfaceVoodooGPIO,
      ConfigKernel.BigSurfaceVoodooSerial,
      ConfigKernel.BigSurfaceVoodooInput,
      ConfigKernel.BigSurface,
      ConfigKernel.BigSurfaceHIDDriver,
    ],
  );

  static final brcm94360 = KextGroup(
    id: 'brcm94360',
    title: '博通BCM94360免驱系列',
    description:
        'Apple AirPort和Fenvi免驱卡,Ventura及以下免驱,补丁支持Sonoma 14及Sequoia 15! 注意:Sonoma 14及以上系统需要使用OCLP打补丁方可正常使用！！！',
    kexts: [
      ConfigKernel.IOSkywalkFamily,
      ConfigKernel.IO80211FamilyLegacy,
      ConfigKernel.IO80211FamilyLegacyAirPortBrcmNIC,
    ],
  );

  static final brcm943xx = KextGroup(
    id: 'brcm943xx',
    title: '博通BCM943XX非免驱系列',
    description:
        'Apple AirPort和Fenvi以外的卡,Catalina及以下免驱,补丁支持Sonoma 14及Sequoia 15! 注意:Sonoma 14及以上系统需要使用OCLP打补丁方可正常使用！！！',
    kexts: [
      ConfigKernel.IOSkywalkFamily,
      ConfigKernel.IO80211FamilyLegacy,
      ConfigKernel.IO80211FamilyLegacyAirPortBrcmNIC,
      ConfigKernel.AirportBrcmFixup,
      ConfigKernel.AirportBrcmFixupAirPortBrcm4360_Injector,
      ConfigKernel.AirportBrcmFixupAirPortBrcmNIC_Injector,
    ],
  );

  static final brcm4331 = KextGroup(
    id: 'brcm4331',
    title: '老款博通BCM4331',
    description: '注意Monterey 12以上系统需要使用OCLP补丁后方可正常使用！！！',
    kexts: [
      ConfigKernel.corecaptureElCap,
      ConfigKernel.IO80211ElCap,
      ConfigKernel.IO80211ElCap_AirPortBrcm4331,
    ],
  );

  static final brcm43224 = KextGroup(
    id: 'brcm43224',
    title: '老款博通BCM43224',
    description: '注意Monterey 12以上系统需要使用OCLP补丁后方可正常使用！！！',
    kexts: [
      ConfigKernel.corecaptureElCap,
      ConfigKernel.IO80211ElCap,
      ConfigKernel.IO80211ElCap_AppleAirPortBrcm43224,
    ],
  );

  static final atherosWifiModels = KextGroup(
    id: 'atheros_wifi_models',
    title: '高通(Atheros) WiFi 型号驱动',
    description: '高通 WiFi 手动选择项',
    kexts: [
      ConfigKernel.AirPortAtheros40_9285,
      ConfigKernel.AirPortAtheros40_9380,
      ConfigKernel.AirPortAtheros40_9485,
      ConfigKernel.AirPortAtheros40_9565,
      ConfigKernel.AirPortAtheros40_9462,
      ConfigKernel.AirPortAtheros40_9463,
    ],
  );

  static final atherosWifiLegacySupport = KextGroup(
    id: 'atheros_wifi_legacy_support',
    title: '高通(Atheros) WiFi Big Sur 及以下依赖',
    description: 'macOS Big Sur 11 及以下系统使用 HS80211Family 配合具体型号驱动',
    kexts: [
      ConfigKernel.HS80211Family,
    ],
  );

  static final atherosWifiModernSupport = KextGroup(
    id: 'atheros_wifi_modern_support',
    title: '高通(Atheros) WiFi Monterey 及以上依赖',
    description: 'macOS Monterey 12 及以上系统使用 IO80211ElCap 组合',
    kexts: [
      ConfigKernel.corecaptureElCap,
      ConfigKernel.IO80211ElCap,
      ConfigKernel.IO80211ElCap_AirPortAtheros40,
    ],
  );

  static final optionalGroups = [
    cpuFriend,
    realtekCardReader,
    appleIntelCpuPowerManagement,
  ];

  static final touchPadGroups = [
    applePs2SmartTouchPad,
    voodooPs2Controller,
    voodooPs2ControllerWithI2c,
    voodooPs2ControllerWithRmi,
    voodooPs2ControllerWithRmiI2c,
    bigSurface,
  ];

  static final brcmWifiGroups = [
    brcm94360,
    brcm943xx,
    brcm4331,
    brcm43224,
  ];

  static final atherosWifiGroups = [
    atherosWifiModels,
    atherosWifiLegacySupport,
    atherosWifiModernSupport,
  ];

  static final requiredTogetherGroups = [
    ...optionalGroups,
    ...touchPadGroups,
    ...brcmWifiGroups,
    atherosWifiLegacySupport,
    atherosWifiModernSupport,
  ];
}
