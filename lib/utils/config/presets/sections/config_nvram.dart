// ignore_for_file: constant_identifier_names

import 'package:rapidefi/utils/config/models/nvram/boot_arg_model.dart';

import '../../models/nvram/nvram_add_item.dart';
import '../../models/nvram/nvram_delete_item.dart';

class ConfigNvram {
  static const String UUID_4D1EDE05_38C7_4A6A_9CC6_4BCCA8B38C14 =
      '4D1EDE05-38C7-4A6A-9CC6-4BCCA8B38C14';
  static const String UUID_4D1FDA02_38C7_4A6A_9CC6_4BCCA8B30102 =
      '4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102';
  static const String UUID_7C436110_AB2A_4BBB_A880_FE41995C9F82 =
      '7C436110-AB2A-4BBB-A880-FE41995C9F82';

  static NvramAddItem revcpu =
      NvramAddItem(key: 'revcpu', dataType: 'integer', value: '1');

  static NvramAddItem revcpuname =
      NvramAddItem(key: 'revcpuname', dataType: 'string', value: '');

  ///修复蓝牙
  static NvramAddItem bluetoothExternalDongleFailed = NvramAddItem(
      key: 'bluetoothExternalDongleFailed', dataType: 'data', value: '00');

  static NvramAddItem bluetoothInternalControllerInfo = NvramAddItem(
      key: 'bluetoothInternalControllerInfo',
      dataType: 'data',
      value: '0000000000000000000000000000');

  ///引导参数
  static NvramAddItem boot_args = NvramAddItem(
    key: 'boot-args',
    dataType: 'string',
    value: '',
  );
  static NvramAddItem ui_scale = NvramAddItem(
    key: 'UIScale',
    dataType: 'data',
    value: '01',
  );

  static NvramAddItem csr_active_config = NvramAddItem(
    key: 'csr-active-config',
    dataType: 'data',
    value: '00000000',
  );

  static Map<String, List<NvramAddItem>> createAddList() {
    return {
      UUID_4D1EDE05_38C7_4A6A_9CC6_4BCCA8B38C14: [
        NvramAddItem(
          key: 'DefaultBackgroundColor',
          dataType: 'data',
          value: '00000000',
        ),
      ],
      UUID_4D1FDA02_38C7_4A6A_9CC6_4BCCA8B30102: [
        NvramAddItem(
          key: 'rtc-blacklist',
          dataType: 'data',
          value: '',
        ),
      ],
      UUID_7C436110_AB2A_4BBB_A880_FE41995C9F82: [
        NvramAddItem(
          key: 'ForceDisplayRotationInEFI',
          dataType: 'integer',
          value: '0',
        ),
        NvramAddItem(
          key: 'SystemAudioVolume',
          dataType: 'data',
          value: '46',
        ),
        NvramAddItem(
          key: 'boot-args',
          dataType: 'string',
          value: '',
        ),
        NvramAddItem(
          key: 'csr-active-config',
          dataType: 'data',
          value: '00000000',
        ),
        NvramAddItem(
          key: 'prev-lang:kbd',
          dataType: 'data',
          value: '7A682D48616E733A323532',
        ),
        NvramAddItem(
          key: 'run-efi-updater',
          dataType: 'string',
          value: 'No',
        ),
      ],
    };
  }

  static Map<String, List<NvramDeleteItem>> createDeleteList() {
    return {
      UUID_4D1EDE05_38C7_4A6A_9CC6_4BCCA8B38C14: [
        NvramDeleteItem(value: 'DefaultBackgroundColor'),
        NvramDeleteItem(value: 'UIScale'),
      ],
      UUID_4D1FDA02_38C7_4A6A_9CC6_4BCCA8B30102: [
        NvramDeleteItem(value: 'rtc-blacklist'),
      ],
      UUID_7C436110_AB2A_4BBB_A880_FE41995C9F82: [
        NvramDeleteItem(value: 'forceDisplayRotationInEFI'),
        NvramDeleteItem(value: 'boot-args'),
        NvramDeleteItem(value: 'csr-active-config'),
        NvramDeleteItem(value: 'prev-lang:kbd'),
        NvramDeleteItem(value: 'bluetoothExternalDongleFailed'),
        NvramDeleteItem(value: 'bluetoothInternalControllerInfo'),
      ],
    };
  }

  ///引导参数

  static BootArgModel verbose =
      BootArgModel(arg: '-v', comment: '开启-v跑码(卡代码时方便定位发现错误,适用于调试引导阶段)');

  static BootArgModel keepsyms1 = BootArgModel(
      arg: 'keepsyms=1',
      comment:
          '便于mac系统在发生内核崩溃时打印更多符号信息,有助于排查问题.此参数通常搭配debug=0x100使用(首次调试引导时,强烈建议勾选)');

  static BootArgModel debug100 = BootArgModel(
      arg: 'debug=0x100',
      comment: '防止在内核崩溃时自动重启,便于查看Panic崩溃日志(首次调试引导时,强烈建议勾选)');

  static BootArgModel watchdog = BootArgModel(
      arg: 'watchdog=0', comment: '禁用看门狗功能,防止误触发Panic崩溃重启(适用于调试引导时)');

  static BootArgModel slide = BootArgModel(
      arg: 'slide=0',
      comment:
          '禁用内核地址空间随机化（KASLR）,保证内核和 kext（内核扩展）加载在同一套固定内存映射,避免因随机slide值导致的内存冲突早期启动内核崩溃问题(适用于调试引导时)');

  static BootArgModel no_compat_check = BootArgModel(
      arg: '-no_compat_check',
      comment:
          '跳过首次启动macOS过程中机型检查,避免因SMBIOS过低或过高出现禁止符号,确保可以正常引导系统(注意此参数不能跳过安装时的机型检查,安装时会出现类似"不支持macOS",此时可以更改更高或者更低的SMBIOS来支持新或旧系统)');
  static BootArgModel amfi = BootArgModel(
      arg: 'amfi=0x80',
      comment:
          '禁用AMFI,相对比较新的显卡(比如HD4000及以上,GT710等开普勒核心以上)或者WiFi打驱动时,此参数适用.注意和amfi_get_out_of_my_way=0x1参数不要同时使用!(禁用SIP才生效,开启SIP后自动移除该参数)');

  static BootArgModel amfipassbeta = BootArgModel(
      arg: '-amfipassbeta',
      comment:
          '确保AMFIPass.kext在最新macOS Tahoe 26系统中能正常启用并激活功能,以便继续绕过AMFI(禁用AMFI)安全检查。(注意:1.此参数与禁用AMFI参数不可同时使用,并且此参数需要搭配AMFIPass.kext使用 2.此参数通常在最新系统中才可能用到,非必要不要添加)');

  static BootArgModel amfi_get_out_of_my_way = BootArgModel(
      arg: 'amfi_get_out_of_my_way=0x1',
      comment:
          '禁用AMFI,老平台老旧显卡(比如GT240)或者WiFi打驱动时,此参数适用.注意和amfi=0x80参数不要同时使用!(禁用SIP才生效,开启SIP后自动移除该参数)');

  static BootArgModel ipc_control_port_options = BootArgModel(
      arg: 'ipc_control_port_options=0',
      comment: '修复禁用AMFI后部分应用(例如:百度网盘)闪退问题(禁用SIP才生效,开启SIP后自动移除该参数)');

  static BootArgModel lilubetaall = BootArgModel(
      arg: '-lilubetaall',
      comment:
          '修复在最新系统(主要是Beta版)可能出现的问题(系统驱动异常,比如:声卡,蓝牙,CPU频率等突然异常,尝鲜最新Beta版本系统时强烈建议勾选)');
  static BootArgModel cpus = BootArgModel(
      arg: 'cpus=1',
      comment: '仅启用1个CPU核心（适用于X58,X79,X99,X299等多核心服务器CPU内核崩溃、早期安装调试阶段）');
  static BootArgModel dart = BootArgModel(
      arg: 'dart=0',
      comment: '关闭 VT-d（禁用 IOMMU,BIOS没有关闭VT-d时,可以勾选）, 解决某些主板启动或者进系统后卡死问题');
  static BootArgModel disablegfxfirmware = BootArgModel(
      arg: '-disablegfxfirmware',
      comment:
          '禁用Apple Graphics Firmware固件加载,避免启动过程中因固件加载失败或重试循环而卡住(仅适用于Intel核显)');

  static BootArgModel wegnoigpu = BootArgModel(
      arg: '-wegnoigpu', comment: '禁用Intel核显(核显无法驱动，也不支持加速硬解时，建议勾选)');

  static BootArgModel wegnoegpu = BootArgModel(
      arg: '-wegnoegpu', comment: '禁用独显(通常intel双显卡笔记本独立显卡【常见于N卡】无法驱动时,建议勾选)');

  static BootArgModel nv_disable =
      BootArgModel(arg: 'nv_disable=1', comment: '禁用 NVIDIA 驱动（仅适用于调试不兼容N卡时）');

  static BootArgModel igfxvesa = BootArgModel(
      arg: '-igfxvesa',
      comment: '禁用Intel 核显加速(例如:使用OCLP 打完核显补丁无法正常启动时,可以勾选,无加速,仅调试时用)');

  static BootArgModel igfxhdmidivs = BootArgModel(
      arg: '-igfxhdmidivs',
      comment:
          '修复第6代 Skylake 核显,第7代 Kaby Lake 核显以及第8代 Coffee Lake核显驱动在尝试点亮外接HDMI高分辨率显示器时造成的死循环问题(具体症状表现为插入 HDMI 线后,笔记本内屏变黑但有背光,系统无响应,并且外屏也无输出)');

  static BootArgModel igfxonln = BootArgModel(
      arg: 'igfxonln=1',
      comment:
          '在所有显示器上强制在线状态,对核显多屏输出有所帮助,某些时候可以避免睡眠唤醒后黑屏或开机需要插拔显示器线才能点亮屏幕等问题(通常适用于8代Coffee Lake及以上核显)');

  static BootArgModel igfxrpsc = BootArgModel(
      arg: 'igfxrpsc=1',
      comment: '修复提升Intel核显性能(例如:修复核显4K hevc编码,分辨率及fps达不到理想值问题)');

  static BootArgModel igfxmlr = BootArgModel(
      arg: '-igfxmlr',
      comment:
          '修复Intel核显最大链路速率值的问题,导致在点亮屏幕时直接崩溃的问题(（尤其是 Skylake、Kaby Lake、Coffee Lake、Comet Lake上,黑屏无信号,未达4K预期分辨率等）');

  static BootArgModel igfxmpc = BootArgModel(
      arg: '-igfxmpc',
      comment:
          '修复核显分辨率问题,强制启用核显（IGPU）的 “最大像素时钟覆盖（max pixel clock override）”，解除 macOS 默认的分辨率,刷新率等限制');

  static BootArgModel igfxfw = BootArgModel(
      arg: 'igfxfw=2',
      comment: '启用核显完整固件加载,提高核显利用率,提升核显性能.添加此参数可能导致无法进系统，谨慎使用');

  static BootArgModel cdfon = BootArgModel(
      arg: '-cdfon',
      comment:
          '修复部分笔记本核显HDMI输出4K黑屏问题(通常适用于笔记本,例如ThinkPad P71/7700HQ/HD630/4K 卡死在 `gIOScreenLockState3`)');

  static BootArgModel igfxcdc = BootArgModel(
      arg: '-igfxcdc',
      comment: '修复10代Ice Lake平台上因Core Display Clock (CDCLK)频率过低而导致的内核崩溃问题');

  static BootArgModel igfxdvmt = BootArgModel(
      arg: '-igfxdvmt',
      comment: '修复10代Ice Lake平台上因驱动错误地计算DVMT预分配内存大小而导致的内核崩溃问题');

  static BootArgModel igfxdbeo = BootArgModel(
      arg: '-igfxdbeo', comment: '修复10代Ice Lake平台上笔记本开机持续花屏7到15秒的问题');

  static BootArgModel igfxnotelemetryload = BootArgModel(
      arg: '-igfxnotelemetryload',
      comment:
          '禁用 iGPU（核显）在启动过程中加载遥测模块,某些笔记本（尤其是 Chromebook）在加载该模块时可能会导致系统在启动阶段卡死或冻结(适用于Intel Skylake 6代及以上笔记本)');

  static BootArgModel igfxblr = BootArgModel(
      arg: '-igfxblr',
      comment:
          '修复macOS Ventura 13.4以下,7代KBL、8&9代CFL笔记本平台上的背光寄存器,修复黑屏或持续3分钟暗屏问题(适用于笔记本)');

  static BootArgModel igfxblt = BootArgModel(
      arg: '-igfxblt',
      comment:
          '修复macOS Ventura 13.4及以上,7代KBL、8&9代CFL笔记本平台上的背光寄存器,修复黑屏或持续3分钟暗屏问题(适用于笔记本)');

  static BootArgModel igfxbls = BootArgModel(
      arg: '-igfxbls', comment: '调整亮度滑块(亮度滑块)设置,使其过度更平滑自然,以提升用户体验(适用于笔记本)');

  static BootArgModel gfxrst = BootArgModel(
      arg: 'gfxrst=1',
      comment:
          '在第二启动阶段绘制苹果标志，而不是帧缓冲区复制.当连接外部显示器时，平滑地从进度条过渡到登录桌面,某些时候可以修复进系统黑屏问题,同时对插拔显示器线才能亮屏有所帮助');
  static BootArgModel npci2000 = BootArgModel(
      arg: 'npci=0x2000',
      comment:
          '修复X58,X79,X99,AMD等平台卡ACPI Configuration begin问题(通常Above 4G Decoding没有打开时,注意和npci=0x3000二选一,常见于X58,X79,X99等服务器以及AMD平台)');

  static BootArgModel npci3000 = BootArgModel(
      arg: 'npci=0x3000',
      comment:
          '修复X58,X79,X99,AMD等平台卡ACPI Configuration begin问题(通常Above 4G Decoding没有打开时,注意和npci=0x2000二选一,常见于X58,X79,X99等服务器以及AMD平台)');

  static BootArgModel unfairgva = BootArgModel(
      arg: 'unfairgva=1',
      comment:
          '修复AMD GPU上的硬件数字版权管理(DRM)支持问题(使得在支持的AMD GPU上体验受到DRM保护的数字内容,如流媒体服务提供的高质量视频)');

  static BootArgModel radvesa = BootArgModel(
      arg: '-radvesa',
      comment: '禁用ATI,AMD显卡加速(例如:使用OCLP 打完显卡补丁无法正常启动时,可以勾选,无加速,仅调试时用)');

  static BootArgModel radpg15 = BootArgModel(
      arg: 'radpg=15',
      comment:
          '修复HD7750、HD7850(主要核心为GCN系列HD77XX、HD78XX、HD79XX)等老A卡花屏、黄屏等显示异常问题');

  static BootArgModel agdpmod_ignore = BootArgModel(
      arg: 'agdpmod=ignore',
      comment:
          '修复部分显卡可能导致的黑屏或显示异常问题,完全忽略AppleGraphicsDevicePolicy.kext对图形卡的限制或设置.在不确定具体限制问题时,避免因不兼容的硬件配置(如特定board-id)导致的显示问题或黑屏现象.注意此参数,搭配WhateverGreen.kext使用才生效.对于原生免驱A卡,可以去掉WhateverGreen.kext驱动,那么此参数无需再添加');

  static BootArgModel agdpmod_pikera = BootArgModel(
      arg: 'agdpmod=pikera',
      comment:
          '修复AMD Navi核心RX5XXX,RX6XXX系列显卡启动时黑屏问题(例如:RX5500,RX5600,RX5700,RX6600,RX6800,RX6900等),将board-id替换为board-ix,绕过AppleGraphicsDevicePolicy的某些限制.注意:1. 搭配WhateverGreen.kext使用才生效. 2. BIOS SuperIO设置中关闭Serial/COM Port.对于原生免驱A卡,可以去掉WhateverGreen.kext驱动,那么此参数无需再添加.');

  static BootArgModel agdpmod_vit9696 = BootArgModel(
      arg: 'agdpmod=vit9696',
      comment:
          '修复部分RX470,RX570等显卡睡眠唤醒后黑屏问题,禁用AppleGraphicsDevicePolicy中的board-id检查,修复部分显卡可能导致的黑屏或显示异常问题.注意此参数,搭配WhateverGreen.kext使用才生效.对于原生免驱A卡,可以去掉WhateverGreen.kext驱动,那么此参数无需再添加');

  static BootArgModel amd_no_dgpu_accel = BootArgModel(
      arg: '-amd_no_dgpu_accel',
      comment:
          '修复Intel 3代及以下平台AMD RX5XX(例如:RX560,RX570,RX580)系列,AMD RX5XXX,RX6XXX(例如:RX5500,RX6600)系列免驱显卡在Ventura及以上系统黑屏问题(注意:进入系统后需要使用OCLP打显卡补丁!打完显卡补丁后,去掉该引导参数或者使用EFI目录下备用config-after-post改名替换config,重启即可驱动显卡!)');
  static BootArgModel radcodec = BootArgModel(
      arg: '-radcodec', comment: '修复官方不支持的AMD显卡(例如: RX550 Lexa核心)使其支持VDA硬件视频编码');

  static BootArgModel ngfxcompat_ngfxgl_nvda_drv_vrl = BootArgModel(
      arg: 'ngfxcompat=1 ngfxgl=1 nvda_drv_vrl=1',
      comment:
          '修复Fermi,Maxwell,Pascal架构老N卡(例如:GT610,GTX750,GTX960,GTX1050)BigSur 11以上系统显卡驱动问题(注意:进入系统后需要使用OCLP打显卡补丁!!!开普勒核心不需要此参数！！！)');

  static BootArgModel brcmfx_country_hk = BootArgModel(
      arg: 'brcmfx-country=HK',
      comment: '修复部分博通无线网卡速率较慢问题(更改博通WiFi国家码为香港,也可以更改路由器信道改善)');

  static BootArgModel vsmcgen =
      BootArgModel(arg: 'vsmcgen=1', comment: '修复卡ramrod代码,SMC模拟器损坏问题');

  static BootArgModel revpatch_sbvmm = BootArgModel(
      arg: 'revpatch=auto,sbvmm,cpuname',
      comment:
          '修复禁用SIP(系统完整性保护)或SecureBootModel(安全模型)后macOS系统OTA更新问题,以及修复自定义CPU名称显示问题');

  static BootArgModel swd_panic = BootArgModel(
      arg: 'swd_panic=1', comment: '避免设备进入睡眠模式后重启的问题,便于获取内核崩溃日志,排查睡眠问题');

  static BootArgModel ctrsmt = BootArgModel(
      arg: 'ctrsmt=full',
      comment: '改善Intel 12代及之后大小核 CPU 的拓扑识别与调度，性能提升不保证，建议实测后启用(注意需要搭配CpuTopologyRebuild.kext使用才生效)');

  static BootArgModel darkwake = BootArgModel(
      arg: 'darkwake=0',
      comment: '完全禁用Darkwake模式,让系统进入传统睡眠模式,主要用于修复唤醒黑屏,自动唤醒等问题');

  static BootArgModel forceRenderStandby = BootArgModel(
      arg: 'forceRenderStandby=0',
      comment: '禁用iGPU RC6渲染待机,修复睡眠时由于核显RC6引发NVMe内核恐慌问题');

  static BootArgModel applbkl = BootArgModel(
      arg: 'applbkl=3', comment: '启用AMD Radeon RX 5000 系列显卡的PWM背光控制');

  static BootArgModel raddvi =
      BootArgModel(arg: '-raddvi', comment: '修复校正老A卡(290X、370等)DVI接口输出显示');

  static BootArgModel i2c_force_polling = BootArgModel(
      arg: '-vi2c-force-polling',
      comment:
          '强制I2C类型触控板工作在轮询模式（polling mode）,而不是中断（interrupt-driven mode）驱动模式(中断模式通常需要定制SSDT,相对复杂.某些时候可以修复I2C触控板无法使用的问题(需要搭配VoodooI2C驱动使用)');

  static List<BootArgModel> bootArgModels = [
    verbose,
    keepsyms1,
    debug100,
    watchdog,
    slide,
    no_compat_check,
    lilubetaall,
    cpus,
    dart,
    disablegfxfirmware,
    nv_disable,
    amfi,
    amfi_get_out_of_my_way,
    ipc_control_port_options,
    amfipassbeta,
    wegnoigpu,
    wegnoegpu,
    igfxhdmidivs,
    igfxmlr,
    igfxmpc,
    igfxfw,
    igfxvesa,
    igfxonln,
    igfxrpsc,
    cdfon,
    igfxcdc,
    igfxdvmt,
    igfxdbeo,
    igfxnotelemetryload,
    igfxblr,
    igfxblt,
    igfxbls,
    gfxrst,
    npci2000,
    npci3000,
    unfairgva,
    radpg15,
    radvesa,
    raddvi,
    radcodec,
    ctrsmt,
    agdpmod_ignore,
    agdpmod_pikera,
    agdpmod_vit9696,
    amd_no_dgpu_accel,
    ngfxcompat_ngfxgl_nvda_drv_vrl,
    brcmfx_country_hk,
    vsmcgen,
    revpatch_sbvmm,
    swd_panic,
    darkwake,
    forceRenderStandby,
    applbkl,
    i2c_force_polling
  ];
}
