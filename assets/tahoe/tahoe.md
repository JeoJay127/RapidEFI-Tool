
## 1.安装macOS Tahoe 26 ,需要对OpenCore做哪些调整?

#### 请严格按照以下步骤检查

1. 建议将OpenCore引导升级至1.0.7及更新版本，同时保证基本kexts(例如: Lilu等)同步更新最新版本 (当前Rapid工具内置已最新,可忽略)

2. 由于macOS Tahoe 26调整了USB接口定义，因此必须使用适配了最新macOS Tahoe 26的USB驱动,以下方案任选其一:

   - Rapid工具内置USBInjectAll.kext 1.0版本，已适配macOS Tahoe 26,使用通用USB驱动安装调试阶段，请勿随意替换USBInjectAll.kext，以免卡USB

   - Rapid工具内置USBToolBox.kext 1.2.0版本，已适配macOS Tahoe 26,只需要使用USBToolBox工具定制UTBMap.kext这一个驱动即可，请勿随意替换USBToolBox.kext，以免卡USB

3. 对于AMD Ryzen核显用户,同样建议安装阶段禁用NootedRed.kext,待完成安装好系统后，再选择开启！同样建议安装阶段禁用NootRX.kext,待完成安装好系统后，再选择开启！


----------

## 2.macOS Tahoe 26 支持哪些平台?

支持范围:

1. Intel平台: 4代 Haswell及以上(绝大部分奔腾赛扬CPU不支持AVX2指令集,导致显卡需要OCLP补丁，无法支持macOS Tahoe 26)
   
   需要注意的是 4代 Haswell 因核显暂时无法OCLP补丁,必须加免驱A卡(RX 460,RX550及以上)

2. AMD 平台:  Ryzen 1000 - 9000系列 
  
   - Ryzen 核显用户: Ryzen 1xxx 系列（Athlon Silver/Gold）到 Ryzen 5xxx，以及 7x30系列，使用NootedRed.kext支持macOS Tahoe 26

   - Ryzen 独显用户: 搭配免驱A卡(RX460，RX550及以上),即可支持macOS Tahoe 26

 注意: 3代及以下(如:X79)由于缺少AVX2.0指令集,所有免驱显卡都需要打补丁(目前OCLP还不支持),因此在这些平台上显卡暂时无法驱动

----------

## 3.macOS Tahoe 26 支持哪些显卡?

1. Intel 核显 : 6代Skylake(核显仿冒HD630即可) - 10代

2. Intel Xe 核显 (11代 Tiger Lake ~ 14代 Raptor Lake,以及 Twin Lake):
   
   - 使用 WhateverXe + AMFIAnchor + AMFIAnchorInjector 组合(工具【可选Kexts驱动】→【显卡】)。该方案通过适配 Apple 原生 TGL 驱动实现显示输出,必须与 WhateverGreen 二选一,保持 AMFI 开启,并设置 csr-active-config=03080000、启动参数 -allow3d -disablegfxfirmware。安装系统后还需要手动安装 WhateverXe Graphics 显卡包才能获得完整加速。
   - Core Ultra (Meteor Lake / Arrow Lake) 属于 Xe-LPG,需要 WTLIntelGfx (XeGfx.kext),目前仍是测试驱动。工具内置的 XeGfx/XeGfxIntelFB 仅用于方便分发,完整加速组件仍需按上游说明自行构建,并安装到辅助内核集合后手动加载。

3. AMD 独显: RX 460,RX 550 及以上

4. AMD Ryzen 核显: Ryzen 1xxx 系列（Athlon Silver/Gold）到 Ryzen 5xxx，以及 7x30系列 (NootedRed.kext支持macOS Tahoe 26)

注意:
   
   所有N卡都不支持 (开普勒，以及10系以类N卡暂时都无法OCLP) 

----------

## 4.macOS Tahoe 26 支持哪些WiFi?

1. Intel WiFi (注意方案一、二、三不要同时使用,只能选一种!)
   
   #### 方案一. 使用Z大驱动 itlwm.kext + Heliport客户端(非必须，对于小白，相对方便,主要配置WiFi密码信息)

   #### 方案二. 使用OCLP修改版（例如:[OCLP-X 2.7.0版本](https://github.com/JeoJay127/OCLP-X/releases/tag/2.7.0) ）打WiFi补丁

   #### 方案三(Tahoe 26 推荐). 使用 AirportItlwm Tahoe 构建,直接接入原生 Wi-Fi 界面,无需 OCLP 补丁

   工具【WiFi蓝牙驱动】→【英特尔(Intel)】中勾选 AirportItlwm_Tahoe.kext(laobamac 分支构建)即可,系统会把它识别为原生无线网卡。

   注意:
   - 该构建仅适用于 macOS Tahoe 26.x(Darwin 25),与 Sequoia 构建使用不同的 ABI,不要混用;
   - 不需要、也不能阻止 IOSkywalkFamily(该阻止项只用于老款博通网卡,会导致 Tahoe 原生无线框架被移除);
   - Wi-Fi 6 (802.11ax/HE) 默认关闭,可添加启动参数 itlwm_he=1 尝试启用;
   - 不支持 WPA3-only、强制 PMF、AWDL/AirDrop 与 MLO;
   - 首次进入系统后如果网络设置里没有 Wi-Fi 服务,可在 系统设置 → 网络 中手动添加 Wi-Fi 接口。

2. Brcm博通 WiFi

   使用OCLP修改版（例如:[OCLP-X 2.7.0版本](https://github.com/JeoJay127/OCLP-X/releases/tag/2.7.0) ）打WiFi补丁

3. USB WiFi

 ----------
 
 ## 5.macOS Tahoe 26 声卡问题

1. AppleALC.kext + SimpleHDA.kext(推荐,无需根补丁)

从macOS Tahoe 26 Beta2开始,由于苹果移除了AppleHDA.kext,导致所有使用AppleALC.kext驱动声卡失效。工具在 Tahoe 26 且勾选 AppleALC 时会自动附加 SimpleHDA.kext,通过 OpenCore 恢复原版 AppleHDA 音频栈:

   - 保持 Kernel → Quirks → DisableLinkeditJettison 为开启;
   - 保留原有可用的 alcid/layout-id 配置,加载顺序为 Lilu → AppleALC → SimpleHDA;
   - 使用前请移除 OCLP 音频根补丁或其他 AppleHDA 恢复方案,避免重复加载;
   - 可选安装 SimpleHDA-HAL 包获得原版 HAL 控制面板,无需重建系统内核集合。

2. AppleALC.kext + OCLP 补丁

使用OCLP修改版（例如:[OCLP-X 2.7.0版本](https://github.com/JeoJay127/OCLP-X/releases/tag/2.7.0) ）打补丁,找回AppleHDA.kext,即可支持(原来macOS Sequoia以下本身能正常驱动的)

3. VoodooHDA.kext

   该驱动称为万能声卡,可以使用Hackintool工具将此驱动打入系统内核扩展,重启即可驱动.

   由于万能声卡可能存在电流杂音，开机爆音问题，一般不建议使用万能声卡！只有当AppleALC不支持或者很难驱动时，可以考虑万能声卡。

4. USB 声卡
   
   USB声卡一般免驱，当驱动声卡比较繁琐或者不能驱动时，可以考虑USB声卡

 ----------

## 6.安装macOS Sequoia 15一切正常,升级或安装macOS Tahoe 26 卡代码

   1.对于macOS Tahoe 26 卡代码，首先考虑是否是 Lilu.kext(注意保持最新版本) 和 USB 的问题，具体参考本指南第1条内容

   2.如果使用了OCLP 打过 WiFi补丁,而且刚好你使用的有线网卡是RTL8125系列网卡,需要添加kernel 阻止补丁 com.apple.driver.AppleEthernetRL (工具最新版本自动添加处理)

 ----------

## 7.macOS Tahoe 26 用着用着死机

   有如下可能原因:

   1. 有线网卡驱动问题。例如: AppleIGC.kext (低版本macOS 也可能存在),如果使用相对较新的kext驱动,主板BIOS需要开启VT-d
      
   2. macOS黑名单NVMe固态硬盘。 例如：三星，镁光,海力士等黑名单NVMe
