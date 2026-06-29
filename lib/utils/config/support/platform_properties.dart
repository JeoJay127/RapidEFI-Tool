import 'package:rapidefi/utils/config/models/device_properties/device_property_item.dart';

// 核显属性配置
DevicePropertyItem _deviceProperty(
  String key,
  String dataType,
  String value,
  String comment, {
  bool display = true,
}) {
  return DevicePropertyItem(
    key: key,
    dataType: dataType,
    value: value,
    comment: comment,
    display: display,
  );
}

DevicePropertyItem get framebuffer_patch_enable => _deviceProperty(
      'framebuffer-patch-enable',
      'data',
      '01000000',
      "启用核显帧缓冲（Framebuffer）补丁总开关",
    );
DevicePropertyItem get framebuffer_unifiedmem_1536 => _deviceProperty(
      'framebuffer-unifiedmem',
      'data',
      '00000060',
      "修改显存至1536M(1.5G显存,苹果官方默认值,适用于3代~10代英特尔核显平台)",
    );
DevicePropertyItem get framebuffer_unifiedmem_2048 => _deviceProperty(
      'framebuffer-unifiedmem',
      'data',
      '00000080',
      "修改显存至2048M(2G显存,工具默认值,适用于3代~10代英特尔核显平台)",
    );
DevicePropertyItem get framebuffer_unifiedmem_3072 => _deviceProperty(
      'framebuffer-unifiedmem',
      'data',
      '000000C0',
      "修改显存至3072M(3G显存,适用于3代~10代英特尔核显平台)",
    );
DevicePropertyItem get framebuffer_unifiedmem_4095 => _deviceProperty(
      'framebuffer-unifiedmem',
      'data',
      '0000F0FF',
      "修改显存至4095M(4G显存,适用于3代~10代英特尔核显平台)",
    );
DevicePropertyItem get framebuffer_cursormem_1k => _deviceProperty(
      'framebuffer-cursormem',
      'data',
      '00009000',
      "修复4代Haswell平台1080P高分屏花屏问题（比如高分屏花屏可能就是这个值不够大,这个补丁是Haswell核显专用补丁.建议1080P及以下屏幕使用此配置）",
    );
DevicePropertyItem get framebuffer_cursormem_2k4k => _deviceProperty(
      'framebuffer-cursormem',
      'data',
      '00000003',
      "修复4代Haswell平台2K,4K等高分屏花屏问题（比如高分屏花屏可能就是这个值不够大,这个补丁是Haswell核显专用补丁.建议2K,4k屏幕使用此配置）",
    );
DevicePropertyItem get framebuffer_memorycount_2 => _deviceProperty(
      'framebuffer-memorycount',
      'data',
      '02000000',
      "Ivy Bridge 高分屏候选补丁",
    );
DevicePropertyItem get framebuffer_pipecount_2 => _deviceProperty(
      'framebuffer-pipecount',
      'data',
      '02000000',
      "Ivy Bridge 高分屏候选补丁",
    );
DevicePropertyItem get framebuffer_portcount_4 => _deviceProperty(
      'framebuffer-portcount',
      'data',
      '04000000',
      "Ivy Bridge 高分屏候选补丁",
    );
DevicePropertyItem get framebuffer_con0_enable => _deviceProperty(
      'framebuffer-con0-enable',
      'data',
      '01000000',
      "启用 con0 接口补丁",
    );
DevicePropertyItem get framebuffer_con1_enable => _deviceProperty(
      'framebuffer-con1-enable',
      'data',
      '01000000',
      "启用 con1 接口补丁",
    );
DevicePropertyItem get framebuffer_con2_enable => _deviceProperty(
      'framebuffer-con2-enable',
      'data',
      '01000000',
      "启用 con2 接口补丁",
    );
DevicePropertyItem get framebuffer_con3_enable => _deviceProperty(
      'framebuffer-con3-enable',
      'data',
      '01000000',
      "启用 con3 接口补丁",
    );
DevicePropertyItem get framebuffer_con1_alldata_ivy_high_res => _deviceProperty(
      'framebuffer-con1-alldata',
      'data',
      '020500000004000007040000030400000004000081000000040600000004000081000000',
      "Ivy Bridge 高分屏候选接口补丁",
    );
DevicePropertyItem get framebuffer_aapl00_duallink => _deviceProperty(
      'AAPL00,DualLink',
      'data',
      '01000000',
      "Sandy Bridge 笔记本高分屏(1600x900及以上分辨率)补丁",
    );
DevicePropertyItem get framebuffer_singlelink => _deviceProperty(
      'framebuffer-singlelink',
      'data',
      '01000000',
      "Ironlake/Arrandale 笔记本可选补丁",
    );
DevicePropertyItem get framebuffer_enable_hdmi20 => _deviceProperty(
      'enable-hdmi20',
      'data',
      '01000000',
      "修复HDMI 高分屏 60 fps方案 (在一些情况下,Intel 核显可能默认使用 HDMI 1.4 标准.启用该参数,强制启用 HDMI 2.0,以支持更高的分辨率和刷新率,比如支持4K@60HZ)",
    );
DevicePropertyItem get framebuffer_hda_gfx => _deviceProperty(
      'hda-gfx',
      'string',
      'onboard-1',
      "修复HDMI音频输出(通常只需要合适的alcid就行,这个参数某些时候可以修复HDMI音频正确输出问题)",
    );
DevicePropertyItem get framebuffer_disable_hdmi_patches => _deviceProperty(
      'disable-hdmi-patches',
      'data',
      '01000000',
      "禁用数字声音的DP到HDMI转换补丁(当DisplayPort接口通过转换器连接到HDMI接口时,确保HDMI连接的稳定性和可靠性)",
    );
DevicePropertyItem get framebuffer_force_online => _deviceProperty(
      'force-online',
      'data',
      '01000000',
      "在所有显示器上强制在线状态,对核显多屏输出有所帮助,某些时候可以避免睡眠唤醒后黑屏或开机需要插拔显示器线才能点亮屏幕等问题(通常适用于8代Coffee Lake及以上核显)",
    );
DevicePropertyItem get framebuffer_rps_control => _deviceProperty(
      'rps-control',
      'data',
      '01000000',
      "提升核显性能(例如:修复核显4K hevc编码,分辨率及fps达不到理想值问题)",
    );
DevicePropertyItem get framebuffer_igfxfw => _deviceProperty(
      'igfxfw',
      'data',
      '02000000',
      "启用核显完整固件加载,提高核显利用率,提升核显性能.添加此参数可能导致无法进系统，谨慎使用",
    );
DevicePropertyItem get framebuffer_enable_hdmi_dividers_fix => _deviceProperty(
      'enable-hdmi-dividers-fix',
      'data',
      '01000000',
      "修复第6代 Skylake 核显,第7代 Kaby Lake 核显以及第8代 Coffee Lake核显驱动在尝试点亮外接HDMI高分辨率显示器时造成的死循环问题(具体症状表现为插入 HDMI 线后,笔记本内屏变黑但有背光,系统无响应,并且外屏也无输出)",
    );
DevicePropertyItem get framebuffer_enable_cdclk_frequency_fix =>
    _deviceProperty(
      'enable-cdclk-frequency-fix',
      'data',
      '01000000',
      "修复10代 Ice Lake 平台上因 Core Display Clock (CDCLK) 频率过低而导致的内核崩溃问题",
    );
DevicePropertyItem get framebuffer_enable_dvmt_calc_fix => _deviceProperty(
      'enable-dvmt-calc-fix',
      'data',
      '01000000',
      "修复10代 Ice Lake 平台上因驱动错误地计算 DVMT 预分配内存大小而导致的内核崩溃问题",
    );
DevicePropertyItem get framebuffer_enable_backlight_smoother => _deviceProperty(
      'enable-backlight-smoother',
      'data',
      '01000000',
      "调整亮度滑块(亮度滑块)设置,使其过度更平滑自然,以提升用户体验",
    );
DevicePropertyItem get framebuffer_enable_backlight_registers_alternative_fix =>
    _deviceProperty(
      'enable-backlight-registers-alternative-fix',
      'data',
      '01000000',
      "修复在7代 Kaby Lake,8代, 9代Coffee Lake 平台上运行 macOS 13.4 或以上版本的笔记本开机持续3分钟暗屏问题",
    );
DevicePropertyItem get framebuffer_enable_backlight_registers_fix =>
    _deviceProperty(
      'enable-backlight-registers-fix',
      'data',
      '01000000',
      "修复在7代 Kaby Lake,8代,9代 Coffee Lake平台上运行 macOS 13.3及以下版本版本的笔记本开机持续3分钟暗屏问题",
    );
DevicePropertyItem get framebuffer_enable_dbuf_early_optimizer =>
    _deviceProperty(
      'enable-dbuf-early-optimizer',
      'data',
      '01000000',
      "修复10代 Ice Lake 平台上笔记本开机持续花屏7到15秒的问题",
    );
DevicePropertyItem get framebuffer_enable_max_pixel_clock_override =>
    _deviceProperty(
      'enable-max-pixel-clock-override',
      'data',
      '01000000',
      "修复10代 Ice Lake 核显HDMI高分辨率显示器在 4K@60Hz、部分 2K/4K 高刷新场景下黑屏、无信号、分辨率无法正确输出的问题(强制启用核显（IGPU）的 “最大像素时钟覆盖（max pixel clock override）)",
    );
DevicePropertyItem get framebuffer_aapl_GfxYTile => _deviceProperty(
      'AAPL,GfxYTile',
      'data',
      '01000000',
      "用于修复核显毛刺效果或者闪屏问题(比如核显HD530)",
    );
DevicePropertyItem get framebuffer_disable_external_gpu => _deviceProperty(
      'disable-external-gpu',
      'data',
      '01000000',
      "禁用独显(通常双显卡笔记本独显无法驱动时,需要屏蔽独显)",
    );
DevicePropertyItem get framebuffer_enable_dpcd_max_link_rate_fix =>
    _deviceProperty(
      'enable-dpcd-max-link-rate-fix',
      'data',
      '01000000',
      "修复笔记本(例如Dell XPS 15 9570 等高分屏笔记本)高分屏内屏返回错误的最大链路速率值的问题,导致在点亮内屏时直接崩溃的问题(高分屏笔记本建议勾选)",
    );
DevicePropertyItem get framebuffer_aapl00_override_no_connect =>
    _deviceProperty(
      'AAPL00,override-no-connect',
      'data',
      '',
      "向AAPL00接口(笔记本通常是内屏)注入显示器EDID,修复该接口黑屏不显示问题(注意:需要在EDID配置页,先注入显示器EDID!可以在工具“核显配置”->“显示器EDID”来补充填写EDID.B560等500系主板,在修复HDMI输出时,必须注入显示器EDID,否则大概率黑屏.某些时候,对于其他Intel平台可能会修复核显花屏,紫屏或黑屏问题)",
    );
DevicePropertyItem get framebuffer_aapl01_override_no_connect =>
    _deviceProperty(
      'AAPL01,override-no-connect',
      'data',
      '',
      "向AAPL01接口注入显示器EDID,修复该接口黑屏不显示问题(注意:需要在EDID配置页,先注入显示器EDID!可以在工具“核显配置”->“显示器EDID”来补充填写EDID.B560等500系主板,在修复HDMI输出时,必须注入显示器EDID,否则大概率黑屏.某些时候,对于其他Intel平台可能会修复核显花屏,紫屏或黑屏问题)",
    );
DevicePropertyItem get framebuffer_aapl02_override_no_connect =>
    _deviceProperty(
      'AAPL02,override-no-connect',
      'data',
      '',
      "向AAPL02接口注入显示器EDID,修复该接口黑屏不显示问题(注意:需要在EDID配置页,先注入显示器EDID!可以在工具“核显配置”->“显示器EDID”来补充填写EDID.B560等500系主板,在修复HDMI输出时,必须注入显示器EDID,否则大概率黑屏.某些时候,对于其他Intel平台可能会修复核显花屏,紫屏或黑屏问题)",
    );
DevicePropertyItem get framebuffer_enable_lspcon_support => _deviceProperty(
      'enable-lspcon-support',
      'data',
      '01000000',
      "启用LSPCON支持,核显 DisplayPort 转 HDMI 2.0 输出(需要搭配0~3号端口LSPCON信号转换器,适用于6代 Skylake ~ 10代 Comet Lake, Ice Lake英特尔平台)",
    );
DevicePropertyItem get framebuffer_framebuffer_con0_has_lspcon =>
    _deviceProperty(
      'framebuffer-con0-has-lspcon',
      'data',
      '01000000',
      "0号端口LSPCON 信号转换器(需要启用LSPCON支持)",
    );
DevicePropertyItem get framebuffer_framebuffer_con1_has_lspcon =>
    _deviceProperty(
      'framebuffer-con1-has-lspcon',
      'data',
      '01000000',
      "1号端口LSPCON 信号转换器(需要启用LSPCON支持)",
    );
DevicePropertyItem get framebuffer_framebuffer_con2_has_lspcon =>
    _deviceProperty(
      'framebuffer-con2-has-lspcon',
      'data',
      '01000000',
      "2号端口LSPCON 信号转换器(需要启用LSPCON支持)",
    );
DevicePropertyItem get framebuffer_framebuffer_con3_has_lspcon =>
    _deviceProperty(
      'framebuffer-con3-has-lspcon',
      'data',
      '01000000',
      "3号端口LSPCON 信号转换器(需要启用LSPCON支持)",
    );
DevicePropertyItem get framebuffer_fbmem => _deviceProperty(
      'framebuffer-fbmem',
      'data',
      '00009000',
      "修改framebuffer memory至9M(framebuffer内存大小,会影响高分屏,通常和framebuffer-stolenmem搭配使用)",
    );
DevicePropertyItem get framebuffer_stolenmem_1k => _deviceProperty(
      'framebuffer-stolenmem',
      'data',
      '00003001',
      "修改stolen memory至19M(适用于1080P屏幕,工具默认值,可以不用勾选.如果BIOS中有DVMT参数,建议修改至64M。BIOS如果更改了DVMT参数,可以去掉此参数)",
    );
DevicePropertyItem get framebuffer_stolenmem_2k => _deviceProperty(
      'framebuffer-stolenmem',
      'data',
      '00000004',
      "修改stolen memory至64M(适用于2k或4k屏幕,如果BIOS中有DVMT参数,建议修改至64M或以上。BIOS如果更改了DVMT参数,可以去掉此参数)",
    );
DevicePropertyItem get framebuffer_stolenmem_4k => _deviceProperty(
      'framebuffer-stolenmem',
      'data',
      '00000008',
      "修改stolen memory至128M(适用于4k屏幕,如果BIOS中有DVMT参数,,高分屏建议修改至128M或256M或以上。BIOS如果更改了DVMT参数,可以去掉此参数)",
    );

List<DevicePropertyItem> get _enableHdmiCon0FixItems => [
      _deviceProperty(
        'framebuffer-con0-enable',
        'data',
        '01000000',
        "启用con0 HDMI端口(需要搭配0号HDMI接口)",
      ),
      _deviceProperty(
        'framebuffer-con0-type',
        'data',
        '00080000',
        "0号HDMI接口,用于修复6~10代HDMI黑屏问题(需要启用con0 HDMI端口)",
      ),
    ];

List<DevicePropertyItem> get _enableHdmiCon1FixItems => [
      _deviceProperty(
        'framebuffer-con1-enable',
        'data',
        '01000000',
        "启用con1 HDMI端口(需要搭配1号HDMI接口)",
      ),
      _deviceProperty(
        'framebuffer-con1-type',
        'data',
        '00080000',
        "1号HDMI接口,用于修复6~10代HDMI黑屏问题(需要启用con1 HDMI端口)",
      ),
    ];

List<DevicePropertyItem> get _enableHdmiCon2FixItems => [
      _deviceProperty(
        'framebuffer-con2-enable',
        'data',
        '01000000',
        "启用con2 HDMI端口(需要搭配2号HDMI接口)",
      ),
      _deviceProperty(
        'framebuffer-con2-type',
        'data',
        '00080000',
        "2号HDMI接口,用于修复6~10代HDMI黑屏问题(需要启用con2 HDMI端口)",
      ),
    ];

class IgpuDevicePropertyOption {
  final String id;
  final String title;
  final String category;
  final String? exclusiveGroup;
  final String? multiSelectGroup;
  final String? mutexGroup;
  final List<DevicePropertyItem> items;

  const IgpuDevicePropertyOption({
    required this.id,
    required this.title,
    required this.category,
    required this.items,
    this.exclusiveGroup,
    this.multiSelectGroup,
    this.mutexGroup,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IgpuDevicePropertyOption && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

const igpuCategoryMemory = '显存/DVMT 参数';
const igpuCategoryHaswell = '4代 Haswell 专用参数';
const igpuCategoryIvyBridge = '3代 Ivy Bridge 高分屏候选补丁';
const igpuCategorySandyBridge = '2代 Sandy Bridge 高分屏候选补丁';
const igpuCategoryArrandale = '1代 Arrandale 笔记本候选补丁';
const igpuCategoryHdmi = 'HDMI/接口修复';
const igpuCategoryIceLake = '10代 Ice Lake 修复';
const igpuCategoryCommon = '通用修复';

IgpuDevicePropertyOption _option({
  required String id,
  required String title,
  required String category,
  required List<DevicePropertyItem> items,
  String? exclusiveGroup,
  String? multiSelectGroup,
  String? mutexGroup,
}) {
  return IgpuDevicePropertyOption(
    id: id,
    title: title,
    category: category,
    items: items,
    exclusiveGroup: exclusiveGroup,
    multiSelectGroup: multiSelectGroup,
    mutexGroup: mutexGroup,
  );
}

List<IgpuDevicePropertyOption> selectableIGPUDevicePropertyOptions() {
  final hdmiCon0Options = _enableHdmiCon0FixItems;
  final hdmiCon1Options = _enableHdmiCon1FixItems;
  final hdmiCon2Options = _enableHdmiCon2FixItems;

  return [
    _option(
      id: 'dvmt_32m_1080p',
      title: framebuffer_stolenmem_1k.comment ?? '',
      category: igpuCategoryMemory,
      exclusiveGroup: 'dvmt',
      items: [framebuffer_stolenmem_1k, framebuffer_fbmem],
    ),
    _option(
      id: 'stolenmem_2k',
      title: framebuffer_stolenmem_2k.comment ?? '',
      category: igpuCategoryMemory,
      exclusiveGroup: 'dvmt',
      items: [framebuffer_stolenmem_2k],
    ),
    _option(
      id: 'stolenmem_4k',
      title: framebuffer_stolenmem_4k.comment ?? '',
      category: igpuCategoryMemory,
      exclusiveGroup: 'dvmt',
      items: [framebuffer_stolenmem_4k],
    ),
    _option(
      id: 'unifiedmem_1536',
      title: framebuffer_unifiedmem_1536.comment ?? '',
      category: igpuCategoryMemory,
      exclusiveGroup: 'unifiedmem',
      items: [framebuffer_unifiedmem_1536],
    ),
    _option(
      id: 'unifiedmem_2048',
      title: framebuffer_unifiedmem_2048.comment ?? '',
      category: igpuCategoryMemory,
      exclusiveGroup: 'unifiedmem',
      items: [framebuffer_unifiedmem_2048],
    ),
    _option(
      id: 'unifiedmem_3072',
      title: framebuffer_unifiedmem_3072.comment ?? '',
      category: igpuCategoryMemory,
      exclusiveGroup: 'unifiedmem',
      items: [framebuffer_unifiedmem_3072],
    ),
    _option(
      id: 'unifiedmem_4095',
      title: framebuffer_unifiedmem_4095.comment ?? '',
      category: igpuCategoryMemory,
      exclusiveGroup: 'unifiedmem',
      items: [framebuffer_unifiedmem_4095],
    ),
    _option(
      id: 'haswell_cursormem_1080p',
      title: framebuffer_cursormem_1k.comment ?? '',
      category: igpuCategoryHaswell,
      exclusiveGroup: 'haswell_cursormem',
      items: [framebuffer_cursormem_1k],
    ),
    _option(
      id: 'haswell_cursormem_2k4k',
      title: framebuffer_cursormem_2k4k.comment ?? '',
      category: igpuCategoryHaswell,
      exclusiveGroup: 'haswell_cursormem',
      items: [framebuffer_cursormem_2k4k],
    ),
    _option(
      id: 'ivy_bridge_high_res',
      title: 'Ivy Bridge 笔记本高分屏(1600x900及以上分辨率)补丁',
      category: igpuCategoryIvyBridge,
      items: [
        framebuffer_memorycount_2,
        framebuffer_pipecount_2,
        framebuffer_portcount_4,
        framebuffer_stolenmem_2k,
        framebuffer_con1_enable,
        framebuffer_con1_alldata_ivy_high_res,
      ],
    ),
    _option(
      id: 'sandy_bridge_duallink',
      title: framebuffer_aapl00_duallink.comment ?? '',
      category: igpuCategorySandyBridge,
      items: [framebuffer_aapl00_duallink],
    ),
    _option(
      id: 'ironlake_singlelink',
      title: framebuffer_singlelink.comment ?? '',
      category: igpuCategoryArrandale,
      items: [framebuffer_singlelink],
    ),
    _option(
      id: 'hdmi_con0_type',
      title: '启用 con0 接口HDMI类型修正补丁,用于修复6~10代HDMI黑屏,紫屏,音频问题',
      category: igpuCategoryHdmi,
      multiSelectGroup: 'hdmi_type_patch',
      mutexGroup: 'hdmi_connector_mode',
      items: hdmiCon0Options,
    ),
    _option(
      id: 'hdmi_con1_type',
      title: '启用 con1 接口HDMI类型修正补丁,用于修复6~10代HDMI黑屏,紫屏,音频问题',
      category: igpuCategoryHdmi,
      multiSelectGroup: 'hdmi_type_patch',
      mutexGroup: 'hdmi_connector_mode',
      items: hdmiCon1Options,
    ),
    _option(
      id: 'hdmi_con2_type',
      title: '启用 con2 接口HDMI类型修正补丁,用于修复6~10代HDMI黑屏,紫屏,音频问题',
      category: igpuCategoryHdmi,
      multiSelectGroup: 'hdmi_type_patch',
      mutexGroup: 'hdmi_connector_mode',
      items: hdmiCon2Options,
    ),
    _option(
      id: 'ice_lake_dbuf_early_optimizer_fixes',
      title: framebuffer_enable_dbuf_early_optimizer.comment ?? '',
      category: igpuCategoryIceLake,
      items: [
        framebuffer_enable_dbuf_early_optimizer,
      ],
    ),
    _option(
      id: 'ice_lake_calc_fixes',
      title: framebuffer_enable_dvmt_calc_fix.comment ?? '',
      category: igpuCategoryIceLake,
      items: [
        framebuffer_enable_dvmt_calc_fix,
      ],
    ),
    _option(
      id: 'ice_lake_cdclk_fixes',
      title: framebuffer_enable_cdclk_frequency_fix.comment ?? '',
      category: igpuCategoryIceLake,
      items: [
        framebuffer_enable_cdclk_frequency_fix,
      ],
    ),
    _option(
      id: 'ice_lake_4k_clock',
      title: framebuffer_enable_max_pixel_clock_override.comment ?? '',
      category: igpuCategoryIceLake,
      items: [framebuffer_enable_max_pixel_clock_override],
    ),
    _option(
      id: 'hdmi20',
      title: framebuffer_enable_hdmi20.comment ?? '',
      category: igpuCategoryCommon,
      items: [framebuffer_enable_hdmi20],
    ),
    _option(
      id: 'force_online',
      title: framebuffer_force_online.comment ?? '',
      category: igpuCategoryCommon,
      items: [framebuffer_force_online],
    ),
    _option(
      id: 'rps_control',
      title: framebuffer_rps_control.comment ?? '',
      category: igpuCategoryCommon,
      items: [framebuffer_rps_control],
    ),
    _option(
      id: 'igfxfw',
      title: framebuffer_igfxfw.comment ?? '',
      category: igpuCategoryCommon,
      items: [framebuffer_igfxfw],
    ),
    _option(
      id: 'hda_gfx',
      title: framebuffer_hda_gfx.comment ?? '',
      category: igpuCategoryCommon,
      items: [framebuffer_hda_gfx],
    ),
    _option(
      id: 'disable_hdmi_patches',
      title: framebuffer_disable_hdmi_patches.comment ?? '',
      category: igpuCategoryCommon,
      items: [framebuffer_disable_hdmi_patches],
    ),
    _option(
      id: 'hdmi_dividers_fix',
      title: framebuffer_enable_hdmi_dividers_fix.comment ?? '',
      category: igpuCategoryCommon,
      items: [framebuffer_enable_hdmi_dividers_fix],
    ),
    _option(
      id: 'backlight_smoother',
      title: framebuffer_enable_backlight_smoother.comment ?? '',
      category: igpuCategoryCommon,
      items: [framebuffer_enable_backlight_smoother],
    ),
    _option(
      id: 'backlight_registers_alternative_fix',
      title:
          framebuffer_enable_backlight_registers_alternative_fix.comment ?? '',
      category: igpuCategoryCommon,
      items: [framebuffer_enable_backlight_registers_alternative_fix],
    ),
    _option(
      id: 'backlight_registers_fix',
      title: framebuffer_enable_backlight_registers_fix.comment ?? '',
      category: igpuCategoryCommon,
      items: [framebuffer_enable_backlight_registers_fix],
    ),
    _option(
      id: 'gfx_y_tile',
      title: framebuffer_aapl_GfxYTile.comment ?? '',
      category: igpuCategoryCommon,
      items: [framebuffer_aapl_GfxYTile],
    ),
    _option(
      id: 'disable_external_gpu',
      title: framebuffer_disable_external_gpu.comment ?? '',
      category: igpuCategoryCommon,
      items: [framebuffer_disable_external_gpu],
    ),
    _option(
      id: 'dpcd_max_link_rate_fix',
      title: framebuffer_enable_dpcd_max_link_rate_fix.comment ?? '',
      category: igpuCategoryCommon,
      items: [framebuffer_enable_dpcd_max_link_rate_fix],
    ),
    _option(
      id: 'aapl00_override_no_connect',
      title: framebuffer_aapl00_override_no_connect.comment ?? '',
      category: igpuCategoryCommon,
      items: [framebuffer_aapl00_override_no_connect],
    ),
    _option(
      id: 'aapl01_override_no_connect',
      title: framebuffer_aapl01_override_no_connect.comment ?? '',
      category: igpuCategoryCommon,
      items: [framebuffer_aapl01_override_no_connect],
    ),
    _option(
      id: 'aapl02_override_no_connect',
      title: framebuffer_aapl02_override_no_connect.comment ?? '',
      category: igpuCategoryCommon,
      items: [framebuffer_aapl02_override_no_connect],
    ),
    _option(
      id: 'lspcon_support',
      title: framebuffer_enable_lspcon_support.comment ?? '',
      category: igpuCategoryCommon,
      items: [framebuffer_enable_lspcon_support],
    ),
    _option(
      id: 'con0_lspcon',
      title: framebuffer_framebuffer_con0_has_lspcon.comment ?? '',
      category: igpuCategoryCommon,
      items: [framebuffer_framebuffer_con0_has_lspcon],
    ),
    _option(
      id: 'con1_lspcon',
      title: framebuffer_framebuffer_con1_has_lspcon.comment ?? '',
      category: igpuCategoryCommon,
      items: [framebuffer_framebuffer_con1_has_lspcon],
    ),
    _option(
      id: 'con2_lspcon',
      title: framebuffer_framebuffer_con2_has_lspcon.comment ?? '',
      category: igpuCategoryCommon,
      items: [framebuffer_framebuffer_con2_has_lspcon],
    ),
    _option(
      id: 'con3_lspcon',
      title: framebuffer_framebuffer_con3_has_lspcon.comment ?? '',
      category: igpuCategoryCommon,
      items: [framebuffer_framebuffer_con3_has_lspcon],
    ),
  ];
}

List<IgpuDevicePropertyOption> selectableIGPUDevicePropertyOptionsForPlatform(
  String platformCode,
) {
  return selectableIGPUDevicePropertyOptions();
}

Set<DevicePropertyItem> selectableIGPUDeviceProperties() {
  final deviceProperties = <String, DevicePropertyItem>{};
  for (final option in selectableIGPUDevicePropertyOptions()) {
    for (final item in option.items) {
      deviceProperties[_propertyIdentity(item)] = item;
    }
  }
  return deviceProperties.values.toSet();
}

String _propertyIdentity(DevicePropertyItem item) =>
    '${item.key}|${item.dataType}|${item.value}';
