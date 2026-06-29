//  table.dart
//  Created by JeoJay127
//
extension MapExtension on Map<String, dynamic> {
  String get name => this['name'] ?? '';
}

class ACPITable {
  static const ssdtHPET = {
    'name': 'SSDT-HPET',
    'remark': '消除IRQ冲突,通常用于声卡修复',
    'note': '''
•	HPET(High Precision Event Timer,高精度事件计时器)是用于系统定时的硬件模块。
•	在 macOS 下,一些主板的 HPET 设备可能会导致 IRQ(中断请求)冲突，进而影响音频设备的正常工作,导致系统不稳定、甚至无法启动。
•	该补丁通过调整 HPET 相关的 ACPI 设备定义，避免 IRQ 冲突，确保 macOS 能够正确使用 HPET 计时器，修复声卡问题,提高系统稳定性等。
   ''',
  };

  static const ssdtECUSBXDesktop = {
    'name': 'SSDT-EC-USBX-DESKTOP',
    'remark': '仿冒EC并注入USB电源属性(适用于Intel 6代及以上台式机)',
    'note': '''
•	适用于Intel 6代及以上台式机
•	该补丁会禁用系统原有 EC 设备,然后创建一个虚拟的 EC 设备，以“欺骗” macOS 认为存在一个兼容的 EC，从而解决因 EC 设备缺失导致的启动问题。 
•	添加必要的USB电源属性以修复潜在的问题。等同于合并: SSDT-EC-DESKTOP.aml + SSDT-USBX.aml
        ''',
  };

  static const ssdtECUSBXLaptop = {
    'name': 'SSDT-EC-USBX-LAPTOP',
    'remark': '仅仿冒EC,不影响现有EC，同时注入USB电源属性(适用于Intel 6代及以上笔记本）',
    'note': '''
•	适用于Intel 6代及以上笔记本
•	适用于笔记本,它不会删除或修改现有的 EC,而是单独创建一个新的虚拟 EC，避免破坏原始 EC 设备，防止可能导致笔记本电源管理、键盘背光等功能异常。
•	添加必要的USB电源属性以修复潜在的问题。等同于合并: SSDT-EC-LAPTOP.aml + SSDT-USBX.aml
''',
  };

  static const ssdtECDesktop = {
    'name': 'SSDT-EC-DESKTOP',
    'remark': '仿冒EC(适用于Intel 5代及以下台式机)',
    'note': '''
•	适用于Intel 5代及以下台式机
•	该补丁会禁用系统原有 EC 设备,然后创建一个虚拟的 EC 设备，以“欺骗” macOS 认为存在一个兼容的 EC，从而解决因 EC 设备缺失导致的启动问题。 
        ''',
  };

  static const ssdtECLaptop = {
    'name': 'SSDT-EC-LAPTOP',
    'remark': '仅仿冒EC,不影响现有EC(适用于Intel 5代及以下笔记本）',
    'note': '''
•	适用于Intel 5代及以下笔记本
•	它不会删除或修改现有的 EC,而是单独创建一个新的虚拟 EC，避免破坏原始 EC 设备，防止可能导致笔记本电源管理、键盘背光等功能异常。
''',
  };

  static const ssdtUSBX = {
    'name': 'SSDT-USBX',
    'remark': 'USB电源属性修正(适用于Intel 6代及更新平台)',
    'note': '''
•	适用于Intel Skylake 6代及以上, 服务器Haswell-E 4代及以上，AMD Ryzen等平台
•	从 Intel Skylake 及更新的处理器开始，macOS 需要特定的 USB 电源属性，以确保 USB 设备能够正确供电和识别。
•	该补丁修正 USB 端口的电源管理，使其符合 macOS 要求，解决 USB 设备识别异常、供电不足、无法热插拔等问题。
•	对于笔记本: SSDT-EC-LAPTOP.aml + SSDT-USBX.aml 两者合并等同于 SSDT-EC-USBX-LAPTOP.aml
•	对于台式机: SSDT-EC-DESKTOP.aml + SSDT-USBX.aml 两者合并等同于 SSDT-EC-USBX-DESKTOP.aml
''',
  };

  static const ssdtPLUG = {
    'name': 'SSDT-PLUG',
    'remark': 'CPU核心识别,启用频率调节与节能修正',
    'note': '''
•	SSDT-PLUG 适用于Intel Haswell 4代 ~ 11代, 服务器Haswell-E 4代及以上平台 (定制SSDT-PLUG时,工具自动检测生成!)
•	SSDT-PLUG-ALT 适用于Intel Alder Lake 12代及以上,以及AMD Ryzen平台 (定制SSDT-PLUG时,工具自动检测生成并更名为SSDT-PLUG-ALT!)
•	macOS 依赖 CPU 电源管理插件（PluginType）来调节 CPU 频率，提高能效和续航。
•	该补丁会修改 CPU 定义，使 macOS 认为它是 Apple 设备所需的 plugin-type = 1 处理器，从而正确加载 CPU 变频管理，提高性能和功耗控制。
          ''',
  };

  static const ssdtPMC = {
    'name': 'SSDT-PMC',
    'remark': '启用NVRAM支持(通常适用于Intel原生300系列主板)',
    'note': '''
•	适用于Intel Coffee Lake 8代 ~ 9代平台
•	原生 300 系列主板（如 Z370、B360）在 macOS 下可能无法正确使用 NVRAM，导致部分功能（如 iMessage、音量记忆、引导参数等）无法保存。
•	该补丁启用主板的 PMC（Power Management Controller，电源管理控制器），让 macOS 正常使用原生 NVRAM，而无需额外的 EmuVariableUEFI 驱动。
''',
  };

  static const ssdtPNLF = {
    'name': 'SSDT-PNLF',
    'remark': '添加PNLF设备以提供背光支持(仅适用于笔记本和一体机)',
    'note': '''
•	macOS 需要 PNLF 设备（Panel Brightness）才能正确控制笔记本屏幕的亮度。
•	该补丁会在 ACPI 中创建一个 PNLF 设备,使 macOS 能够调节屏幕亮度，并在系统偏好设置中显示亮度控制选项。
•	适用于笔记本和部分一体机,解决亮度调节不可用的问题。
•	UID = 14, 适用于: Intel第1代Arrandale,第2代Sandy Bridge,第3代Ivy Bridge 
  注意:有些机器使用UID: 14 会遇到最大亮度受限或其他问题.为了解决这些问题,必须设置正确的 iGPU（集成显卡）的设备路径，并且可能需要补充IGPU寄存器信息
•	UID = 15, 适用于: Intel第4代Haswell,第5代Broadwell
•	UID = 16, 适用于: Intel第6代Skylake,第7代Kaby Lake, 某些第4代Haswell
•	UID = 17, 适用于: 自定义亮度,通常用于一些非标准设备或特殊需求的 Hackintosh（黑苹果）设置
•	UID = 18, 适用于: 自定义亮度,通常用于一些非标准设备或特殊需求的 Hackintosh（黑苹果）设置
•	UID = 19, 适用于: Intel第8代CoffeeLake及以上,10代以下,以及AMD笔记本
•	UID = 99, 适用于: 其他（需要自定义 applbkl-name / applbkl-data 设备属性）,可能根本无法正常工作
''',
  };

  static const ssdtALS0 = {
    'name': 'SSDT-ALS0',
    'remark': '提供屏幕背光调节所需的传感器支持(仅适用于笔记本和一体机)',
    'note': '''
•	用于模拟和启用 Apple 原生传感器(光线传感器 Ambient Light Sensor,简称ALS)功能,以实现自动调节屏幕亮度
•	如果你的设备真的有ALS(如某些高端笔记本),并且存在问题,可以尝试添加SSDT-ALS0来修正自动亮度调节功能,否则不建议添加
•	适用范围：仅限一体机 (AIO) 和笔记本电脑
          ''',
  };

  static const ssdtXOSI = {
    'name': 'SSDT-XOSI',
    'remark': 'macOS伪装成Windows,解锁被屏蔽的设备(如I2C触摸板)',
    'note': '''
•	_OSI（Operating System Interface）是 ACPI 的一个方法，允许操作系统报告自己支持哪些功能。
•	一些主板固件可能会根据 _OSI 返回值来决定是否启用某些设备，而 macOS 可能不被识别，从而导致功能缺失。
•	该补丁会“欺骗”固件，使其认为 macOS 也是 Windows，从而激活隐藏的功能，如：I2C 触摸板、电池管理等。
          ''',
  };

  static const ssdtRHUB = {
    'name': 'SSDT-RHUB',
    'remark': 'USB端口重置与修正',
    'note': '''
•	某些OEM违反了ACPI规范，这导致在启动macOS时出现问题。为了解决这个问题，需要关闭RHUB设备，并强制macOS手动重建端口。
•	该补丁在 macOS 启动时重置 USB 控制器(包括EHC1,EHC2等USB设备屏蔽和更名),使得所有 USB 端口可以正确识别,并配合 USB 映射（如:UTBMap.kext）使用,以确保 USB 设备正常工作。
• 通常适用于桌面端400系主板(华硕等)以及移动端IceLake平台(戴尔,联想等)。
''',
  };

  static const ssdtBridge = {
    'name': 'SSDT-Bridge',
    'remark': '为缺失的 PCI 设备路径创建桥接',
    'note': '''
•	一些主板或设备的 PCI 设备路径可能在 macOS 下无法正确识别，导致设备无法正常工作，例如: 显卡、声卡、无线网卡等。
•	该补丁会为这些设备创建正确的 PCI 桥接，确保 macOS 能够正确识别并使用这些 PCI 设备。
''',
  };

  static const ssdtAPIC = {
    'name': 'SSDT-APIC',
    'remark': '修正APIC表,解决CPU内核panic问题(适用于HEDT服务器平台)',
    'note': '''
•	修复或重写 APIC 表中的 Processor ID,确保 macOS 能正确识别 CPU 核心数量和编号,避免内核 panic 或核心识别错误。
•	需在固件中 Drop 掉原有 APIC 表，才能加载修补后的表。
•	适用于X58, X79, X99, X299 等 Intel 服务器(HEDT)平台。
''',
  };

  static const ssdtDMAR = {
    'name': 'SSDT-DMAR',
    'remark': '移除DMAR保留内存区域,修复系统启动问题,网卡兼容性问题',
    'note': '''
•	DMAR（DMA Remapping Table）是 Intel VT-d 虚拟化技术的一部分，用于 IOMMU（输入输出内存管理单元）支持。
•	该补丁会移除 DMAR 表中导致问题的保留内存区域，从而避免 macOS 误读 DMAR 导致系统无法启动。
•	为 VT-d 兼容性提供支持，让 VT-d 在 macOS Big Sur 及更新版本中正常工作，尤其是涉及使用 DriverKit 驱动的硬件。
•	macOS 支持 VT-d，但某些主板或 BIOS 提供的 DMAR 表存在兼容性问题，可能导致 macOS 在解析 ACPI DMAR 表时内核崩溃、卡启动、系统不稳定等问题(卡在 AppleACPICPU、IOPCI、AppleVTD 相关日志位置)。
•	支持的硬件范围： I225 网卡、Aquantia 网卡、部分 WiFi 设备等。
•	需在固件中 Drop 掉原有 DMAR 表，才能加载修补后的表。
•	适用 CPU： 任何支持 VT-d 技术的处理器。
''',
  };

  static const ssdtSBUSMCHC = {
    'name': 'SSDT-SBUS-MCHC',
    'remark': '添加系统总线SMBus支持',
    'note': '''
•	macOS 需要 SMBus（System Management Bus） 设备才能正确运行某些服务，如：
  I2C 触摸板，电池管理，光感自动亮度调节，某些 Wi-Fi / 蓝牙设备
•	SSDT-SBUS-MCHC 通过在 ACPI 中添加 SBUS（系统管理总线）和 MCHC（内存控制器）设备，使 macOS 认为这是一个原生的 Apple 设备，确保相关功能正常工作。
•	如果设备 I2C 触摸板、电池信息、自动亮度调节无法使用，可以尝试启用该补丁。
''',
  };

  static const ssdtIMEI = {
    'name': 'SSDT-IMEI',
    'remark': '修复核显加速失败问题(通常适用于Ivy Bridge和 Sandy Bridge)',
    'note': '''
•	Intel Management Engine(简称IMEI)是用于连接管理引擎的硬件接口,只有在旧平台(Sandy/Ivy)和某些主板缺少 MEI/IMEI/HECI 设备时才需要
•	适用于Intel第3代Ivy Bridge处理器,6系主板混合时(例如：i3 3225处理器，H61主板),核显加速问题
•	适用于Intel第2代Sandy Bridge处理器,7系主板混合时(例如：i5 2500k处理器，B75主板),核显加速问题
•	Intel第3代Ivy Bridge处理器搭配7系主板,以及Intel第2代Sandy Bridge处理器搭配6系主板,不需要此SSDT!
• Intel第4代Haswell及更新平台,通常能正确实现 MEI/IMEI/HECI 设备,不需要此SSDT!
          ''',
  };

  static const ssdtFixShutdown = {
    'name': 'SSDT-FixShutdown',
    'remark': '修复关机变重启或关机不断电问题',
    'note': '''
•	修复某些主板在macOS执行关机（S5）时，有时不会完全关闭 USB 控制器电源导致无法正常关机问题(关机变重启或关机不断电)
•	需要搭配 ACPI 重命名补丁： _PTS -> ZPTS 
''',
  };

  static const checkSystemState = {
    'name': 'Check-System-State',
    'remark': '检查当前系统状态,主要查看是否支持S3睡眠(非定制SSDT)',
    'note': '''
•	检查当前机器是否为AOAC机器(非定制SSDT)
•	检查当前BIOS设置中系统状态,主要查看是否支持S3睡眠(非定制SSDT)
•	注意:非AOAC机器才兼容S3睡眠,AOAC机器与S3睡眠冲突,不支持S3睡眠!
•	如果非AOAC机器(AOAC机器不支持S3睡眠,不用往下看)检查结果显示系统状态不支持S3睡眠,可能存在如下几种情况:
  1. 主板固件支持S3睡眠,但是BIOS设置中未开启S3睡眠,开启后可支持S3睡眠
  2. 主板固件物理未阉割 S3,只是 DSDT 未定义 _S3 方法,补全 _S3 方法有概率修复 S3 睡眠问题
  3. 主板固件物理阉割 S3,完全不支持S3睡眠,就算补全 _S3 方法,也无法修复 S3 睡眠问题
''',
  };

  static const checkAOAC = {
    'name': 'Check-AOAC',
    'remark': '检查当前是否为AOAC机器(非定制SSDT)',
    'note': '''
•	根据FACP.aml检查当前是否为AOAC机器(非定制SSDT)
•	注意:非AOAC机器才兼容S3睡眠,AOAC机器与S3睡眠冲突,不支持S3睡眠!AOAC机器常见于笔记本
•	AOAC机器一旦进入S3睡眠,可能出现：睡眠后无法被唤醒，呈现死机状态，只能强制关机。建议禁用S3睡眠。
•	AOAC机器建议考虑如下解决方案:
  1. 解锁BIOS,禁用AOAC(通常很难办到,但是最稳定)
  2. 禁用S3睡眠 (在BIOS中禁用S3睡眠,或者SSDT-S3-DISABLE禁用S3睡眠)
  3. 关闭独显供电电源
  4. 使用 NVMeFix.kext 开启 SSD 的 APST
  5. 启用 ASPM（BIOS 高级选项启用ASPM,SSDT 补丁启用 L1）
''',
  };

  static const ssdtGPRW = {
    'name': 'SSDT-GPRW',
    'remark': '修复由于USB控制器导致睡眠即醒问题',
    'note': '''
•	将GPRW重命名为XPRW,修复即时唤醒问题(注意:可能导致USB键盘无法唤醒设备,可以通过电源键唤醒)
•	SSDT-GPRW比较常用,因为绝大多数平台都是GPRW方法,极少数平台提供并使用UPRW方法
•	适用于Skylake及更新平台
''',
  };

  static const ssdtUPRW = {
    'name': 'SSDT-UPRW',
    'remark': '修复由于USB控制器导致睡眠即醒问题',
    'note': '''
•	将GPRW重命名为XPRW,修复即时唤醒问题(注意:可能导致USB键盘无法唤醒设备,可以通过电源键唤醒)
•	很少用到SSDT-UPRW,因为绝大多数平台都是GPRW方法,极少数平台提供并使用UPRW方法
•	适用于Skylake及更新平台
''',
  };
  static const ssdtLID = {
    'name': 'SSDT-LID',
    'remark': '修复睡眠按键睡眠问题(适用于笔记本)',
    'note': '''
•	某些电脑通过睡眠按键SLPB（PNP0C0E） 进入睡眠时,由于 ACPI 传递错误参数,导致 macOS 误认为是关机,可能导致:直接重启,睡眠后崩溃,或者睡眠成功但系统状态损坏
•	在按下睡眠键时伪装“盖子合上”，把危险的 PNP0C0E 睡眠强制转换成安全稳定的 PNP0C0D 睡眠
•	通常适用于笔记本电脑
''',
  };

  static const ssdtWakeScreen = {
    'name': 'SSDT-WakeScreen',
    'remark': '修复唤醒后需按任意键亮屏问题',
    'note': '''
•	修复某些机器唤醒后需按任意键才能亮屏的问题
''',
  };

  static const ssdtLED = {
    'name': 'SSDT-LED',
    'remark': '修复唤醒后电源键呼吸灯异常问题(适用于联想笔记本)',
    'note': '''
•	修复某些联想笔记本唤醒后 A 面呼吸灯和电源键呼吸灯未恢复正常的问题
•	修复某些联想笔记本上唤醒后 F4 麦克风指示灯状态不正常的问题
•	主要适用于联想系列笔记本,其他品牌笔记本通常不适用
''',
  };

  static const ssdtS3Disable = {
    'name': 'SSDT-S3-DISABLE',
    'remark': '禁用系统 S3 睡眠状态(修复S3睡眠唤醒崩溃,重启或关机问题)',
    'note': '''
•	仅禁用macOS系统下 S3 睡眠状态,避免macOS系统唤醒时出现系统崩溃、重启或关机
•	禁用后,仅macOS不再支持S3睡眠(点击睡眠按钮或者显示器进入节能模式,屏幕关闭,但是主机仍然会运行,风扇也不会停止运转)
•	禁用macOS系统下 S3 睡眠状态后,不再需要修改macOS任何系统设置,可以不用关闭节能模式(在此之前,你可能需要修改系统设置->不活跃时关闭显示器->永不)
•	适用场景:在没有修复睡眠问题时,macOS系统设置里节能模式开启("不活跃时关闭显示器->10分钟"),系统进入睡眠状态后,当唤醒macOS系统,可能出现系统崩溃、重启或关机.此时可以禁用S3睡眠状态,即可修复该问题.
•	需要搭配 ACPI 重命名补丁： _S3 -> XS3 
''',
  };

  static const ssdtFACP = {
    'name': 'SSDT-FACP',
    'remark': '热重启修改为冷重启,修复部分硬件不可用的问题',
    'note': '''
•	热重启修改为冷重启，修复部分平台从Windows重启到macOS后,导致部分硬件不可用的问题。(比如：声卡,WiFi,蓝牙)
•	注意: 没有SSDT-FACP.aml生成! 只生成ACPI - Patch补丁! 
''',
  };

  static const ssdtGPUSPOOF = {
    'name': 'SSDT-GPU-SPOOF',
    'remark': '显卡设备 ID 映射',
    'note': '''
• 用于 AMD 显卡设备 ID 映射场景，通过 ACPI 注入兼容设备 ID，让系统加载对应图形驱动。
• 仅建议用于 RapidEFI 兼容性数据中明确标记需要设备 ID 映射的型号。
''',
  };

  static const ssdtPCIDISABLE = {
    'name': 'SSDT-PCI-DISABLE',
    'remark': 'ACPI 设备屏蔽',
    'note': '''
• 用于在 ACPI 层处理不适合交给 macOS 驱动的 PCI 设备，例如不兼容显卡、NVMe 控制器或其他扩展设备。
• 笔记本优先尝试电源级停用；如果固件没有对应电源方法，再降级到驱动层规避。
• 台式机、NUC、HEDT 默认使用通用规避方式，避免依赖机器固件里通常不存在的独显电源方法。
• 所有方案都需要有效 ACPI Path；如果硬件报告缺失 ACPI Path，会自动跳过该设备。
''',
  };
  static const ssdtRMNE = {
    'name': 'SSDT-RMNE',
    'remark': '仿冒有线网卡设备(适用于没有有线网卡的笔记本)',
    'note': '''
•	为Hackintosh系统提供NullEthernet仿冒虚拟网卡，用于解决 iMessage、Facetime、iCloud 等 Apple 服务对内建网络设备的依赖
  ''',
  };

  static const ssdtGPI0 = {
    'name': 'SSDT-GPI0',
    'remark': '修复笔记本I2C触摸板问题(适用于笔记本)',
    'note': '''
•	通过修复ACPI硬件节点挂载,确保在macOS系统启用该设备,修复部分I2C触控板无法正常识别问题
•	SSDT-GPI0 解决驱动挂载硬件设备问题,SSDT-XOSI 主要用于修复 BIOS/ACPI 初始化逻辑与操作系统识别不兼容的问题(某些时候可以修复触控板问题)

''',
  };

  static const ssdtCPUR = {
    'name': 'SSDT-CPUR',
    'remark': 'B850,B650,B550,A520芯片组的CPU重命名(仅适用于Ryzen平台)',
    'note': '''
•	适用于B850,B650,B550,A520芯片组的CPU重命名,修复AMD平台无法识别CPU导致的崩溃问题(预制SSDT补丁时才推荐使用)
•	定制SSDT补丁时,建议使用定制的SSDT-PLUG即可!(AMD Ryzen平台,在定制SSDT时,自动更名为SSDT-PLUG-ALT)
''',
  };

  static const ssdtPLUGALT = {
    'name': 'SSDT-PLUG-ALT',
    'remark': '修复电源管理(适用于Intel 12代及以上，部分AMD Ryzen等平台)',
    'note': '''
•	macOS 依赖 CPU 电源管理插件（PluginType）来调节 CPU 频率，提高能效和续航。
•	该补丁会修改 CPU 定义，使 macOS 认为它是 Apple 设备所需的 plugin-type = 1 处理器，从而正确加载 CPU 变频管理，提高性能和功耗控制。
•	适用于Intel Alder Lake 12代及以上,以及部分AMD Ryzen平台 
''',
  };

  static const ssdtAWAC = {
    'name': 'SSDT-AWAC',
    'remark': '禁用AWAC(现代计时器)(适用于Intel Coffee Lake 8代及以上)',
    'note': '''
•	禁用AWAC(现代计时器),同时启用或仿冒传统RTC
•	适用于Intel Coffee Lake 8代及以上
''',
  };

  static const ssdtUNC = {
    'name': 'SSDT-UNC',
    'remark': '所有原生X99(C612)主板和大多数原生X79(C602)主板需要',
    'note': '''
•	此 SSDT 适用于所有 X99 主板以及多数 X79 主板，主要功能是禁用 ACPI 中未使用的设备，从而防止 IOPCIFamily 引起内核崩溃（kernel panic）。
•	适用主板： 所有原生X99(C612)主板和大多数原生X79(C602)主板。
''',
  };

  static const ssdtRTC0RANGE = {
    'name': 'SSDT-RTC0-RANGE',
    'remark': '启用或仿冒传统RTC计时器,并修复RTC范围(适用于所有原生X99(C612)和X299主板)',
    'note': '''
•	启用或仿冒传统RTC计时器,并修复RTC范围。
• 解决开机时间不正确、RTC 相关错误、睡眠唤醒问题等。
•	此 SSDT 适用于所有 X99(C612) 主板以及X299 主板
''',
  };

  static const ssdtDTGP = {
    'name': 'SSDT-DTGP',
    'remark': '添加DTGP支持',
    'note': '''
•	注入硬件设备属性,修复部分显卡,声卡,雷电卡等ACPI问题(没有 DTGP 方法支持时，这些属性注入可能会失败或不起作用！)
''',
  };

  static const ssdtDMAC = {
    'name': 'SSDT-DMAC',
    'remark': '仿冒一个标准DMA控制器',
    'note': '''
•	仿冒一个标准 DMA Controller（直接内存访问控制器）的虚拟设备控制器（PNP0200）, 补全 ACPI 资源表,让 macOS 正常识别 LPC 总线设备和 DMA 功能
•	HEDT/服务器平台通常不需要
•	添加缺失的部件,这只是一种完善方案,非必要!
''',
  };

  static const ssdtPWRB = {
    'name': 'SSDT-PWRB',
    'remark': '仿冒一个标准PWRB控制器',
    'note': '''
•	仿冒一个标准 Power Button（PNP0C0C）设备,让 macOS 正常识别系统电源按钮、支持睡眠和唤醒
•	部分 BIOS/主板 ACPI 树里没有 PNP0C0C,macOS 无法正确处理电源按钮,可能导致无法睡眠、无法唤醒、菜单栏电源按钮不可用
•	添加缺失的部件,这只是一种完善方案,非必要!
''',
  };

  static const ssdtSLPB = {
    'name': 'SSDT-SLPB',
    'remark': '仿冒一个标准SLPB控制器',
    'note': '''
•	仿冒一个标准 Sleep Button（PNP0C0E）设备，让 macOS 正确识别系统睡眠按钮，实现睡眠和唤醒功能
•	部分 BIOS/主板 ACPI 树里没有 PNP0C0E,macOS 无法正确处理睡眠按钮,可能导致无法睡眠、无法唤醒、菜单栏睡眠按钮不可用
•	PNP0C0E睡眠修正方法时,需要此部件!
•	添加缺失的部件,这只是一种完善方案,非必要!
''',
  };

  static const ssdtMEM2 = {
    'name': 'SSDT-MEM2',
    'remark': '仿冒一个IGPU所需的MEM2设备',
    'note': '''
•	添加 IGPU 所需的 MEM2 ACPI 设备,修复 IGPU 相关问题
•	补充核显内存映射，避免驱动初始化失败
•	适用范围: Haswell ~ Kaby Lake，仅核显系统。通常仅独显不需要此SSDT!
''',
  };
}
