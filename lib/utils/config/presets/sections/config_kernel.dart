// ignore_for_file: non_constant_identifier_names

import 'package:rapidefi/extension/string_extension.dart';
import 'package:rapidefi/utils/config/models/kernel/kernel_trim.dart';
import '../../models/kernel/kernel_emulate.dart';
import '../../models/kernel/kernel_kext.dart';
import '../../models/kernel/kernel_quirks.dart';

class ConfigKernel {
  static KernelKext Lilu = KernelKext(
      bundlePath: 'Lilu.kext',
      executablePath: 'Contents/MacOS/Lilu',
      plistPath: 'Contents/Info.plist',
      minKernel: '',
      maxKernel: '',
      name: 'Lilu',
      url: 'https://github.com/acidanthera/Lilu',
      function: '一个macOS内核扩展必备驱动,主要为macOS提供扩展性和兼容性,这使得其他开发者可以编写用于扩展macOS的内核扩展',
      note: [
        "例如 WhateverGreen、AppleALC、VirtualSMC等可以通过Lilu.kext实现对macOS的各种修改和增强功能,例如支持不同的显卡、声卡、虚拟机管理等",
        "Lilu.kext通常是macOS内核扩展的第一个加载,因为其他插件可能需要依赖它的功能。这确保了插件在macOS启动时能够正确加载",
        "必备基础驱动"
      ]);

  static KernelKext VirtualSMC = KernelKext(
      bundlePath: 'VirtualSMC.kext',
      executablePath: 'Contents/MacOS/VirtualSMC',
      plistPath: 'Contents/Info.plist',
      minKernel: '',
      maxKernel: '',
      name: "VirtualSMC",
      url: "https://github.com/acidanthera/VirtualSMC",
      function: '一个macOS内核扩展必备驱动,主要为macOS提供扩展性和兼容性,这使得其他开发者可以编写用于扩展macOS的内核扩展',
      note: [
        "在真正的苹果硬件上,SMC负责管理硬件传感器、风扇控制、电源管理、温度传感器、电池状态等系统管理功能。VirtualSMC在非苹果硬件上提供了这些功能,以确保macOS可以在这些系统上正常运行",
        "通常与其他内核扩展一起使用,例如 Lilu.kext、WhateverGreen等,以在非苹果硬件上创建一个接近真实Mac的环境",
        "缺少该驱动,不能正常运行macOS"
      ]);
  static KernelKext WhateverGreen = KernelKext(
      bundlePath: 'WhateverGreen.kext',
      executablePath: 'Contents/MacOS/WhateverGreen',
      plistPath: 'Contents/Info.plist',
      minKernel: '',
      maxKernel: '',
      name: "WhateverGreen",
      url: "https://github.com/acidanthera/WhateverGreen",
      function:
          '主要提供GPU图形驱动支持,绝大多数强烈建议勾选(MacPro7,1机型且RX460,RX560等以上AMD独显用户可以去掉勾选),通常与NootRX,NootedRed驱动存在冲突，安装阶段不要同时选择',
      note: [
        "支持多种图形卡，包括 NVIDIA、AMD 和 Intel 图形卡。该扩展可以修复和配置正确的Framebuffer,以使显示器和分辨率工作正常",
        "提供了对 HDMI 和 DisplayPort(DP)连接的支持,以确保音频和视频输出正常工作",
      ]);

  static KernelKext AppleALC = KernelKext(
      bundlePath: 'AppleALC.kext',
      executablePath: 'Contents/MacOS/AppleALC',
      plistPath: 'Contents/Info.plist',
      name: "AppleALC",
      url: "https://github.com/acidanthera/AppleALC",
      minKernel: '',
      maxKernel: '',
      function: '使用AppleALC仿冒内建声卡(相对较完美,优先选择)');

  static KernelKext VoodooHDA = KernelKext(
      bundlePath: 'VoodooHDA.kext',
      executablePath: 'Contents/MacOS/VoodooHDA',
      plistPath: 'Contents/Info.plist',
      minKernel: '',
      maxKernel: '20.3.0',
      function:
          '使用VoodooHDA万能声卡(引导中加载,仅支持macOS BigSur 11.2.3以下,更高macOS版本需要将此驱动打入系统内核扩展才能生效,据作者测试,最高支持macOS Tahoe 26.x正式版)');

  static KernelKext AppleIntelPIIXATA = KernelKext(
      bundlePath: 'AppleIntelPIIXATA.kext',
      executablePath: 'Contents/MacOS/AppleIntelPIIXATA',
      plistPath: 'Contents/Info.plist',
      minKernel: '',
      maxKernel: '',
      function: '老平台或AMD平台USB 3.0控制器兼容性修复');

  static KernelKext telemetrap = KernelKext(
    bundlePath: 'telemetrap.kext',
    executablePath: 'Contents/MacOS/telemetrap',
    plistPath: 'Contents/Info.plist',
    minKernel: '18.0.0',
    maxKernel: '',
  );

  static KernelKext SMCProcessor = KernelKext(
    bundlePath: 'SMCProcessor.kext',
    executablePath: 'Contents/MacOS/SMCProcessor',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
  );

  static KernelKext SMCSuperIO = KernelKext(
    bundlePath: 'SMCSuperIO.kext',
    executablePath: 'Contents/MacOS/SMCSuperIO',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
  );

  static KernelKext RestrictEvents = KernelKext(
    bundlePath: 'RestrictEvents.kext',
    executablePath: 'Contents/MacOS/RestrictEvents',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
  );

  static KernelKext NullCPUPowerManagement = KernelKext(
      bundlePath: 'NullCPUPowerManagement.kext',
      executablePath: 'Contents/MacOS/NullCPUPowerManagement',
      plistPath: 'Contents/Info.plist',
      minKernel: '',
      maxKernel: '',
      function:
          '修复Intel 3代之前老平台CPU电源管理导致的重启问题(表现为出现AppleIntelCPUPowerManagement内核崩溃日志,或卡开机Logo,或刚进入系统就重启等问题)');

  static KernelKext AMDRyzenCPUPowerManagement = KernelKext(
      bundlePath: 'AMDRyzenCPUPowerManagement.kext',
      executablePath: 'Contents/MacOS/AMDRyzenCPUPowerManagement',
      plistPath: 'Contents/Info.plist',
      minKernel: '17.0.0',
      maxKernel: '',
      function:
          "修复AMD Ryzen系列CPU电源管理(仅适用于AMD Ryzen系列,如果出现电源管理导致的重启问题,可以考虑去掉勾选)");

  static KernelKext ACPIBatteryManager = KernelKext(
      bundlePath: 'ACPIBatteryManager.kext',
      executablePath: 'Contents/MacOS/ACPIBatteryManager',
      plistPath: 'Contents/Info.plist',
      minKernel: '',
      maxKernel: '',
      function: "电池驱动方案一(适用于3代及更老平台的笔记本)",
      note: []);

  static KernelKext SMCBatteryManager = KernelKext(
      bundlePath: 'SMCBatteryManager.kext',
      executablePath: 'Contents/MacOS/SMCBatteryManager',
      plistPath: 'Contents/Info.plist',
      minKernel: '',
      maxKernel: '',
      function: "电池驱动方案二(适用于3代及更新平台的笔记本)",
      note: []);

  static KernelKext SMCLightSensor = KernelKext(
      bundlePath: 'SMCLightSensor.kext',
      executablePath: 'Contents/MacOS/SMCLightSensor',
      plistPath: 'Contents/Info.plist',
      minKernel: '',
      maxKernel: '',
      function: "环境光传感器(自动屏幕亮度),如果没有环境光传感器,请勿使用,否则可能会导致问题",
      note: []);

  static KernelKext AsusSMC = KernelKext(
      bundlePath: 'AsusSMC.kext',
      executablePath: 'Contents/MacOS/AsusSMC',
      plistPath: 'Contents/Info.plist',
      minKernel: '',
      maxKernel: '',
      function: "华硕(Asus)笔记本风扇控制、电源管理和其他系统传感器优化等,非华硕不建议使用",
      note: []);

  static KernelKext YogaSMC = KernelKext(
      bundlePath: 'YogaSMC.kext',
      executablePath: 'Contents/MacOS/YogaSMC',
      plistPath: 'Contents/Info.plist',
      minKernel: '',
      maxKernel: '',
      function: "联想(Lenovo)笔记本风扇控制、电源管理和其他系统传感器优化等,非联想机器不建议使用",
      note: []);

  static KernelKext SMCDellSensors = KernelKext(
      bundlePath: 'SMCDellSensors.kext',
      executablePath: 'Contents/MacOS/SMCDellSensors',
      plistPath: 'Contents/Info.plist',
      minKernel: '',
      maxKernel: '',
      function: "戴尔(Dell)笔记本专用传感器,对风扇进行更准确的监视和控制,非戴尔机器不建议使用",
      note: []);

  static KernelKext SMCAMDProcessor = KernelKext(
      bundlePath: 'SMCAMDProcessor.kext',
      executablePath: 'Contents/MacOS/SMCAMDProcessor',
      plistPath: 'Contents/Info.plist',
      minKernel: '17.0.0',
      maxKernel: '',
      function:
          '允许将AMD处理器的传感器信息(如温度、功耗、频率等)暴露给 macOS 的监控工具.此驱动支持 AMD Ryzen 系列处理器和部分 AMD FX 系列处理器,其他AMD处理器可能会导致意外问题,同时Sequoia 15及以上系统部分平台可能存在兼容性问题,谨慎选择.');

  static KernelKext NootRX = KernelKext(
      bundlePath: 'NootRX.kext',
      executablePath: 'Contents/MacOS/NootRX',
      plistPath: 'Contents/Info.plist',
      minKernel: '',
      maxKernel: '',
      name: 'NootRX',
      note: [
        '用于支持RX6700、RX6750XT、RX6750GRE等官方不支持的RX6XXX系列独显,与WhateverGreen驱动存在冲突，安装阶段不要同时选择',
        '支持Navi 21(Big Sur及以上)、Navi 22/23(Monterey及以上),也支持RX6650、RX6950等显卡',
        '首次安装macOS时添加此驱动可能导致无法进入系统,建议完成安装后再添加',
      ]);

  static KernelKext NootedRed = KernelKext(
      bundlePath: 'NootedRed.kext',
      enabled: false,
      executablePath: 'Contents/MacOS/NootedRed',
      plistPath: 'Contents/Info.plist',
      minKernel: '',
      maxKernel: '',
      name: 'NootedRed',
      function: '');

  static KernelKext BFixup = KernelKext(
      bundlePath: 'BFixup.kext',
      executablePath: 'Contents/MacOS/BFixup',
      plistPath: 'Contents/Info.plist',
      minKernel: '',
      maxKernel: '',
      name: 'BFixup',
      function:
          '修复AMD Ryzen 2000~5000系列核显Edge,Chrome浏览器未关闭硬件加速导致的缓慢问题(仅适用于AMD Ryzen系列,主要降低使用OpenGL渲染,正常使用QQ,Chrome浏览器.使用该驱动可能会导致其他应用无法正常使用，自行取舍)');

  static KernelKext AAAMouSSE = KernelKext(
    bundlePath: 'AAAMouSSE.kext',
    executablePath: 'Contents/MacOS/AAAMouSSE',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
  );

  static KernelKext ECEnabler = KernelKext(
      bundlePath: 'ECEnabler.kext',
      executablePath: 'Contents/MacOS/ECEnabler',
      plistPath: 'Contents/Info.plist',
      minKernel: '',
      maxKernel: '',
      function: "电池读数修复,修复部分电池显示问题",
      note: []);

  static KernelKext NVMeFix = KernelKext(
    bundlePath: 'NVMeFix.kext',
    executablePath: 'Contents/MacOS/NVMeFix',
    plistPath: 'Contents/Info.plist',
    minKernel: '18.0.0',
    maxKernel: '',
    note: [
      '提升非苹果NVMe固态硬盘兼容性,减少闲置能耗',
      '不兼容的三星等黑名单NVMe磁盘并不能有效修复超时崩溃问题',
      '兼容性良好的NVMe固态硬盘使用此驱动可能导致内核崩溃,多数时候谨慎使用',
    ],
  );

  static KernelKext AppleMCEReporterDisabler = KernelKext(
    bundlePath: 'AppleMCEReporterDisabler.kext',
    executablePath: '',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
  );

  static KernelKext AMFIPass = KernelKext(
      bundlePath: 'AMFIPass.kext',
      executablePath: 'Contents/MacOS/AMFIPass',
      plistPath: 'Contents/Info.plist',
      minKernel: '18.0.0',
      maxKernel: '',
      function:
          "增强绕过或禁用AMFI的能力.注意:添加该驱动可能会导致某些应用无法打开或闪退,此时可以尝试去掉该驱动,仅使用禁用AMFI启动参数(如amfi=0x80)");

  static KernelKext Innie = KernelKext(
    bundlePath: 'Innie.kext',
    executablePath: 'Contents/MacOS/Innie',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
    note: ['修复NVMe固态硬盘被识别成外置磁盘的问题'],
  );

  static KernelKext FeatureUnlock = KernelKext(
    bundlePath: 'FeatureUnlock.kext',
    executablePath: 'Contents/MacOS/FeatureUnlock',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
    note: ['解锁不受支持Mac上的通用控制、随航等功能'],
  );

  static KernelKext HibernationFixup = KernelKext(
    bundlePath: 'HibernationFixup.kext',
    executablePath: 'Contents/MacOS/HibernationFixup',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
    note: ['修复常见休眠、睡眠相关问题'],
  );

  static KernelKext HoRNDIS = KernelKext(
    bundlePath: 'HoRNDIS.kext',
    executablePath: 'Contents/MacOS/HoRNDIS',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
    note: ['允许macOS通过USB连接使用Android设备的网络共享功能'],
  );

  static KernelKext CryptexFixup = KernelKext(
    bundlePath: 'CryptexFixup.kext',
    executablePath: 'Contents/MacOS/CryptexFixup',
    plistPath: 'Contents/Info.plist',
    minKernel: '22.0.0',
    maxKernel: '',
  );

  static KernelKext NoAVXFSCompressionTypeZlibAVXpel = KernelKext(
    bundlePath: 'NoAVXFSCompressionTypeZlib-AVXpel.kext',
    executablePath: 'Contents/MacOS/NoAVXFSCompressionTypeZlib',
    plistPath: 'Contents/Info.plist',
    minKernel: '22.0.0',
    maxKernel: '',
  );

  static KernelKext CPUFriend = KernelKext(
    bundlePath: 'CPUFriend.kext',
    executablePath: 'Contents/MacOS/CPUFriend',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
    note: ['CPU变频驱动,主要提供11代及以上平台 MacPro7,1变频支持'],
  );

  static KernelKext CPUFriendDataProvider = KernelKext(
    bundlePath: 'CPUFriendDataProvider.kext',
    executablePath: '',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
    note: ['CPUFriend配套数据驱动,提供具体机型的CPU变频数据'],
  );

  static KernelKext CpuTopologyRebuild = KernelKext(
    bundlePath: 'CpuTopologyRebuild.kext',
    executablePath: 'Contents/MacOS/CpuTopologyRebuild',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
    note: [
      '优化Intel 12代及之后CPU大小核心配置',
      '可以提高单核性能,但可能导致多核性能有所下降,仅适用于12代及以上平台',
    ],
  );

  static KernelKext CpuTscSync = KernelKext(
    bundlePath: 'CpuTscSync.kext',
    executablePath: 'Contents/MacOS/CpuTscSync',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
    note: [
      'CPU TSC同步方案一,通常优先选择',
      '常用于多核心X79、X99、X299以及AMD等平台',
      '用于修复操作卡顿、卡开机Logo、音视频同步异常、睡眠唤醒失败等问题',
    ],
  );

  static KernelKext ForgedInvariant = KernelKext(
    bundlePath: 'ForgedInvariant.kext',
    executablePath: 'Contents/MacOS/ForgedInvariant',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
    note: [
      'CPU TSC同步方案二,通常用于AMD Ryzen以及部分Intel平台',
      '用于修复操作卡顿、偶发崩溃、音视频同步异常、睡眠唤醒失败等问题',
    ],
  );

  static KernelKext AmdTscSync = KernelKext(
      bundlePath: 'AmdTscSync.kext',
      executablePath: 'Contents/MacOS/AmdTscSync',
      plistPath: 'Contents/Info.plist',
      minKernel: '',
      maxKernel: '',
      function:
          '修复AMD Ryzen平台CPU多核心时钟同步问题(仅适用于AMD Ryzen系列,用于修复操作卡顿,卡开机Logo等问题,加入此驱动可能导致意外问题，谨慎选择)');

  static KernelKext TSCAdjustReset = KernelKext(
    bundlePath: 'TSCAdjustReset.kext',
    executablePath: 'Contents/MacOS/TSCAdjustReset',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
  );

  static KernelKext VoodooTSCSync = KernelKext(
    bundlePath: 'VoodooTSCSync.kext',
    executablePath: 'Contents/MacOS/VoodooTSCSync',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
    note: [
      'CPU TSC同步方案三,通常用于较老Intel平台和较老macOS系统',
      '适用于多核心X79、X99、X299等平台,用于修复操作卡顿、卡开机Logo等问题',
    ],
  );

  static KernelKext FakePCIID = KernelKext(
    bundlePath: 'FakePCIID.kext',
    executablePath: 'Contents/MacOS/FakePCIID',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
    note: ['修复部分英特尔核显HDMI音频问题'],
  );

  static KernelKext NullEthernet = KernelKext(
    bundlePath: 'NullEthernet.kext',
    executablePath: 'Contents/MacOS/NullEthernet',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
    note: ['修复无法登录Apple ID和iCloud的问题,通常用于没有本地有线网卡的笔记本'],
  );

  static KernelKext RTCMemoryFixup = KernelKext(
    bundlePath: 'RTCMemoryFixup.kext',
    executablePath: 'Contents/MacOS/RTCMemoryFixup',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
    note: ['修复新平台macOS AppleRTC与PC BIOS之间的冲突,例如RTC导致卡死、突然重启或休眠秒醒'],
  );

  static KernelKext ApplePS2SmartTouchPad = KernelKext(
    bundlePath: 'ApplePS2SmartTouchPad.kext',
    executablePath: 'Contents/MacOS/ApplePS2SmartTouchPad',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
  );

  static KernelKext ApplePS2SmartTouchPadApplePS2Controller = KernelKext(
    bundlePath:
        'ApplePS2SmartTouchPad.kext/Contents/PlugIns/ApplePS2Controller.kext',
    executablePath: 'Contents/MacOS/ApplePS2Controller',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
  );

  static KernelKext ApplePS2SmartTouchPadApplePS2Keyboard = KernelKext(
    bundlePath:
        'ApplePS2SmartTouchPad.kext/Contents/PlugIns/ApplePS2Keyboard.kext',
    executablePath: 'Contents/MacOS/ApplePS2Keyboard',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
  );

  static KernelKext VoodooPS2Controller = KernelKext(
    bundlePath: 'VoodooPS2Controller.kext',
    executablePath: 'Contents/MacOS/VoodooPS2Controller',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
    note: ['PS接口类型键盘鼠标驱动(台式机主板PS圆口键鼠驱动)'],
  );

  static KernelKext VoodooPS2ControllerVoodooPS2Keyboard = KernelKext(
    bundlePath:
        'VoodooPS2Controller.kext/Contents/PlugIns/VoodooPS2Keyboard.kext',
    executablePath: 'Contents/MacOS/VoodooPS2Keyboard',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
    note: ['PS接口类型键盘驱动(台式机主板PS圆口键盘驱动)'],
  );

  static KernelKext VoodooPS2ControllerVoodooPS2Mouse = KernelKext(
    bundlePath: 'VoodooPS2Controller.kext/Contents/PlugIns/VoodooPS2Mouse.kext',
    executablePath: 'Contents/MacOS/VoodooPS2Mouse',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
    note: ['PS接口类型鼠标驱动(台式机主板PS圆口鼠标驱动)'],
  );

  static KernelKext VoodooPS2ControllerVoodooPS2Trackpad = KernelKext(
    bundlePath:
        'VoodooPS2Controller.kext/Contents/PlugIns/VoodooPS2Trackpad.kext',
    executablePath: 'Contents/MacOS/VoodooPS2Trackpad',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
  );

  static KernelKext VoodooPS2ControllerVoodooInput = KernelKext(
    bundlePath: 'VoodooPS2Controller.kext/Contents/PlugIns/VoodooInput.kext',
    executablePath: 'Contents/MacOS/VoodooInput',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
  );

  static KernelKext VoodooI2CVoodooInput = KernelKext(
    bundlePath: 'VoodooI2C.kext/Contents/PlugIns/VoodooInput.kext',
    executablePath: 'Contents/MacOS/VoodooInput',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
  );
  static KernelKext VoodooI2CVoodooI2CServices = KernelKext(
    bundlePath: 'VoodooI2C.kext/Contents/PlugIns/VoodooI2CServices.kext',
    executablePath: 'Contents/MacOS/VoodooI2CServices',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
  );

  static KernelKext VoodooI2CVoodooGPIO = KernelKext(
    bundlePath: 'VoodooI2C.kext/Contents/PlugIns/VoodooGPIO.kext',
    executablePath: 'Contents/MacOS/VoodooGPIO',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
  );

  static KernelKext VoodooI2C = KernelKext(
    bundlePath: 'VoodooI2C.kext',
    executablePath: 'Contents/MacOS/VoodooI2C',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
  );

  static KernelKext VoodooSMBus = KernelKext(
    bundlePath: 'VoodooSMBus.kext',
    executablePath: 'Contents/MacOS/VoodooSMBus',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
  );

  static KernelKext VoodooRMI = KernelKext(
    bundlePath: 'VoodooRMI.kext',
    executablePath: 'Contents/MacOS/VoodooRMI',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
  );

  static KernelKext VoodooRMIVoodooInput = KernelKext(
    bundlePath: 'VoodooRMI.kext/Contents/PlugIns/VoodooInput.kext',
    executablePath: 'Contents/MacOS/VoodooInput',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
  );

  static KernelKext VoodooRMIRMISMBus = KernelKext(
    bundlePath: 'VoodooRMI.kext/Contents/PlugIns/RMISMBus.kext',
    executablePath: 'Contents/MacOS/RMISMBus',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
  );

  static KernelKext VoodooRMIRMII2C = KernelKext(
    bundlePath: 'VoodooRMI.kext/Contents/PlugIns/RMII2C.kext',
    executablePath: 'Contents/MacOS/RMII2C',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
  );

  static KernelKext VoodooI2CHID = KernelKext(
    bundlePath: 'VoodooI2CHID.kext',
    executablePath: 'Contents/MacOS/VoodooI2CHID',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
  );

  static KernelKext BigSurfaceVoodooGPIO = KernelKext(
    bundlePath: 'BigSurface.kext/Contents/PlugIns/VoodooGPIO.kext',
    executablePath: 'Contents/MacOS/VoodooGPIO',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
  );

  static KernelKext BigSurfaceVoodooSerial = KernelKext(
    bundlePath: 'BigSurface.kext/Contents/PlugIns/VoodooSerial.kext',
    executablePath: 'Contents/MacOS/VoodooSerial',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
  );

  static KernelKext BigSurfaceVoodooInput = KernelKext(
    bundlePath: 'BigSurface.kext/Contents/PlugIns/VoodooInput.kext',
    executablePath: 'Contents/MacOS/VoodooInput',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
  );

  static KernelKext BigSurface = KernelKext(
    bundlePath: 'BigSurface.kext',
    executablePath: 'Contents/MacOS/BigSurface',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
    function: 'Microsoft Surface 专用键盘触摸板驱动',
  );

  static KernelKext BigSurfaceHIDDriver = KernelKext(
    bundlePath: 'BigSurface.kext/Contents/PlugIns/BigSurfaceHIDDriver.kext',
    executablePath: 'Contents/MacOS/BigSurfaceHIDDriver',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
  );

  static KernelKext BrightnessKeys = KernelKext(
    bundlePath: 'BrightnessKeys.kext',
    executablePath: 'Contents/MacOS/BrightnessKeys',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
    function: "亮度快捷键修复",
  );
  static KernelKext RadeonBoost = KernelKext(
    bundlePath: 'RadeonBoost.kext',
    executablePath: '',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
    note: ['优化AMD Radeon显卡性能,但某些场景可能导致系统崩溃或无法启动,谨慎勾选'],
  );
  static KernelKext RadeonSensor = KernelKext(
    bundlePath: 'RadeonSensor.kext',
    executablePath: 'Contents/MacOS/RadeonSensor',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
    note: ['允许RadeonGadget.app读取AMD显卡GPU温度等信息'],
  );

  static KernelKext SMCRadeonGPU = KernelKext(
    bundlePath: 'SMCRadeonGPU.kext',
    executablePath: 'Contents/MacOS/SMCRadeonGPU',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
    note: ['将AMD GPU温度等信息导出到VirtualSMC,供监控工具读取'],
  );

  static KernelKext GenericUSBXHCI = KernelKext(
    bundlePath: 'GenericUSBXHCI.kext',
    executablePath: 'Contents/MacOS/GenericUSBXHCI',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
    note: ['老平台或AMD平台USB 3.0控制器兼容性修复'],
  );

  static KernelKext XLNCUSBFix = KernelKext(
      bundlePath: 'XLNCUSBFix.kext',
      executablePath: '',
      plistPath: 'Contents/Info.plist',
      minKernel: '17.0.0',
      maxKernel: '',
      function: '修复AMD FM1/FM2/AM3等老平台USB控制器兼容性问题');

  static KernelKext USBInjectAll = KernelKext(
      bundlePath: 'USBInjectAll.kext',
      executablePath: 'Contents/MacOS/USBInjectAll',
      plistPath: 'Contents/Info.plist',
      minKernel: '',
      maxKernel: '',
      function: '通用USB注入方案,未定制USB时的默认选择');

  static KernelKext USBToolBox = KernelKext(
      bundlePath: 'USBToolBox.kext',
      executablePath: 'Contents/MacOS/USBToolBox',
      plistPath: 'Contents/Info.plist',
      minKernel: '',
      maxKernel: '',
      function: 'USBToolBox方案,通常配合定制好的UTBMap.kext使用');

  static KernelKext UTBMap = KernelKext(
    bundlePath: 'UTBMap.kext',
    executablePath: '',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
  );

  static KernelKext XHCIUnsupported = KernelKext(
    bundlePath: 'XHCI-unsupported.kext',
    executablePath: '',
    plistPath: 'Contents/Info.plist',
    minKernel: '17.0.0',
    maxKernel: '',
    note: [
      '修复Intel 3代及之后更新平台USB3.0问题(300系列芯片组需要(H370,B360,H310,Z390【10.14及以上系统不需要】,X79,X99,ASRock英特尔主板需要【B460/Z490+除外】)'
    ],
  );

  static KernelKext DummyUSBEHCIPCI = KernelKext(
    bundlePath: 'DummyUSBEHCIPCI.kext',
    executablePath: 'Contents/MacOS/AppleUSBEHCIPCI',
    plistPath: 'Contents/Info.plist',
    minKernel: '17.0.0',
    maxKernel: '',
    note: ['修复AMD FM1、FM2、AM3等老平台EHCI USB2.0兼容性问题'],
  );

  static KernelKext DummyUSBXHCIPCI = KernelKext(
    bundlePath: 'DummyUSBXHCIPCI.kext',
    executablePath: 'Contents/MacOS/AppleUSBXHCIPCI',
    plistPath: 'Contents/Info.plist',
    minKernel: '17.0.0',
    maxKernel: '',
    note: ['修复AMD FM1、FM2、AM3等老平台XHCI USB3.0兼容性问题'],
  );

  static KernelKext AppleIntelCPUPowerManagement = KernelKext(
      bundlePath: 'AppleIntelCPUPowerManagement.kext',
      executablePath: 'Contents/MacOS/AppleIntelCPUPowerManagement',
      plistPath: 'Contents/Info.plist',
      minKernel: '22.0.0',
      maxKernel: '',
      function: '修复Intel 3代以及更老平台Ventura 13及以上系统CPU电源管理');

  static KernelKext AppleIntelCPUPowerManagementClient = KernelKext(
      bundlePath: 'AppleIntelCPUPowerManagementClient.kext',
      executablePath: 'Contents/MacOS/AppleIntelCPUPowerManagementClient',
      plistPath: 'Contents/Info.plist',
      minKernel: '22.0.0',
      maxKernel: '',
      function: '修复Intel 3代以及更老平台Ventura 13及以上系统CPU电源管理');

  static KernelKext RealtekCardReader = KernelKext(
    bundlePath: 'RealtekCardReader.kext',
    executablePath: 'Contents/MacOS/RealtekCardReader',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
    note: ['Realtek系列SD卡读卡器驱动(搭配RealtekCardReaderFriend使用)'],
  );

  static KernelKext RealtekCardReaderFriend = KernelKext(
    bundlePath: 'RealtekCardReaderFriend.kext',
    executablePath: 'Contents/MacOS/RealtekCardReaderFriend',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
    note: ['RealtekCardReader配套驱动,用于完善Realtek读卡器兼容性'],
  );

  static KernelKext EmeraldSDHC = KernelKext(
    bundlePath: 'EmeraldSDHC.kext',
    executablePath: 'Contents/MacOS/EmeraldSDHC',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
    note: ['SDHC储存卡设备驱动,支持eMMC和MMC储存卡'],
  );

  static KernelKext RealtekRTL8100 = KernelKext(
      name: 'RealtekRTL8100',
      bundlePath: 'RealtekRTL8100.kext',
      executablePath: 'Contents/MacOS/RealtekRTL8100',
      plistPath: 'Contents/Info.plist',
      minKernel: '',
      maxKernel: '',
      function:
          "810X,8100,8101E,8102E,8103E,8401E,8105E,8402,8106E,8106EUS,8107E,8136,8139",
      note: [
        "百兆有线网卡驱动",
        "支持RTL8101E、RTL8102E、RTL8103E、RTL8401E、RTL8105E、RTL8402、RTL8106E、 RTL8106EUS、RTL8107E、RTL8139网卡",
        "通常用于传统老平台"
      ]);

  static KernelKext AppleIntelE1000e = KernelKext(
      name: 'AppleIntelE1000e',
      bundlePath: 'AppleIntelE1000e.kext',
      executablePath: 'Contents/MacOS/AppleIntelE1000e',
      plistPath: 'Contents/Info.plist',
      minKernel: '',
      maxKernel: '',
      function:
          "82540,82541,82542,82543,82545,82546,82547,82578,82579,82574L,82571,82572,82573,82574,82583,I217-V",
      note: [
        "千兆网卡驱动",
        "支持Intel 82540 ~ 82547,82578 ~ 82579,82574L,82571 ~ 82574,82583,I217-V等网卡",
        "通常用于传统老平台"
      ]);

  static KernelKext BCM5722D = KernelKext(
      name: 'BCM5722D',
      bundlePath: 'BCM5722D.kext',
      executablePath: 'Contents/MacOS/BCM5722D',
      plistPath: 'Contents/Info.plist',
      minKernel: '',
      maxKernel: '',
      function:
          "BCM5722,BCM5754,BCM5754M,BCM5755,BCM5755M,BCM57788,BCM5787,BCM5787M,BCM5906,BCM5906M",
      note: [
        "千兆有线网卡驱动",
        "支持BCM5722,BCM5754,BCM5754M,BCM5755,BCM5755M,BCM57788,BCM5787,BCM5787M,BCM5906,BCM5906M等网卡",
        "通常用于传统老平台"
      ]);

  static KernelKext AtherosL1cEthernet = KernelKext(
      name: 'AtherosL1cEthernet',
      bundlePath: 'AtherosL1cEthernet.kext',
      executablePath: 'Contents/MacOS/AtherosL1cEthernet',
      plistPath: 'Contents/Info.plist',
      minKernel: '',
      maxKernel: '',
      function: "AR8131,AR8132,AR8151,AR8152",
      note: ["千兆有线网卡驱动", "支持AR8131, AR8132, AR8151, AR8152等网卡", "通常用于传统老平台"]);

  static KernelKext RealtekRTL8111 = KernelKext(
      name: 'RealtekRTL8111',
      bundlePath: 'RealtekRTL8111.kext',
      executablePath: 'Contents/MacOS/RealtekRTL8111',
      plistPath: 'Contents/Info.plist',
      minKernel: '',
      maxKernel: '',
      function: "8111,8168,2500,2600,E2500,E2600",
      note: [
        "千兆有线网卡驱动",
        "支持Realtek RTL8111 / 8168 B / C / D / E / F / G / H,支持⻢甲卡Killer E2500及以上网卡",
        "RealtekRTL8111新版本驱动可能仅支持10.13.x及以上系统"
      ]);

  static KernelKext AtherosE2200Ethernet = KernelKext(
      name: 'AtherosE2200Ethernet',
      bundlePath: 'AtherosE2200Ethernet.kext',
      executablePath: 'Contents/MacOS/AtherosE2200Ethernet',
      plistPath: 'Contents/Info.plist',
      minKernel: '',
      maxKernel: '',
      function: "AR816X,AR817X,E220X,E2400",
      note: ["千兆有线网卡驱动", "支持AR816x ,AR817x,Killer E220x,Killer E2400等网卡"]);

  static KernelKext AppleIGC = KernelKext(
      name: 'AppleIGC',
      bundlePath: 'AppleIGC.kext',
      executablePath: 'Contents/MacOS/AppleIGC',
      plistPath: 'Contents/Info.plist',
      minKernel: '',
      maxKernel: '',
      function: "I225,I226",
      note: [
        "千兆(支持2.5G)有线网卡驱动",
        "支持所有符合IGC的设备(i225、i226,i226-V等有线网卡),部分设备的PCI ID可能不在IOPCIMatch列表，自行添加测试",
        "相比AppleEthernetE1000驱动程序具有更好的性能及稳定性(i226-V在Monterey系统使用AppleEthernetE1000可能会引起内核恐慌)"
      ]);

  static KernelKext AppleIGB = KernelKext(
      name: 'AppleIGB',
      bundlePath: 'AppleIGB.kext',
      executablePath: 'Contents/MacOS/AppleIGB',
      plistPath: 'Contents/Info.plist',
      minKernel: '',
      maxKernel: '',
      function: "82575,82576,82580,DH89XXCC,I350,I354,I210,I211",
      note: [
        "千兆(支持2.5G)有线网卡驱动",
        "支持Intel 82575, 82576, 82580, dh89xxcc,i350,i354,i210和 i211网卡",
        "可能存在不稳定性问题,建议保持在Big Sur版本,并使用SmallTree",
        "通常适用于macOS Monterey 12及以上系统"
      ]);

  static KernelKext IntelMausi = KernelKext(
      name: 'IntelMausi',
      bundlePath: 'IntelMausi.kext',
      executablePath: 'Contents/MacOS/IntelMausi',
      plistPath: 'Contents/Info.plist',
      minKernel: '',
      maxKernel: '',
      function: "82578,82579,I217,I218,I219",
      note: [
        "千兆有线网卡驱动",
        "支持Intel 5 Series: 82578LM、82578LC、82578DM、82578DC",
        "支持Intel 6 and 7 Series: 82579LM、82579V",
        "支持Intel 8 and 9 Series: I217LM、I217V、I218LM、I218V、I218LM2、I218V2、I218LM3",
        "支持Intel 100 Series: I219V、I219LM、I219V2、I219LM2、I219LM3",
        "支持Intel 200 Series: I219LM、I219V",
        "支持Intel 300 Series: I219LM、I219V",
        "该驱动由acidanthera维护.OS X 10.6 ~ 10.8 使用IntelSnowMausi"
      ]);

  static KernelKext IntelMausiEthernet = KernelKext(
      name: 'IntelMausiEthernet',
      bundlePath: 'IntelMausiEthernet.kext',
      executablePath: 'Contents/MacOS/IntelMausiEthernet',
      plistPath: 'Contents/Info.plist',
      minKernel: '',
      maxKernel: '',
      function:
          "82578LM,82578LC,82578DM,82578DC,82579LM,82579V,I217LM,I217V,I218LM,I218V,I218LM2,I218V2,I218LM3,I219V,I219LM,I219V2,I219LM2,I219LM2",
      note: [
        "千兆有线网卡驱动",
        "支持Intel 5 Series: 82578LM、82578LC、82578DM、82578DC",
        "支持Intel 6 and 7 Series: 82579LM、82579V",
        "支持Intel 8 and 9 Series: I217LM、I217V、I218LM、I218V、I218LM2、I218V2、I218LM3",
        "支持Intel 100 Series: I219V、I219LM、I219V2、I219LM2、I219LM3",
        "支持Intel 200 Series: I219LM、I219V",
        "支持Intel 300 Series: I219LM、I219V",
        "该驱动由Laura Müller提供.OS X 10.6 ~ 10.8 使用IntelSnowMausi"
      ]);

  static KernelKext LucyRTL8125Ethernet = KernelKext(
      name: 'LucyRTL8125Ethernet',
      bundlePath: 'LucyRTL8125Ethernet.kext',
      executablePath: 'Contents/MacOS/LucyRTL8125Ethernet',
      plistPath: 'Contents/Info.plist',
      minKernel: '',
      maxKernel: '',
      function: "8125",
      note: ["千兆(支持2.5G)有线网卡驱动", "RTL8125旧驱动,支持Realtek RTL8125系列以太网卡"]);

  static KernelKext RTL812xLucy = KernelKext(
      name: 'RTL812xLucy',
      bundlePath: 'RTL812xLucy.kext',
      executablePath: 'Contents/MacOS/RTL812xLucy',
      plistPath: 'Contents/Info.plist',
      minKernel: '',
      maxKernel: '',
      function: "8125,8126",
      note: [
        "千兆(支持2.5G,5G)有线网卡驱动",
        "RTL812x新驱动,支持Realtek RTL8125,RTL8126系列以太网卡",
        "支持型号:RTL8125A, RTL8125B, RTL8125BP, RTL8125CP, RTL8126A"
      ]);

  static KernelKext SmallTreeIntel82576 = KernelKext(
      name: 'SmallTreeIntel82576',
      bundlePath: 'SmallTreeIntel82576.kext',
      executablePath: 'Contents/MacOS/SmallTreeIntel82576',
      plistPath: 'Contents/Info.plist',
      minKernel: '',
      maxKernel: '',
      function: "I211",
      note: [
        "千兆(支持2.5G)有线网卡驱动",
        "支持Intel i211有线网卡,此型号常见于AMD主板",
        "通常适用于macOS Big Sur及以下版本,macOS Monterey可能存在不稳定情况",
        "兼容性:OS X 10.9-12（推荐版本v1.0.6）、macOS 10.13-14（推荐版本v1.2.5）、macOS 10.15+（推荐版本v1.3.0）"
      ]);

  static KernelKext IntelLucy = KernelKext(
      name: 'IntelLucy',
      bundlePath: 'IntelLucy.kext',
      executablePath: 'Contents/MacOS/IntelLucy',
      plistPath: 'Contents/Info.plist',
      minKernel: '17.0.0',
      maxKernel: '',
      function: "X520,X540,X550,82598",
      note: [
        "万兆(支持10G)有线网卡驱动",
        "支持英特尔X520、X540、X550和82598以太网适配器,不再需要硬件修改(以前Smalltree8259x.kext需要)",
        "仅支持macOS 10.13及以上系统",
        "在BIOS UEFI设置中建议关闭WoL"
      ]);

  static KernelKext SATAUnsupported = KernelKext(
    bundlePath: 'SATA-unsupported.kext',
    executablePath: '',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '19.99.99',
    note: ['修复Catalina 10.15及以下系统安装过程中磁盘工具不识别SATA磁盘的问题'],
  );

  static KernelKext CtlnaAHCIPort = KernelKext(
    bundlePath: 'CtlnaAHCIPort.kext',
    executablePath: 'Contents/MacOS/CtlnaAHCIPort',
    plistPath: 'Contents/Info.plist',
    minKernel: '20.0.0',
    maxKernel: '',
    note: ['修复Big Sur 11及以上系统安装过程中磁盘工具不识别SATA磁盘的问题'],
  );

  static KernelKext IntelMKLFixup = KernelKext(
    bundlePath: 'IntelMKLFixup.kext',
    executablePath: 'Contents/MacOS/IntelMKLFixup',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
    note: ['修复AMD平台Adobe全家桶相关兼容性问题'],
  );

  static KernelKext IOSkywalkFamily = KernelKext(
    bundlePath: 'IOSkywalkFamily.kext',
    executablePath: 'Contents/MacOS/IOSkywalkFamily',
    plistPath: 'Contents/Info.plist',
    minKernel: '23.0.0',
    maxKernel: '25.99.99',
  );

  static KernelKext IO80211FamilyLegacy = KernelKext(
    bundlePath: 'IO80211FamilyLegacy.kext',
    executablePath: 'Contents/MacOS/IO80211FamilyLegacy',
    plistPath: 'Contents/Info.plist',
    minKernel: '23.0.0',
    maxKernel: '25.99.99',
  );

  static KernelKext IO80211FamilyLegacyAirPortBrcmNIC = KernelKext(
    bundlePath: 'IO80211FamilyLegacy.kext/Contents/PlugIns/AirPortBrcmNIC.kext',
    executablePath: 'Contents/MacOS/AirPortBrcmNIC',
    plistPath: 'Contents/Info.plist',
    minKernel: '23.0.0',
    maxKernel: '25.99.99',
  );

  static KernelKext AirportBrcmFixup = KernelKext(
    bundlePath: 'AirportBrcmFixup.kext',
    executablePath: 'Contents/MacOS/AirportBrcmFixup',
    plistPath: 'Contents/Info.plist',
    minKernel: '14.0.0',
    maxKernel: '',
  );

  static KernelKext AirportBrcmFixupAirPortBrcm4360_Injector = KernelKext(
    bundlePath:
        'AirportBrcmFixup.kext/Contents/PlugIns/AirPortBrcm4360_Injector.kext',
    executablePath: '',
    plistPath: 'Contents/Info.plist',
    minKernel: '14.0.0',
    maxKernel: '19.99.99',
  );

  static KernelKext AirportBrcmFixupAirPortBrcmNIC_Injector = KernelKext(
    bundlePath:
        'AirportBrcmFixup.kext/Contents/PlugIns/AirPortBrcmNIC_Injector.kext',
    executablePath: '',
    plistPath: 'Contents/Info.plist',
    minKernel: '20.0.0',
    maxKernel: '',
  );

  static KernelKext corecaptureElCap = KernelKext(
    bundlePath: 'corecaptureElCap.kext',
    executablePath: 'Contents/MacOS/corecaptureElCap',
    plistPath: 'Contents/Info.plist',
    minKernel: '16.0.0',
    maxKernel: '',
  );

  static KernelKext IO80211ElCap = KernelKext(
    bundlePath: 'IO80211ElCap.kext',
    executablePath: 'Contents/MacOS/IO80211ElCap',
    plistPath: 'Contents/Info.plist',
    minKernel: '16.0.0',
    maxKernel: '',
  );

  static KernelKext IO80211ElCap_AirPortAtheros40 = KernelKext(
    bundlePath: 'IO80211ElCap.kext/Contents/PlugIns/AirPortAtheros40.kext',
    executablePath: 'Contents/MacOS/AirPortAtheros40',
    plistPath: 'Contents/Info.plist',
    minKernel: '21.0.0',
    maxKernel: '',
  );

  // 10.14 被移除
  static KernelKext IO80211ElCap_AirPortBrcm4331 = KernelKext(
    bundlePath: 'IO80211ElCap.kext/Contents/PlugIns/AirPortBrcm4331.kext',
    executablePath: 'Contents/MacOS/AirPortBrcm4331',
    plistPath: 'Contents/Info.plist',
    minKernel: '18.0.0',
    maxKernel: '',
  );

  // 10.12 被移除
  static KernelKext IO80211ElCap_AppleAirPortBrcm43224 = KernelKext(
    bundlePath: 'IO80211ElCap.kext/Contents/PlugIns/AppleAirPortBrcm43224.kext',
    executablePath: 'Contents/MacOS/AppleAirPortBrcm43224',
    plistPath: 'Contents/Info.plist',
    minKernel: '16.0.0',
    maxKernel: '',
  );

  static KernelKext itlwm = KernelKext(
    bundlePath: 'itlwm.kext',
    executablePath: 'Contents/MacOS/itlwm',
    plistPath: 'Contents/Info.plist',
    minKernel: '17.0.0',
    maxKernel: '',
    note: ["支持macOS High Sierra 10.13 ~ macOS Tathoe 26.x(通常搭配HeliPort客户端使用)"],
  );

  static KernelKext AirportItlwm_Sequoia = KernelKext(
    bundlePath: 'AirportItlwm_Sequoia.kext',
    executablePath: 'Contents/MacOS/AirportItlwm',
    plistPath: 'Contents/Info.plist',
    minKernel: '24.0.0',
    maxKernel: '25.99.99',
    note: [
      "macOS Sequoia 15.x (注意:Sequoia 15系统需要使用OCLP Intel专用修改版打补丁方可正常使用！！！)"
    ],
  );

  static KernelKext AirportItlwm_Sonoma_14_4 = KernelKext(
    bundlePath: 'AirportItlwm_Sonoma_14_4.kext',
    executablePath: 'Contents/MacOS/AirportItlwm',
    plistPath: 'Contents/Info.plist',
    minKernel: '23.4.0',
    maxKernel: '23.99.99',
    note: ["macOS Sonoma 14.4及以上"],
  );

  static KernelKext AirportItlwm_Sonoma = KernelKext(
    bundlePath: 'AirportItlwm_Sonoma.kext',
    executablePath: 'Contents/MacOS/AirportItlwm',
    plistPath: 'Contents/Info.plist',
    minKernel: '23.0.0',
    maxKernel: '23.3.99',
    note: ["macOS Sonoma 14.0 ~ macOS Sonoma 14.3"],
  );

  static KernelKext AirportItlwm_Ventura = KernelKext(
    bundlePath: 'AirportItlwm_Ventura.kext',
    executablePath: 'Contents/MacOS/AirportItlwm',
    plistPath: 'Contents/Info.plist',
    minKernel: '22.0.0',
    maxKernel: '22.99.99',
    note: ["macOS Ventura 13.x"],
  );

  static KernelKext AirportItlwm_Monterey = KernelKext(
    bundlePath: 'AirportItlwm_Monterey.kext',
    executablePath: 'Contents/MacOS/AirportItlwm',
    plistPath: 'Contents/Info.plist',
    minKernel: '21.0.0',
    maxKernel: '21.99.99',
    note: ["macOS Monterey 12.x"],
  );

  static KernelKext AirportItlwm_BigSur = KernelKext(
    bundlePath: 'AirportItlwm_BigSur.kext',
    executablePath: 'Contents/MacOS/AirportItlwm',
    plistPath: 'Contents/Info.plist',
    minKernel: '20.0.0',
    maxKernel: '20.99.99',
    note: ["macOS Big Sur 11.x"],
  );

  static KernelKext AirportItlwm_Catalina = KernelKext(
    bundlePath: 'AirportItlwm_Catalina.kext',
    executablePath: 'Contents/MacOS/AirportItlwm',
    plistPath: 'Contents/Info.plist',
    minKernel: '19.0.0',
    maxKernel: '19.99.99',
    note: ["macOS Catalina 10.15.x"],
  );

  static KernelKext AirportItlwm_Mojave = KernelKext(
    bundlePath: 'AirportItlwm_Mojave.kext',
    executablePath: 'Contents/MacOS/AirportItlwm',
    plistPath: 'Contents/Info.plist',
    minKernel: '18.0.0',
    maxKernel: '18.99.99',
    note: ["macOS Mojave 10.14.x"],
  );

  static KernelKext AirportItlwm_HighSierra = KernelKext(
    bundlePath: 'AirportItlwm_HighSierra.kext',
    executablePath: 'Contents/MacOS/AirportItlwm',
    plistPath: 'Contents/Info.plist',
    minKernel: '17.0.0',
    maxKernel: '17.99.99',
    note: ["macOS High Sierra 10.13.x"],
  );

  static KernelKext IntelBTPatcher = KernelKext(
    bundlePath: 'IntelBTPatcher.kext',
    executablePath: 'Contents/MacOS/IntelBTPatcher',
    plistPath: 'Contents/Info.plist',
    minKernel: '21.0.0',
    maxKernel: '',
  );

  static KernelKext IntelBluetoothInjector = KernelKext(
    bundlePath: 'IntelBluetoothInjector.kext',
    executablePath: '',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '20.99.99',
  );

  static KernelKext IntelBluetoothFirmware = KernelKext(
    bundlePath: 'IntelBluetoothFirmware.kext',
    executablePath: 'Contents/MacOS/IntelBluetoothFirmware',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
  );

  static KernelKext BlueToolFixup = KernelKext(
    bundlePath: 'BlueToolFixup.kext',
    executablePath: 'Contents/MacOS/BlueToolFixup',
    plistPath: 'Contents/Info.plist',
    minKernel: '21.0.0',
    maxKernel: '',
    function: '主要修复部分蓝牙设备问题(适用部分博通和其他USB蓝牙设备)',
  );

  static KernelKext BrcmBluetoothInjector = KernelKext(
    bundlePath: 'BrcmBluetoothInjector.kext',
    executablePath: '',
    plistPath: 'Contents/Info.plist',
    minKernel: '15.0.0',
    maxKernel: '20.99.99',
  );

  static KernelKext BrcmBluetoothInjectorLegacy = KernelKext(
    bundlePath: 'BrcmBluetoothInjectorLegacy.kext',
    executablePath: '',
    plistPath: 'Contents/Info.plist',
    minKernel: '15.0.0',
    maxKernel: '20.99.99',
  );

  static KernelKext BrcmFirmwareData = KernelKext(
    bundlePath: 'BrcmFirmwareData.kext',
    executablePath: 'Contents/MacOS/BrcmFirmwareData',
    plistPath: 'Contents/Info.plist',
    minKernel: '12.0.0',
    maxKernel: '',
  );

  static KernelKext BrcmPatchRAM = KernelKext(
    bundlePath: 'BrcmPatchRAM.kext',
    executablePath: 'Contents/MacOS/BrcmPatchRAM',
    plistPath: 'Contents/Info.plist',
    minKernel: '12.0.0',
    maxKernel: '14.99.99',
  );

  static KernelKext BrcmPatchRAM2 = KernelKext(
    bundlePath: 'BrcmPatchRAM2.kext',
    executablePath: 'Contents/MacOS/BrcmPatchRAM2',
    plistPath: 'Contents/Info.plist',
    minKernel: '15.0.0',
    maxKernel: '18.99.99',
  );

  static KernelKext BrcmPatchRAM3 = KernelKext(
    bundlePath: 'BrcmPatchRAM3.kext',
    executablePath: 'Contents/MacOS/BrcmPatchRAM3',
    plistPath: 'Contents/Info.plist',
    minKernel: '19.0.0',
    maxKernel: '',
  );

  static KernelKext Ath3kBT = KernelKext(
    bundlePath: 'Ath3kBT.kext',
    executablePath: 'Contents/MacOS/Ath3kBT',
    plistPath: 'Contents/Info.plist',
    minKernel: '16.0.0',
    maxKernel: '',
  );

  static KernelKext Ath3kBTInjector = KernelKext(
    bundlePath: 'Ath3kBTInjector.kext',
    executablePath: 'Contents/MacOS/Ath3kBTInjector',
    plistPath: 'Contents/Info.plist',
    minKernel: '16.0.0',
    maxKernel: '',
  );

  static KernelKext HS80211Family = KernelKext(
    bundlePath: 'HS80211Family.kext',
    executablePath: 'Contents/MacOS/HS80211Family',
    plistPath: 'Contents/Info.plist',
    minKernel: '18.0.0',
    maxKernel: '20.99.99',
    note: ["高通WiFi,支持macOS Big Sur 11.x 及以下版本"],
  );

  static KernelKext AirPortAtheros40_9285 = KernelKext(
    bundlePath: 'AirPortAtheros40_9285.kext',
    executablePath: 'Contents/MacOS/AirPortAtheros40',
    plistPath: 'Contents/Info.plist',
    minKernel: '18.0.0',
    maxKernel: '20.99.99',
    note: ["高通(Atheros)-AR9285"],
  );

  static KernelKext AirPortAtheros40_9380 = KernelKext(
    bundlePath: 'AirPortAtheros40_9380.kext',
    executablePath: 'Contents/MacOS/AirPortAtheros40',
    plistPath: 'Contents/Info.plist',
    minKernel: '18.0.0',
    maxKernel: '20.99.99',
    note: ["高通(Atheros)-AR9380"],
  );

  static KernelKext AirPortAtheros40_9485 = KernelKext(
    bundlePath: 'AirPortAtheros40_9485.kext',
    executablePath: 'Contents/MacOS/AirPortAtheros40',
    plistPath: 'Contents/Info.plist',
    minKernel: '18.0.0',
    maxKernel: '20.99.99',
    note: ["高通(Atheros)-AR9485"],
  );

  static KernelKext AirPortAtheros40_9565 = KernelKext(
    bundlePath: 'AirPortAtheros40_9565.kext',
    executablePath: 'Contents/MacOS/AirPortAtheros40',
    plistPath: 'Contents/Info.plist',
    minKernel: '18.0.0',
    maxKernel: '20.99.99',
    note: ["高通(Atheros)-AR9565"],
  );

  static KernelKext AirPortAtheros40_9463 = KernelKext(
    bundlePath: 'AirPortAtheros40_9463.kext',
    executablePath: 'Contents/MacOS/AirPortAtheros40',
    plistPath: 'Contents/Info.plist',
    minKernel: '18.0.0',
    maxKernel: '20.99.99',
    note: ["高通(Atheros)-AR9463"],
  );

  static KernelKext AirPortAtheros40_9462 = KernelKext(
    bundlePath: 'AirPortAtheros40_9462.kext',
    executablePath: 'Contents/MacOS/AirPortAtheros40',
    plistPath: 'Contents/Info.plist',
    minKernel: '18.0.0',
    maxKernel: '20.99.99',
    note: ["高通(Atheros)-AR9462"],
  );

  static KernelKext NoTouchID = KernelKext(
    bundlePath: 'NoTouchID.kext',
    executablePath: 'Contents/MacOS/NoTouchID',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
    note: [
      '禁用Touch ID,减少系统资源浪费并提高稳定性',
      '通常适用于macOS Big Sur 11以下且带指纹识别的笔记本',
    ],
  );

  static KernelKext RtWlanU1827 = KernelKext(
    bundlePath: 'RtWlanU1827.kext',
    executablePath: 'Contents/MacOS/RtWlanU1827',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
  );

  static KernelKext RtWlanU = KernelKext(
    bundlePath: 'RtWlanU.kext',
    executablePath: 'Contents/MacOS/RtWlanU',
    plistPath: 'Contents/Info.plist',
    minKernel: '',
    maxKernel: '',
  );

  static List<KernelKext> lanKernelKexts = [
    RealtekRTL8100,
    AppleIntelE1000e,
    BCM5722D,
    AtherosL1cEthernet,
    RealtekRTL8111,
    AtherosE2200Ethernet,
    AppleIGC,
    AppleIGB,
    IntelMausi,
    IntelMausiEthernet,
    LucyRTL8125Ethernet,
    RTL812xLucy,
    SmallTreeIntel82576,
    IntelLucy
  ];

  static List<KernelKext> sortKernelKexts = [
    Lilu,
    VirtualSMC,
    AAAMouSSE,
    AsusSMC,
    YogaSMC,
    WhateverGreen,
    BFixup,
    NootedRed,
    ECEnabler,
    ACPIBatteryManager,
    SMCBatteryManager,
    SMCDellSensors,
    SMCLightSensor,
    SMCProcessor,
    SMCSuperIO,
    NootRX,
    AppleALC,
    VoodooHDA,
    AppleMCEReporterDisabler,
    RestrictEvents,
    AMDRyzenCPUPowerManagement,
    SMCAMDProcessor,
    AmdTscSync,
    SMCRadeonGPU,
    RadeonSensor,
    RadeonBoost,
    AppleIntelPIIXATA,
    SATAUnsupported,
    CtlnaAHCIPort,
    IntelMKLFixup,
    telemetrap,
    CryptexFixup,
    NoAVXFSCompressionTypeZlibAVXpel,
    NVMeFix,
    AMFIPass,
    Innie,
    FeatureUnlock,
    HibernationFixup,
    HoRNDIS,
    FakePCIID,
    CPUFriend,
    CPUFriendDataProvider,
    CpuTopologyRebuild,
    CpuTscSync,
    ForgedInvariant,
    TSCAdjustReset,
    VoodooTSCSync,
    RTCMemoryFixup,
    NullEthernet,
    RealtekRTL8100,
    AppleIntelE1000e,
    BCM5722D,
    AtherosL1cEthernet,
    RealtekRTL8111,
    AtherosE2200Ethernet,
    AppleIGC,
    AppleIGB,
    IntelMausi,
    IntelMausiEthernet,
    LucyRTL8125Ethernet,
    RTL812xLucy,
    SmallTreeIntel82576,
    IntelLucy,
    NoTouchID,
    NullCPUPowerManagement,
    GenericUSBXHCI,
    XLNCUSBFix,
    USBInjectAll,
    USBToolBox,
    UTBMap,
    XHCIUnsupported,
    DummyUSBEHCIPCI,
    DummyUSBXHCIPCI,
    HS80211Family,
    AirPortAtheros40_9285,
    AirPortAtheros40_9380,
    AirPortAtheros40_9485,
    AirPortAtheros40_9565,
    AirPortAtheros40_9462,
    AirPortAtheros40_9463,
    corecaptureElCap,
    IO80211ElCap,
    IO80211ElCap_AirPortAtheros40,
    IO80211ElCap_AirPortBrcm4331,
    IO80211ElCap_AppleAirPortBrcm43224,
    IOSkywalkFamily,
    IO80211FamilyLegacy,
    IO80211FamilyLegacyAirPortBrcmNIC,
    AirportBrcmFixup,
    AirportBrcmFixupAirPortBrcm4360_Injector,
    AirportBrcmFixupAirPortBrcmNIC_Injector,
    itlwm,
    AirportItlwm_Sequoia,
    AirportItlwm_Sonoma_14_4,
    AirportItlwm_Sonoma,
    AirportItlwm_Ventura,
    AirportItlwm_Monterey,
    AirportItlwm_BigSur,
    AirportItlwm_Catalina,
    AirportItlwm_Mojave,
    AirportItlwm_HighSierra,
    BlueToolFixup,
    IntelBluetoothInjector,
    IntelBluetoothFirmware,
    IntelBTPatcher,
    BrcmBluetoothInjector,
    BrcmBluetoothInjectorLegacy,
    BrcmFirmwareData,
    BrcmPatchRAM,
    BrcmPatchRAM2,
    BrcmPatchRAM3,
    Ath3kBT,
    Ath3kBTInjector,
    ApplePS2SmartTouchPad,
    ApplePS2SmartTouchPadApplePS2Controller,
    ApplePS2SmartTouchPadApplePS2Keyboard,
    VoodooPS2Controller,
    VoodooPS2ControllerVoodooInput,
    VoodooPS2ControllerVoodooPS2Keyboard,
    VoodooPS2ControllerVoodooPS2Mouse,
    VoodooPS2ControllerVoodooPS2Trackpad,
    BrightnessKeys,
    BigSurfaceVoodooGPIO,
    BigSurfaceVoodooSerial,
    BigSurfaceVoodooInput,
    BigSurface,
    BigSurfaceHIDDriver,
    VoodooI2CVoodooInput,
    VoodooI2CVoodooI2CServices,
    VoodooI2CVoodooGPIO,
    VoodooRMI,
    VoodooRMIVoodooInput,
    VoodooI2C,
    VoodooRMIRMII2C,
    VoodooSMBus,
    VoodooRMIRMISMBus,
    VoodooI2CHID,
    AppleIntelCPUPowerManagement,
    AppleIntelCPUPowerManagementClient,
    EmeraldSDHC,
    RealtekCardReader,
    RealtekCardReaderFriend,
    RtWlanU,
    RtWlanU1827,
  ];

  static KernelEmulate kernelEmulate_Haswell_Before =
      KernelEmulate(dummyPowerManagement: false);

  static KernelEmulate kernelEmulate_fakeCPU = KernelEmulate(
    cpuid1Mask: 'FFFFFFFF000000000000000000000000'.toBytes(),
    dummyPowerManagement: true,
  );

  static KernelEmulate kernelEmulate_IvyBridge = kernelEmulate_fakeCPU.copyWith(
      cpuid1Data: 'A0060300000000000000000000000000'.toBytes(),
      dummyPowerManagement: false);

  static KernelEmulate kernelEmulate_Haswell = kernelEmulate_fakeCPU.copyWith(
    cpuid1Data: 'A0060300000000000000000000000000'.toBytes(),
  );

  static KernelEmulate kernelEmulate_Broadwell = kernelEmulate_Haswell;

  static KernelEmulate kernelEmulate_Skylake = kernelEmulate_Haswell;

  static KernelEmulate kernelEmulate_KabyLake = kernelEmulate_Haswell;

  static KernelEmulate kernelEmulate_CoffeeLake = kernelEmulate_Haswell;

  static KernelEmulate kernelEmulate_CoffeeLakePlus = kernelEmulate_Haswell;

  static KernelEmulate kernelEmulate_CometLake = kernelEmulate_Haswell;

  static KernelEmulate kernelEmulate_CometLake_U62 =
      kernelEmulate_Broadwell.copyWith(
    cpuid1Data: 'EC060800000000000000000000000000'.toBytes(),
  );

  static KernelEmulate kernelEmulate_RocketLake_Later = kernelEmulate_Broadwell
      .copyWith(cpuid1Data: '55060A00000000000000000000000000'.toBytes());

  static KernelEmulate kernelEmulate_TigerLake_Later = kernelEmulate_Broadwell
      .copyWith(cpuid1Data: 'E5060700000000000000000000000000'.toBytes());

  static KernelEmulate kernelEmulate_Haswell_HEDT =
      kernelEmulate_fakeCPU.copyWith(
          cpuid1Data: 'C3060300000000000000000000000000'.toBytes(),
          dummyPowerManagement: false);

  static KernelEmulate kernelEmulate_Broadwell_HEDT =
      kernelEmulate_fakeCPU.copyWith(
          cpuid1Data: 'D4060300000000000000000000000000'.toBytes(),
          dummyPowerManagement: false);

  static List<KernelEmulate> kernelEmulateList_Desktop = [
    kernelEmulate_Haswell_Before,
    kernelEmulate_Haswell_Before,
    kernelEmulate_Haswell_Before,
    kernelEmulate_IvyBridge,
    kernelEmulate_Haswell,
    kernelEmulate_Broadwell,
    kernelEmulate_Skylake,
    kernelEmulate_KabyLake,
    kernelEmulate_CoffeeLake,
    kernelEmulate_CoffeeLakePlus,
    kernelEmulate_CometLake,
    kernelEmulate_RocketLake_Later,
    kernelEmulate_RocketLake_Later,
    kernelEmulate_RocketLake_Later,
    kernelEmulate_RocketLake_Later
  ];

  static List<KernelKext> kernelKextsList_desktop_0th = [
    Lilu,
    VirtualSMC,
    WhateverGreen,
    AppleALC,
    AppleIntelPIIXATA,
    telemetrap,
    SMCProcessor,
    SMCSuperIO,
    USBInjectAll
  ];

  static List<KernelKext> kernelKextsList_desktop_1th = [
    Lilu,
    VirtualSMC,
    WhateverGreen,
    AppleALC,
    SMCProcessor,
    SMCSuperIO,
    USBInjectAll
  ];

  static List<KernelKext> kernelKextsList_desktop_2th =
      kernelKextsList_desktop_1th;
  static List<KernelKext> kernelKextsList_desktop_3th =
      kernelKextsList_desktop_1th;
  static List<KernelKext> kernelKextsList_desktop_4th =
      kernelKextsList_desktop_1th;
  static List<KernelKext> kernelKextsList_desktop_5th =
      kernelKextsList_desktop_1th;
  static List<KernelKext> kernelKextsList_desktop_6th =
      kernelKextsList_desktop_1th;

  static List<KernelKext> kernelKextsList_desktop_7th =
      kernelKextsList_desktop_1th;
  static List<KernelKext> kernelKextsList_desktop_8th =
      kernelKextsList_desktop_1th;
  static List<KernelKext> kernelKextsList_desktop_9th =
      kernelKextsList_desktop_1th;
  static List<KernelKext> kernelKextsList_desktop_10th =
      kernelKextsList_desktop_1th;

  static List<KernelKext> kernelKextsList_desktop_11th =
      kernelKextsList_desktop_1th;
  static List<KernelKext> kernelKextsList_desktop_12th =
      kernelKextsList_desktop_11th;
  static List<KernelKext> kernelKextsList_desktop_13th =
      kernelKextsList_desktop_11th;
  static List<KernelKext> kernelKextsList_desktop_14th =
      kernelKextsList_desktop_11th;
  static List<KernelKext> kernelKextsList_desktop_15th =
      kernelKextsList_desktop_11th;

  static KernelQuirks kernelQuirks_desktop_0th = KernelQuirks(
    appleCpuPmCfgLock: true,
    disableIoMapper: true,
    disableLinkeditJettison: true,
    panicNoKextDump: true,
    powerTimeoutKernelPanic: true,
    xhciPortLimit: true,
  );

  static KernelQuirks kernelQuirks_desktop_1th =
      kernelQuirks_desktop_0th.copyWith();

  static KernelQuirks kernelQuirks_desktop_2th =
      kernelQuirks_desktop_1th.copyWith();

  static KernelQuirks kernelQuirks_desktop_3th =
      kernelQuirks_desktop_2th.copyWith();

  static KernelQuirks kernelQuirks_desktop_4th =
      kernelQuirks_desktop_3th.copyWith(
    appleCpuPmCfgLock: false,
    appleXcpmCfgLock: true,
  );

  static KernelQuirks kernelQuirks_desktop_5th =
      kernelQuirks_desktop_4th.copyWith();

  static KernelQuirks kernelQuirks_desktop_6th =
      kernelQuirks_desktop_4th.copyWith();

  static KernelQuirks kernelQuirks_desktop_7th =
      kernelQuirks_desktop_4th.copyWith();

  static KernelQuirks kernelQuirks_desktop_8th =
      kernelQuirks_desktop_4th.copyWith();

  static KernelQuirks kernelQuirks_desktop_9th =
      kernelQuirks_desktop_4th.copyWith();

  static KernelQuirks kernelQuirks_desktop_10th =
      kernelQuirks_desktop_4th.copyWith();

  static KernelQuirks kernelQuirks_desktop_11th =
      kernelQuirks_desktop_4th.copyWith();

  static KernelQuirks kernelQuirks_desktop_12th =
      kernelQuirks_desktop_11th.copyWith(provideCurrentCpuInfo: true);

  static KernelQuirks kernelQuirks_desktop_13th =
      kernelQuirks_desktop_12th.copyWith();

  static KernelQuirks kernelQuirks_desktop_14th =
      kernelQuirks_desktop_12th.copyWith();

  static KernelQuirks kernelQuirks_desktop_15th =
      kernelQuirks_desktop_12th.copyWith();

  static List<KernelKext> kernelKextsList_laptop_0th = [
    Lilu,
    VirtualSMC,
    WhateverGreen,
    AppleALC,
    AppleIntelPIIXATA,
    telemetrap,
    SMCProcessor,
    SMCSuperIO,
    ACPIBatteryManager,
    USBInjectAll,
    ApplePS2SmartTouchPad,
    ApplePS2SmartTouchPadApplePS2Controller,
    ApplePS2SmartTouchPadApplePS2Keyboard,
  ];

  static List<KernelKext> kernelKextsList_laptop_1th = [
    Lilu,
    VirtualSMC,
    WhateverGreen,
    AppleALC,
    SMCProcessor,
    SMCSuperIO,
    ACPIBatteryManager,
    USBInjectAll,
    ApplePS2SmartTouchPad,
    ApplePS2SmartTouchPadApplePS2Controller,
    ApplePS2SmartTouchPadApplePS2Keyboard,
  ];

  static List<KernelKext> kernelKextsList_laptop_2th =
      kernelKextsList_laptop_1th;
  static List<KernelKext> kernelKextsList_laptop_3th = [
    Lilu,
    VirtualSMC,
    WhateverGreen,
    AppleALC,
    SMCProcessor,
    SMCSuperIO,
    SMCBatteryManager,
    USBInjectAll,
    VoodooPS2Controller,
    VoodooPS2ControllerVoodooInput,
    VoodooPS2ControllerVoodooPS2Keyboard,
    VoodooPS2ControllerVoodooPS2Mouse,
    VoodooPS2ControllerVoodooPS2Trackpad,
  ];

  static List<KernelKext> kernelKextsList_laptop_4th =
      kernelKextsList_laptop_3th;

  static List<KernelKext> kernelKextsList_laptop_5th =
      kernelKextsList_laptop_3th;

  static List<KernelKext> kernelKextsList_laptop_6th = [
    Lilu,
    VirtualSMC,
    WhateverGreen,
    AppleALC,
    SMCProcessor,
    SMCSuperIO,
    SMCBatteryManager,
    USBInjectAll,
    VoodooPS2Controller,
    VoodooPS2ControllerVoodooPS2Keyboard,
    VoodooI2C,
    VoodooI2CVoodooInput,
    VoodooI2CVoodooI2CServices,
    VoodooI2CVoodooGPIO,
    VoodooI2CHID,
  ];
  static List<KernelKext> kernelKextsList_laptop_7th =
      kernelKextsList_laptop_6th;
  static List<KernelKext> kernelKextsList_laptop_8th =
      kernelKextsList_laptop_6th;
  static List<KernelKext> kernelKextsList_laptop_9th =
      kernelKextsList_laptop_6th;
  static List<KernelKext> kernelKextsList_laptop_10th_cometLake =
      kernelKextsList_laptop_6th;

  static List<KernelKext> kernelKextsList_laptop_10th_IceLake =
      kernelKextsList_laptop_6th;

  static KernelQuirks kernelQuirks_laptop_0th = KernelQuirks(
    appleCpuPmCfgLock: true,
    disableIoMapper: true,
    disableLinkeditJettison: true,
    panicNoKextDump: true,
    powerTimeoutKernelPanic: true,
    xhciPortLimit: true,
  );

  static KernelQuirks kernelQuirks_laptop_1th =
      kernelQuirks_laptop_0th.copyWith();

  static KernelQuirks kernelQuirks_laptop_2th =
      kernelQuirks_laptop_0th.copyWith();

  static KernelQuirks kernelQuirks_laptop_3th =
      kernelQuirks_laptop_0th.copyWith();

  static KernelQuirks kernelQuirks_laptop_4th = kernelQuirks_laptop_0th
      .copyWith(appleCpuPmCfgLock: false, appleXcpmCfgLock: true);

  static KernelQuirks kernelQuirks_laptop_5th =
      kernelQuirks_laptop_4th.copyWith();

  static KernelQuirks kernelQuirks_laptop_6th =
      kernelQuirks_laptop_4th.copyWith();

  static KernelQuirks kernelQuirks_laptop_7th =
      kernelQuirks_laptop_4th.copyWith();

  static KernelQuirks kernelQuirks_laptop_8th =
      kernelQuirks_laptop_4th.copyWith();

  static KernelQuirks kernelQuirks_laptop_9th =
      kernelQuirks_laptop_4th.copyWith();

  static KernelQuirks kernelQuirks_laptop_10th_cometLake =
      kernelQuirks_laptop_4th.copyWith();

  static KernelQuirks kernelQuirks_laptop_10th_IceLake =
      kernelQuirks_laptop_4th.copyWith();

  static KernelQuirks kernelQuirks_laptop_11th_TigerLake =
      kernelQuirks_laptop_4th.copyWith(
          appleCpuPmCfgLock: true, appleXcpmExtraMsrs: true);

  static KernelQuirks kernelQuirks_laptop_12th_AlderLake =
      kernelQuirks_laptop_11th_TigerLake.copyWith(provideCurrentCpuInfo: true);

  static List<KernelKext> kernelKextsList_nuc_0th = [
    Lilu,
    VirtualSMC,
    WhateverGreen,
    AppleALC,
    AppleIntelPIIXATA,
    telemetrap,
    SMCProcessor,
    SMCSuperIO,
    USBInjectAll
  ];

  static List<KernelKext> kernelKextsList_nuc_1th = [
    Lilu,
    VirtualSMC,
    WhateverGreen,
    AppleALC,
    SMCProcessor,
    SMCSuperIO,
    USBInjectAll
  ];

  static List<KernelKext> kernelKextsList_nuc_2th = kernelKextsList_nuc_1th;
  static List<KernelKext> kernelKextsList_nuc_3th = kernelKextsList_nuc_2th;

  static List<KernelKext> kernelKextsList_nuc_4th = kernelKextsList_nuc_2th;

  static List<KernelKext> kernelKextsList_nuc_5th = kernelKextsList_nuc_2th;

  static List<KernelKext> kernelKextsList_nuc_6th = kernelKextsList_nuc_2th;
  static List<KernelKext> kernelKextsList_nuc_7th = kernelKextsList_nuc_2th;
  static List<KernelKext> kernelKextsList_nuc_8th = kernelKextsList_nuc_2th;
  static List<KernelKext> kernelKextsList_nuc_9th = kernelKextsList_nuc_2th;
  static List<KernelKext> kernelKextsList_nuc_10th_cometLake =
      kernelKextsList_nuc_2th;

  static List<KernelKext> kernelKextsList_nuc_10th_IceLake =
      kernelKextsList_nuc_2th;

  static KernelQuirks kernelQuirks_nuc_0th = KernelQuirks(
    appleCpuPmCfgLock: true,
    disableIoMapper: true,
    disableLinkeditJettison: true,
    panicNoKextDump: true,
    powerTimeoutKernelPanic: true,
    xhciPortLimit: true,
  );

  static KernelQuirks kernelQuirks_nuc_1th = kernelQuirks_nuc_0th.copyWith();

  static KernelQuirks kernelQuirks_nuc_2th = kernelQuirks_nuc_0th.copyWith();

  static KernelQuirks kernelQuirks_nuc_3th = kernelQuirks_nuc_0th.copyWith();

  static KernelQuirks kernelQuirks_nuc_4th = kernelQuirks_nuc_0th.copyWith(
    appleCpuPmCfgLock: false,
    appleXcpmCfgLock: true,
  );

  static KernelQuirks kernelQuirks_nuc_5th = kernelQuirks_nuc_4th.copyWith();

  static KernelQuirks kernelQuirks_nuc_6th = kernelQuirks_nuc_4th.copyWith();

  static KernelQuirks kernelQuirks_nuc_7th = kernelQuirks_nuc_4th.copyWith();

  static KernelQuirks kernelQuirks_nuc_8th = kernelQuirks_nuc_4th.copyWith();

  static KernelQuirks kernelQuirks_nuc_9th = kernelQuirks_nuc_4th.copyWith();

  static KernelQuirks kernelQuirks_nuc_10th_cometLake =
      kernelQuirks_nuc_4th.copyWith();

  static KernelQuirks kernelQuirks_nuc_10th_IceLake =
      kernelQuirks_nuc_4th.copyWith();

  static KernelQuirks kernelQuirks_nuc_11th_TigerLake = kernelQuirks_nuc_4th
      .copyWith(appleCpuPmCfgLock: true, appleXcpmExtraMsrs: true);

  static KernelQuirks kernelQuirks_nuc_12th_AlderLake =
      kernelQuirks_nuc_11th_TigerLake.copyWith(provideCurrentCpuInfo: true);

  static List<KernelKext> kernelKextsList_hedt_1th = [
    Lilu,
    VirtualSMC,
    WhateverGreen,
    AppleALC,
    SMCProcessor,
    SMCSuperIO,
    USBInjectAll
  ];

  static List<KernelKext> kernelKextsList_hedt_2th = kernelKextsList_hedt_1th;
  static List<KernelKext> kernelKextsList_hedt_3th = kernelKextsList_hedt_1th;

  static List<KernelKext> kernelKextsList_hedt_4th = kernelKextsList_hedt_1th;

  static List<KernelKext> kernelKextsList_hedt_5th = kernelKextsList_hedt_1th;

  static List<KernelKext> kernelKextsList_hedt_6th = kernelKextsList_hedt_1th;
  static List<KernelKext> kernelKextsList_hedt_10th = kernelKextsList_hedt_1th;

  static KernelQuirks kernelQuirks_hedt_1th = KernelQuirks(
    appleCpuPmCfgLock: true,
    appleXcpmExtraMsrs: true,
    disableIoMapper: true,
    disableLinkeditJettison: true,
    panicNoKextDump: true,
    powerTimeoutKernelPanic: true,
    xhciPortLimit: true,
  );

  static KernelQuirks kernelQuirks_hedt_2th = kernelQuirks_hedt_1th.copyWith();

  static KernelQuirks kernelQuirks_hedt_3th = kernelQuirks_hedt_1th.copyWith();

  static KernelQuirks kernelQuirks_hedt_4th = KernelQuirks(
    appleXcpmCfgLock: true,
    appleXcpmExtraMsrs: true,
    disableIoMapper: true,
    disableLinkeditJettison: true,
    panicNoKextDump: true,
    powerTimeoutKernelPanic: true,
    xhciPortLimit: true,
  );

  static KernelQuirks kernelQuirks_hedt_5th = kernelQuirks_hedt_4th.copyWith();

  static KernelQuirks kernelQuirks_hedt_6th = KernelQuirks(
    appleXcpmCfgLock: true,
    disableIoMapper: true,
    disableLinkeditJettison: true,
    panicNoKextDump: true,
    powerTimeoutKernelPanic: true,
    xhciPortLimit: true,
  );

  static KernelQuirks kernelQuirks_hedt_10th = kernelQuirks_hedt_6th.copyWith();

  static List<KernelKext> kernelKextsList_amd_desktop_legacy = [
    Lilu,
    VirtualSMC,
    WhateverGreen,
    AppleALC,
    USBInjectAll
  ];

  static List<KernelKext> kernelKextsList_amd_desktop_ryzen = [
    Lilu,
    VirtualSMC,
    WhateverGreen,
    AppleALC,
    USBInjectAll
  ];

  static KernelEmulate kernelEmulate_amd =
      KernelEmulate(dummyPowerManagement: true);

  static KernelQuirks kernelQuirks_amd_desktop_legacy = KernelQuirks(
    disableLinkeditJettison: true,
    panicNoKextDump: true,
    powerTimeoutKernelPanic: true,
    provideCurrentCpuInfo: true,
    xhciPortLimit: true,
  );

  static KernelQuirks kernelQuirks_amd_desktop_ryzen = KernelQuirks(
    disableLinkeditJettison: true,
    panicNoKextDump: true,
    powerTimeoutKernelPanic: true,
    provideCurrentCpuInfo: true,
    xhciPortLimit: true,
  );

  static List<KernelKext> kernelKextsList_amd_laptop_legacy = [
    Lilu,
    VirtualSMC,
    WhateverGreen,
    AppleALC,
    SMCBatteryManager,
    GenericUSBXHCI,
    USBInjectAll,
    VoodooPS2Controller,
    VoodooPS2ControllerVoodooInput,
    VoodooPS2ControllerVoodooPS2Keyboard,
    VoodooPS2ControllerVoodooPS2Mouse,
    VoodooPS2ControllerVoodooPS2Trackpad,
  ];

  static List<KernelKext> kernelKextsList_amd_laptop_ryzen = [
    Lilu,
    VirtualSMC,
    WhateverGreen,
    AppleALC,
    GenericUSBXHCI,
    SMCBatteryManager,
    USBInjectAll,
    VoodooPS2Controller,
    VoodooPS2ControllerVoodooPS2Keyboard,
    VoodooI2C,
    VoodooI2CVoodooInput,
    VoodooI2CVoodooI2CServices,
    VoodooI2CVoodooGPIO,
    VoodooI2CHID,
  ];

  ///
  static KernelQuirks kernelQuirks_amd_laptop_legacy = KernelQuirks(
    disableLinkeditJettison: true,
    panicNoKextDump: true,
    powerTimeoutKernelPanic: true,
    provideCurrentCpuInfo: true,
    xhciPortLimit: true,
  );

  static KernelQuirks kernelQuirks_amd_laptop_ryzen = KernelQuirks(
    disableLinkeditJettison: true,
    panicNoKextDump: true,
    powerTimeoutKernelPanic: true,
    provideCurrentCpuInfo: true,
    xhciPortLimit: true,
  );

  static List<KernelKext> kernelKextsList_amd_nuc_legacy = [
    Lilu,
    VirtualSMC,
    WhateverGreen,
    AppleALC,
    USBInjectAll
  ];

  static List<KernelKext> kernelKextsList_amd_nuc_ryzen = [
    Lilu,
    VirtualSMC,
    WhateverGreen,
    AppleALC,
    USBInjectAll
  ];

  ///
  static KernelQuirks kernelQuirks_amd_nuc_legacy = KernelQuirks(
    disableLinkeditJettison: true,
    panicNoKextDump: true,
    powerTimeoutKernelPanic: true,
    provideCurrentCpuInfo: true,
    xhciPortLimit: true,
  );

  static KernelQuirks kernelQuirks_amd_nuc_ryzen = KernelQuirks(
    disableLinkeditJettison: true,
    panicNoKextDump: true,
    powerTimeoutKernelPanic: true,
    provideCurrentCpuInfo: true,
    xhciPortLimit: true,
  );

  static List<KernelKext> kernelKextsList_amd_hedt_ryzen = [
    Lilu,
    VirtualSMC,
    WhateverGreen,
    AppleALC,
    USBInjectAll
  ];

  static KernelQuirks kernelQuirks_amd_hedt_ryzen = KernelQuirks(
    disableLinkeditJettison: true,
    panicNoKextDump: true,
    powerTimeoutKernelPanic: true,
    provideCurrentCpuInfo: true,
    xhciPortLimit: true,
  );

  static List<KernelTrim> kernelTrims = [
    const KernelTrim(
        value: -1,
        comment: '默认配置TRIM策略(即设置SetApfsTrimTimeout = -1)',
        note: [
          '1.APFS系统根据macOS的默认TRIM超时时间来执行TRIM操作,适用于大部分支持TRIM的SSD',
          '2.在支持 TRIM 的 SSD 上,macOS 自动管理 TRIM 的执行，有助于清理已删除数据块，使 SSD 的写入效率更高，避免了频繁的写入放大，提升写入速度',
          '3.TRIM 会定期清理未使用的块,减少 SSD 的磨损,从而延长 SSD 使用寿命',
          '4.某些不完全支持 TRIM 的第三方 SSD 在执行 TRIM 时可能会出现延迟，甚至出现卡顿现象，导致开机过程变得非常缓慢'
        ]),
    const KernelTrim(
        value: 0,
        comment: '完全禁用TRIM功能(即设置SetApfsTrimTimeout = 0)',
        note: [
          '禁用TRIM好处:',
          '1.提升开机速度,对于不支持或部分支持TRIM的第三方SSD,macOS在启动时可能会因为尝试TRIM操作导致延迟.禁用TRIM可以消除这一延迟,提高开机速度',
          '2.提升兼容性,部分兼容性差的SSD可以减少异常崩溃风险',
          '3.延长非TRIM SSD的寿命,在不支持TRIM的SSD上,强行启用TRIM可能反而加速磨损,影响寿命.禁用TRIM 可以延长此类SSD的使用寿命',
          '禁用TRIM坏处:',
          '1.SSD性能下降,部分SSD没有了TRIM的垃圾回收机制,SSD在删除数据后无法及时清理和标记空闲块,可能会导致写入速度变慢',
          '2.磁盘空间管理效率降低,禁用后,SSD的控制器需要更多的时间和资源来进行垃圾回收,可能导致碎片增多、空间管理效率降低',
          '3.缩短SSD的寿命,支持TRIM的SSD,禁用TRIM后,SSD无法优化写入过程,使存储块磨损加剧,从而缩短支持TRIM的SSD的寿命.',
          '虽然禁用 TRIM 能带来一定的开机速度提升，但对于支持 TRIM 的现代 SSD 来说，建议保持 TRIM 开启，以获得长期的性能和稳定性。这种速度提升通常较小,只有在一些不兼容的 SSD 上才会有明显效果',
        ])
  ];
}
