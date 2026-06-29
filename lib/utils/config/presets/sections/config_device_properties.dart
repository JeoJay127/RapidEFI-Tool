// ignore_for_file: constant_identifier_names

import '../../models/device_properties/device_property_item.dart';
import '../../models/device_properties/igpu_model.dart';

class ConfigDp {
  static const pciPath = "PciRoot(0x0)/Pci(0x2,0x0)";

  static const imei_pciPath = "PciRoot(0x0)/Pci(0x16,0x0)";

  static DevicePropertyItem sandyBridge_imei = DevicePropertyItem(
    key: 'device-id',
    dataType: 'data',
    value: '3A1C0000',
    comment: '2代CPU - 3代主板混合',
  );

  static DevicePropertyItem ivyBridge_imei = DevicePropertyItem(
    key: 'device-id',
    dataType: 'data',
    value: '3A1E0000',
    comment: '3代CPU - 2代主板混合',
  );

  ///2代，不驱动核显
  static DevicePropertyItem display_none_2th = DevicePropertyItem(
    key: 'AAPL,snb-platform-id',
    dataType: 'data',
    value: '11223344',
    comment: '暂不驱动核显完成安装(可以避免核显缓冲帧问题导致黑屏,内核崩溃问题)',
    display: false,
  );

  ///3代及以上,不驱动核显
  static DevicePropertyItem display_none_3th = display_none_2th.copyWith(
    key: 'AAPL,ig-platform-id',
  );

  static DevicePropertyItem device_id = DevicePropertyItem(
    key: 'device-id',
    dataType: 'data',
    value: '仿冒设备ID',
  );

  ///2代,计算
  static DevicePropertyItem comuting_id_2th = DevicePropertyItem(
      key: 'AAPL,snb-platform-id',
      dataType: 'data',
      value: '',
      comment: '核显仅用于加速、计算任务，不作为输出显示(独立显卡输出显示)',
      display: false);

  ///3代及以上,计算
  static DevicePropertyItem comuting_id_3th =
      comuting_id_2th.copyWith(key: 'AAPL,ig-platform-id', display: false);

  static DevicePropertyItem intel_desktop_display_2th =
      display_none_2th.copyWith(
          value: '10000300', comment: 'HD3000、HD P3000等核显', display: true);

  static DevicePropertyItem intel_desktop_display_fakeid_2th =
      device_id.copyWith(
    value: '26010000',
  );

  static DevicePropertyItem intel_desktop_computing_fakeid_2th =
      device_id.copyWith(
    value: '02010000',
  );

  static DevicePropertyItem intel_desktop_computing_id_2th =
      comuting_id_2th.copyWith(
    value: '00000500',
  );

  static IgpuPropertyModel intel_desktop =
      IgpuPropertyModel(pciPath: pciPath, propertyItems: []);
  static IgpuPropertyModel intel_desktop_imei_2th = IgpuPropertyModel(
      pciPath: imei_pciPath, propertyItems: [sandyBridge_imei]);

  ///2代核显，输出显示
  static List<IgpuPropertyModel> intel_desktop_2th = [
    intel_desktop.copyWith(
      pciPath: pciPath,
      propertyItems: [
        intel_desktop_display_2th,
        intel_desktop_display_fakeid_2th
      ],
    )
  ];

  ///2代核显,不驱动输出显示
  static List<IgpuPropertyModel> intel_desktop_display_none_2th = [
    intel_desktop.copyWith(
      propertyItems: [display_none_2th],
    )
  ];

  ///2代核显,计算
  ///
  static List<IgpuPropertyModel> intel_desktop_computing_2th = [
    intel_desktop.copyWith(propertyItems: [intel_desktop_computing_id_2th])
  ];

  ///3代,核显输出
  static DevicePropertyItem intel_desktop_display_3th =
      display_none_3th.copyWith(
          value: '0A006601', comment: 'HD4000、HD P4000等核显', display: true);

  static DevicePropertyItem intel_desktop_display_fakeid_3th =
      device_id.copyWith(
    value: '66010000',
  );

  static DevicePropertyItem intel_desktop_computing_id_3th =
      comuting_id_3th.copyWith(
    value: '07006201',
  );

  static DevicePropertyItem intel_desktop_computing_fakeid_3th =
      device_id.copyWith(
    value: '02010000',
  );

  static IgpuPropertyModel intel_desktop_imei_3th =
      IgpuPropertyModel(pciPath: imei_pciPath, propertyItems: [ivyBridge_imei]);

  ///3代核显,输出显示
  static List<IgpuPropertyModel> intel_desktop_3th = [
    intel_desktop.copyWith(
      propertyItems: [
        intel_desktop_display_3th,
        intel_desktop_display_fakeid_3th
      ],
    )
  ];

  ///3代核显,不驱动输出显示
  static List<IgpuPropertyModel> intel_desktop_display_none_3th = [
    intel_desktop.copyWith(
      propertyItems: [display_none_3th],
    )
  ];

  ///3代核显计算属性
  static List<IgpuPropertyModel> intel_desktop_computing_3th = [
    intel_desktop.copyWith(propertyItems: [intel_desktop_computing_id_3th])
  ];

  ///4代,核显输出
  static DevicePropertyItem intel_desktop_display_4th =
      intel_desktop_display_3th.copyWith(
          value: '0300220D', comment: 'HD4400、HD4600、HD P4600等核显');

  static DevicePropertyItem intel_desktop_display_fakeid_4th =
      device_id.copyWith(
    value: '12040000',
  );

  static DevicePropertyItem intel_desktop_computing_id_4th =
      comuting_id_3th.copyWith(
    value: '04001204',
  );

  ///4代,输出显示
  static List<IgpuPropertyModel> intel_desktop_4th = [
    intel_desktop.copyWith(
      propertyItems: [
        intel_desktop_display_4th,
        intel_desktop_display_fakeid_4th
      ],
    )
  ];

  static List<IgpuPropertyModel> intel_desktop_display_none_4th = [
    intel_desktop.copyWith(
      propertyItems: [display_none_3th],
    )
  ];

  ///4代,计算
  static List<IgpuPropertyModel> intel_desktop_computing_4th = [
    intel_desktop.copyWith(
      propertyItems: [intel_desktop_computing_id_4th],
    )
  ];

  ///5代,核显输出
  static DevicePropertyItem intel_desktop_display_5th_1 =
      intel_desktop_display_3th.copyWith(
          value: '07002216', comment: 'Iris Pro 6200/6300等核显');

  static DevicePropertyItem intel_desktop_display_fakeid_5th_1 =
      device_id.copyWith(
    value: '26160000',
  );

  static DevicePropertyItem intel_desktop_display_5th_2 =
      intel_desktop_display_3th.copyWith(
          value: '03001216', comment: 'HD5600核显(P6200,P6300可仿冒此设备)');

  static DevicePropertyItem intel_desktop_display_fakeid_5th_2 =
      device_id.copyWith(
    value: '12160000',
  );

  static DevicePropertyItem intel_desktop_display_5th_3 =
      intel_desktop_display_3th.copyWith(
          value: '00002B16', comment: 'HD6000,Iris 6100等核显');

  static DevicePropertyItem intel_desktop_display_fakeid_5th_3 =
      device_id.copyWith(
    value: '26160000',
  );

  static DevicePropertyItem intel_desktop_computing_id_5th =
      comuting_id_3th.copyWith(
    value: '04001204',
  );

  ///5代,输出显示
  static List<IgpuPropertyModel> intel_desktop_5th_1 = [
    intel_desktop.copyWith(
      propertyItems: [
        intel_desktop_display_5th_1,
        intel_desktop_display_fakeid_5th_1
      ],
    )
  ];

  static List<IgpuPropertyModel> intel_desktop_5th_2 = [
    intel_desktop.copyWith(
      propertyItems: [
        intel_desktop_display_5th_2,
        intel_desktop_display_fakeid_5th_2
      ],
    )
  ];

  static List<IgpuPropertyModel> intel_desktop_5th_3 = [
    intel_desktop.copyWith(
      propertyItems: [
        intel_desktop_display_5th_3,
        intel_desktop_display_fakeid_5th_3
      ],
    )
  ];

  static List<IgpuPropertyModel> intel_desktop_display_none_5th = [
    intel_desktop.copyWith(
      propertyItems: [display_none_3th],
    )
  ];

  ///5代,计算
  static List<IgpuPropertyModel> intel_desktop_computing_5th = [
    intel_desktop.copyWith(
      propertyItems: [intel_desktop_computing_id_5th],
    )
  ];

  ///6代,核显输出
  static DevicePropertyItem intel_desktop_display_6th_1 =
      intel_desktop_display_3th.copyWith(
          value: '00001659', comment: 'HD520,HD530等仿冒HD620核显(适用于Ventura以上系统)');

  static DevicePropertyItem intel_desktop_display_fakeid_6th_1 =
      device_id.copyWith(
    value: '16590000',
  );

  static DevicePropertyItem intel_desktop_display_6th_2 =
      intel_desktop_display_3th.copyWith(
          value: '00001B59',
          comment: 'HD520,HD530等仿冒HD620核显(适用于Ventura以上系统,备选方案)');

  static DevicePropertyItem intel_desktop_display_fakeid_6th_2 =
      device_id.copyWith(
    value: '1B590000',
  );

  static DevicePropertyItem intel_desktop_display_6th_3 =
      intel_desktop_display_3th.copyWith(
          value: '00001219',
          comment: 'HD530、HD P530等500系列核显(适用于Monterey及以下系统)');

  static DevicePropertyItem intel_desktop_display_fakeid_6th_3 =
      device_id.copyWith(
    value: '1B190000',
  );

  static DevicePropertyItem intel_desktop_computing_id_6th =
      comuting_id_3th.copyWith(
    value: '01001219',
  );

  ///6代,输出显示
  static List<IgpuPropertyModel> intel_desktop_6th_1 = [
    intel_desktop.copyWith(
      propertyItems: [
        intel_desktop_display_6th_1,
        intel_desktop_display_fakeid_6th_1
      ],
    )
  ];

  static List<IgpuPropertyModel> intel_desktop_6th_2 = [
    intel_desktop.copyWith(
      propertyItems: [
        intel_desktop_display_6th_2,
        intel_desktop_display_fakeid_6th_2
      ],
    )
  ];

  static List<IgpuPropertyModel> intel_desktop_6th_3 = [
    intel_desktop.copyWith(
      propertyItems: [
        intel_desktop_display_6th_3,
        intel_desktop_display_fakeid_6th_3
      ],
    )
  ];

  static List<IgpuPropertyModel> intel_desktop_display_none_6th = [
    intel_desktop.copyWith(
      propertyItems: [display_none_3th],
    )
  ];

  ///6代,计算
  static List<IgpuPropertyModel> intel_desktop_computing_6th = [
    intel_desktop.copyWith(
      propertyItems: [intel_desktop_computing_id_6th],
    )
  ];

  ///7代,核显输出
  static DevicePropertyItem intel_desktop_display_7th_1 =
      intel_desktop_display_3th.copyWith(
          value: '00001259', comment: 'HD 630、HD P630等核显');

  static DevicePropertyItem intel_desktop_display_fakeid_7th_1 =
      device_id.copyWith(
    value: '12590000',
  );

  static DevicePropertyItem intel_desktop_display_7th_2 =
      intel_desktop_display_3th.copyWith(
          value: '07009B3E', comment: 'HD 630、P630等仿冒UHD630核显(方案一)');

  static DevicePropertyItem intel_desktop_display_fakeid_7th_2 =
      device_id.copyWith(
    value: '9B3E0000',
  );

  static DevicePropertyItem intel_desktop_display_7th_3 =
      intel_desktop_display_3th.copyWith(
          value: '00009B3E', comment: 'HD 630、P630等仿冒UHD630核显(方案二)');

  static DevicePropertyItem intel_desktop_display_fakeid_7th_3 =
      device_id.copyWith(
    value: '9B3E0000',
  );
  static DevicePropertyItem intel_desktop_computing_id_7th =
      comuting_id_3th.copyWith(
    value: '03001259',
  );

  ///7代,输出显示
  static List<IgpuPropertyModel> intel_desktop_7th_1 = [
    intel_desktop.copyWith(
      propertyItems: [
        intel_desktop_display_7th_1,
        intel_desktop_display_fakeid_7th_1,
      ],
    )
  ];

  static List<IgpuPropertyModel> intel_desktop_7th_2 = [
    intel_desktop.copyWith(
      propertyItems: [
        intel_desktop_display_7th_2,
        intel_desktop_display_fakeid_7th_2,
      ],
    )
  ];

  static List<IgpuPropertyModel> intel_desktop_7th_3 = [
    intel_desktop.copyWith(
      propertyItems: [
        intel_desktop_display_7th_3,
        intel_desktop_display_fakeid_7th_3,
      ],
    )
  ];

  static List<IgpuPropertyModel> intel_desktop_display_none_7th = [
    intel_desktop.copyWith(
      propertyItems: [display_none_3th],
    )
  ];

  ///7代,计算
  static List<IgpuPropertyModel> intel_desktop_computing_7th = [
    intel_desktop.copyWith(
      propertyItems: [intel_desktop_computing_id_7th],
    )
  ];

  ///8代,核显输出
  static DevicePropertyItem intel_desktop_display_8th_1 =
      intel_desktop_display_3th.copyWith(
          value: '07009B3E', comment: 'UHD 630核显显示输出方案一');

  static DevicePropertyItem intel_desktop_display_fakeid_8th_1 =
      device_id.copyWith(
    value: '9B3E0000',
  );

  static DevicePropertyItem intel_desktop_display_8th_2 =
      intel_desktop_display_3th.copyWith(
          value: '00009B3E', comment: 'UHD 630核显方显示输出案二');

  static DevicePropertyItem intel_desktop_display_fakeid_8th_2 =
      intel_desktop_display_fakeid_8th_1.copyWith();

  static DevicePropertyItem intel_desktop_computing_id_8th =
      comuting_id_3th.copyWith(
    value: '0300913E',
  );

  ///8代,输出显示
  static List<IgpuPropertyModel> intel_desktop_8th_1 = [
    intel_desktop.copyWith(
      propertyItems: [
        intel_desktop_display_8th_1,
        intel_desktop_display_fakeid_8th_1
      ],
    )
  ];

  static List<IgpuPropertyModel> intel_desktop_8th_2 = [
    intel_desktop.copyWith(
      propertyItems: [
        intel_desktop_display_8th_2,
        intel_desktop_display_fakeid_8th_2
      ],
    )
  ];

  static List<IgpuPropertyModel> intel_desktop_display_none_8th = [
    intel_desktop.copyWith(
      propertyItems: [display_none_3th],
    )
  ];
  static List<IgpuPropertyModel> intel_desktop_computing_8th = [
    intel_desktop.copyWith(
      propertyItems: [intel_desktop_computing_id_8th],
    )
  ];

  static DevicePropertyItem intel_desktop_computing_id_10th =
      comuting_id_3th.copyWith(
    value: '0300C89B',
  );

  ///10代,核显计算
  static List<IgpuPropertyModel> intel_desktop_computing_10th = [
    intel_desktop.copyWith(
      propertyItems: [intel_desktop_computing_id_10th],
    )
  ];

  static DevicePropertyItem intel_laptop_display_1th = DevicePropertyItem(
    key: 'framebuffer-patch-enable',
    dataType: 'data',
    value: '01000000',
    comment: 'Intel HD Graphics(比如:i3 380M,i5 480M自带核显)',
  );

  static DevicePropertyItem framebuffe_singlelink = DevicePropertyItem(
    key: 'framebuffer-singlelink',
    dataType: 'data',
    value: '01000000',
    comment: '',
  );

  static List<IgpuPropertyModel> intel_laptop_1th = [
    intel_desktop.copyWith(
      propertyItems: [intel_laptop_display_1th, framebuffe_singlelink],
    )
  ];

  static DevicePropertyItem intel_laptop_display_2th = DevicePropertyItem(
    key: 'AAPL,snb-platform-id',
    dataType: 'data',
    value: '00000100',
    comment: 'HD3000核显输出显示,适用于1366x768及以下分辨率)',
  );

  static DevicePropertyItem AAPL00_DualLink = DevicePropertyItem(
    key: 'AAPL00,DualLink',
    dataType: 'data',
    value: '01000000',
    comment: '启用支持1600X900以上分辨率',
  );

  static DevicePropertyItem intel_laptop_device_id = DevicePropertyItem(
    key: 'device-id',
    dataType: 'data',
    value: '16010000',
    comment: '仿冒设备ID',
  );

  static DevicePropertyItem intel_laptop_imei_2th = sandyBridge_imei.copyWith();

  static IgpuPropertyModel intel_laptop_imei_model_2th = IgpuPropertyModel(
      pciPath: imei_pciPath, propertyItems: [intel_laptop_imei_2th]);

  static List<IgpuPropertyModel> intel_laptop_2th_1 = [
    intel_desktop.copyWith(
      propertyItems: [intel_laptop_display_2th],
    )
  ];

  static List<IgpuPropertyModel> intel_laptop_2th_2 = [
    intel_desktop.copyWith(
      propertyItems: [
        intel_laptop_display_2th.copyWith(
            comment: 'HD3000核显输出显示,适用于1600x900及以上分辨率)'),
        AAPL00_DualLink
      ],
    )
  ];

  static List<IgpuPropertyModel> intel_laptop_2th_3 = [
    intel_desktop.copyWith(
      propertyItems: [display_none_2th],
    )
  ];

  static DevicePropertyItem intel_laptop_display_3th_1 = DevicePropertyItem(
    key: 'AAPL,ig-platform-id',
    dataType: 'data',
    value: '03006601',
    comment: 'HD4000核显驱动方案一,适用于1366x768及以下分辨率,LVDS链接方式',
  );

  static DevicePropertyItem intel_laptop_display_3th_2 =
      intel_laptop_display_3th_1.copyWith(
    value: '04006601',
    comment: 'HD4000核显驱动方案二,适用于1600x900及以上分辨率LVDS链接方式,多屏输出可能需要更多补丁配置)',
  );

  static DevicePropertyItem intel_laptop_display_3th_3 =
      intel_laptop_display_3th_1.copyWith(
    value: '09006601',
    comment: 'HD4000核显驱动方案三,适用于以eDP连接方式的显示器)',
  );

  static DevicePropertyItem intel_laptop_device_id_3th =
      intel_laptop_device_id.copyWith(
    value: '66010000',
  );

  static DevicePropertyItem intel_laptop_imei_3th = ivyBridge_imei.copyWith();

  static IgpuPropertyModel intel_laptop_imei_model_3th = IgpuPropertyModel(
      pciPath: imei_pciPath, propertyItems: [intel_laptop_imei_3th]);

  static List<IgpuPropertyModel> intel_laptop_3th_1 = [
    intel_desktop.copyWith(
      propertyItems: [intel_laptop_display_3th_1, intel_laptop_device_id_3th],
    )
  ];

  static List<IgpuPropertyModel> intel_laptop_3th_2 = [
    intel_desktop.copyWith(
      propertyItems: [
        intel_laptop_display_3th_2.copyWith(),
        intel_laptop_device_id_3th
      ],
    )
  ];

  static List<IgpuPropertyModel> intel_laptop_3th_3 = [
    intel_desktop.copyWith(
      propertyItems: [
        intel_laptop_display_3th_3.copyWith(),
        intel_laptop_device_id_3th
      ],
    )
  ];

  static List<IgpuPropertyModel> intel_laptop_3th_4 = [
    intel_desktop.copyWith(
      propertyItems: [display_none_3th],
    )
  ];

  static DevicePropertyItem intel_laptop_display_4th_1 = DevicePropertyItem(
    key: 'AAPL,ig-platform-id',
    dataType: 'data',
    value: '0600260A',
    comment: 'HD4200、HD4400、HD4600核显',
  );

  static DevicePropertyItem intel_laptop_display_4th_2 =
      intel_laptop_display_3th_1.copyWith(
    value: '0500260A',
    comment: 'HD5000、HD5100、HD5200核显',
  );

  static DevicePropertyItem intel_laptop_display_4th_3 = display_none_3th;

  static DevicePropertyItem intel_laptop_device_id_4th =
      intel_laptop_device_id.copyWith(
    value: '12040000',
  );

  static List<IgpuPropertyModel> intel_laptop_4th_1 = [
    intel_desktop.copyWith(
      propertyItems: [intel_laptop_display_4th_1, intel_laptop_device_id_4th],
    )
  ];
  static List<IgpuPropertyModel> intel_laptop_4th_2 = [
    intel_desktop.copyWith(
      propertyItems: [intel_laptop_display_4th_2, intel_laptop_device_id_4th],
    ),
    intel_laptop_imei_model_3th
  ];
  static List<IgpuPropertyModel> intel_laptop_4th_3 = [
    intel_desktop.copyWith(
      propertyItems: [intel_laptop_display_4th_3],
    )
  ];

  static DevicePropertyItem intel_laptop_display_5th = DevicePropertyItem(
    key: 'AAPL,ig-platform-id',
    dataType: 'data',
    value: '06002616',
    comment: 'HD5500核显',
  );

  static DevicePropertyItem intel_laptop_display_5th_4 = display_none_3th;

  static DevicePropertyItem intel_laptop_device_id_5th_1 =
      intel_laptop_device_id.copyWith(
    value: '16160000',
  );

  static DevicePropertyItem intel_laptop_device_id_5th_2 =
      intel_laptop_device_id.copyWith(
    value: '26160000',
  );

  static DevicePropertyItem intel_laptop_device_id_5th_3 =
      intel_laptop_device_id.copyWith(
    value: '26160000',
  );

  static List<IgpuPropertyModel> intel_laptop_5th_1 = [
    intel_desktop.copyWith(
      propertyItems: [intel_laptop_display_5th, intel_laptop_device_id_5th_1],
    )
  ];
  static List<IgpuPropertyModel> intel_laptop_5th_2 = [
    intel_desktop.copyWith(
      propertyItems: [
        intel_laptop_display_5th.copyWith(comment: 'HD5600核显'),
        intel_laptop_device_id_5th_2
      ],
    ),
  ];
  static List<IgpuPropertyModel> intel_laptop_5th_3 = [
    intel_desktop.copyWith(
      propertyItems: [
        intel_laptop_display_5th.copyWith(
            value: '00002B16', comment: 'HD6000核显'),
        intel_laptop_device_id_5th_3
      ],
    ),
  ];
  static List<IgpuPropertyModel> intel_laptop_5th_4 = [
    intel_desktop.copyWith(
      propertyItems: [intel_laptop_display_5th_4],
    )
  ];

  static DevicePropertyItem intel_laptop_display_6th_1 = DevicePropertyItem(
    key: 'AAPL,ig-platform-id',
    dataType: 'data',
    value: '00001659',
    comment: 'HD520,HD530等仿冒HD620核显(用于Ventura以上系统)',
  );
  static DevicePropertyItem intel_laptop_device_id_6th_1 =
      intel_laptop_device_id.copyWith(
    value: '16590000',
  );
  static DevicePropertyItem intel_laptop_display_6th_2 =
      intel_laptop_display_6th_1.copyWith(
    value: '00001619',
    comment: 'HD 515、HD 520、HD 530、 HD 540、 HD 550、P530核显(适用于Monterey及以下系统)',
  );
  static DevicePropertyItem intel_laptop_device_id_6th_2 =
      intel_laptop_device_id.copyWith(
    value: '16190000',
  );

  static DevicePropertyItem intel_laptop_display_6th_3 =
      intel_laptop_display_6th_1.copyWith(
    value: '00001E19',
    comment: 'HD 515核显备选方案',
  );

  static DevicePropertyItem intel_laptop_display_6th_4 =
      intel_laptop_display_6th_1.copyWith(
    value: '00001B19',
    comment: 'HD 510核显',
  );
  static DevicePropertyItem intel_laptop_device_id_6th_4 =
      intel_laptop_device_id.copyWith(
    value: '02190000',
  );

  static DevicePropertyItem intel_laptop_display_6th_5 = display_none_3th;

  static List<IgpuPropertyModel> intel_laptop_6th_1 = [
    intel_desktop.copyWith(
      propertyItems: [intel_laptop_display_6th_1, intel_laptop_device_id_6th_1],
    )
  ];
  static List<IgpuPropertyModel> intel_laptop_6th_2 = [
    intel_desktop.copyWith(
      propertyItems: [intel_laptop_display_6th_2, intel_laptop_device_id_6th_2],
    ),
  ];
  static List<IgpuPropertyModel> intel_laptop_6th_3 = [
    intel_desktop.copyWith(
      propertyItems: [intel_laptop_display_6th_3],
    )
  ];

  static List<IgpuPropertyModel> intel_laptop_6th_4 = [
    intel_desktop.copyWith(
      propertyItems: [intel_laptop_display_6th_4, intel_laptop_device_id_6th_4],
    )
  ];

  static List<IgpuPropertyModel> intel_laptop_6th_5 = [
    intel_desktop.copyWith(
      propertyItems: [intel_laptop_display_6th_5],
    )
  ];

  static DevicePropertyItem intel_laptop_display_7th_1 = DevicePropertyItem(
    key: 'AAPL,ig-platform-id',
    dataType: 'data',
    value: '00001B59',
    comment: 'HD 615、 HD 620、HD 630、 HD 640、HD 650核显',
  );
  static DevicePropertyItem intel_laptop_device_id_7th_1 =
      intel_laptop_device_id.copyWith(
    value: '16590000',
  );

  static DevicePropertyItem intel_laptop_display_7th_2 =
      intel_nuc_display_7th_1.copyWith(
    value: '00001659',
    comment: 'HD/UHD 620核显备选方案',
  );
  static DevicePropertyItem intel_laptop_device_id_7th_2 =
      intel_laptop_device_id.copyWith(
    value: '16590000',
  );

  static DevicePropertyItem intel_laptop_display_7th_3 =
      intel_laptop_display_6th_1.copyWith(
    value: '0000C087',
    comment: 'UHD 617、UHD 620核显',
  );
  static DevicePropertyItem intel_laptop_device_id_7th_3 =
      intel_laptop_device_id.copyWith(
    value: '16590000',
  );

  static DevicePropertyItem intel_laptop_display_7th_4 = display_none_3th;

  static List<IgpuPropertyModel> intel_laptop_7th_1 = [
    intel_desktop.copyWith(
      propertyItems: [intel_laptop_display_7th_1, intel_laptop_device_id_7th_1],
    )
  ];
  static List<IgpuPropertyModel> intel_laptop_7th_2 = [
    intel_desktop.copyWith(
      propertyItems: [intel_laptop_display_7th_2, intel_laptop_device_id_7th_2],
    )
  ];

  static List<IgpuPropertyModel> intel_laptop_7th_3 = [
    intel_desktop.copyWith(
      propertyItems: [intel_laptop_display_7th_3, intel_laptop_device_id_7th_3],
    )
  ];

  static List<IgpuPropertyModel> intel_laptop_7th_4 = [
    intel_desktop.copyWith(
      propertyItems: [intel_laptop_display_7th_4],
    )
  ];

  static DevicePropertyItem intel_laptop_display_8th_1 = DevicePropertyItem(
    key: 'AAPL,ig-platform-id',
    dataType: 'data',
    value: '0900A53E',
    comment: 'UHD 630核显',
  );
  static DevicePropertyItem intel_laptop_device_id_8th_1 =
      intel_laptop_device_id.copyWith(
    value: '9B3E0000',
  );

  static DevicePropertyItem intel_laptop_display_8th_2 =
      intel_laptop_display_8th_1.copyWith(
    value: '00009B3E',
    comment: 'UHD 620核显',
  );
  static DevicePropertyItem intel_laptop_device_id_8th_2 =
      intel_laptop_device_id.copyWith(
    value: '9B3E0000',
  );

  static DevicePropertyItem intel_laptop_display_8th_3 =
      intel_laptop_display_6th_1.copyWith(
    value: '0400A53E',
    comment: 'Intel lris Plus 655核显',
  );
  static DevicePropertyItem intel_laptop_device_id_8th_3 =
      intel_laptop_device_id.copyWith(
    value: 'A53E0000',
  );

  static DevicePropertyItem intel_laptop_display_8th_4 = display_none_3th;

  static List<IgpuPropertyModel> intel_laptop_8th_1 = [
    intel_desktop.copyWith(
      propertyItems: [intel_laptop_display_8th_1, intel_laptop_device_id_8th_1],
    )
  ];
  static List<IgpuPropertyModel> intel_laptop_8th_2 = [
    intel_desktop.copyWith(
      propertyItems: [intel_laptop_display_8th_2, intel_laptop_device_id_8th_2],
    )
  ];

  static List<IgpuPropertyModel> intel_laptop_8th_3 = [
    intel_desktop.copyWith(
      propertyItems: [intel_laptop_display_8th_3, intel_laptop_device_id_8th_3],
    )
  ];

  static List<IgpuPropertyModel> intel_laptop_8th_4 = [
    intel_desktop.copyWith(
      propertyItems: [intel_laptop_display_8th_4],
    )
  ];

  static DevicePropertyItem intel_laptop_display_9th_1 = DevicePropertyItem(
    key: 'AAPL,ig-platform-id',
    dataType: 'data',
    value: '0900A53E',
    comment: 'UHD 630核显',
  );
  static DevicePropertyItem intel_laptop_device_id_9th_1 =
      intel_laptop_device_id.copyWith(
    value: '9B3E0000',
  );

  static DevicePropertyItem intel_laptop_display_9th_2 =
      intel_laptop_display_9th_1.copyWith(
    value: '00009B3E',
    comment: 'UHD 620核显',
  );
  static DevicePropertyItem intel_laptop_device_id_9th_2 =
      intel_laptop_device_id.copyWith(
    value: '9B3E0000',
  );

  static DevicePropertyItem intel_laptop_display_9th_3 = display_none_3th;

  static List<IgpuPropertyModel> intel_laptop_9th_1 = [
    intel_desktop.copyWith(
      propertyItems: [intel_laptop_display_9th_1, intel_laptop_device_id_9th_1],
    )
  ];
  static List<IgpuPropertyModel> intel_laptop_9th_2 = [
    intel_desktop.copyWith(
      propertyItems: [intel_laptop_display_9th_2, intel_laptop_device_id_9th_2],
    )
  ];

  static List<IgpuPropertyModel> intel_laptop_9th_3 = [
    intel_desktop.copyWith(
      propertyItems: [intel_laptop_display_9th_3],
    )
  ];

  static List<IgpuPropertyModel> intel_laptop_10th_1 = [
    intel_desktop.copyWith(
      propertyItems: [intel_laptop_display_9th_1, intel_laptop_device_id_9th_1],
    )
  ];

  static List<IgpuPropertyModel> intel_laptop_10th_2 = [
    intel_desktop.copyWith(
      propertyItems: [intel_laptop_display_9th_2, intel_laptop_device_id_9th_2],
    )
  ];

  static List<IgpuPropertyModel> intel_laptop_10th_3 = [
    intel_desktop.copyWith(
      propertyItems: [intel_laptop_display_9th_3],
    )
  ];

  static DevicePropertyItem intel_laptop_display_iceLake = DevicePropertyItem(
    key: 'AAPL,ig-platform-id',
    dataType: 'data',
    value: '0000528A',
    comment: 'G4/G7系列核显',
  );
  static DevicePropertyItem intel_laptop_device_id_iceLake =
      intel_laptop_device_id.copyWith(
    value: '528A0000',
  );

  static DevicePropertyItem intel_laptop_display_none_iceLake =
      display_none_3th;

  static List<IgpuPropertyModel> intel_laptop_iceLake_1 = [
    intel_desktop.copyWith(
      propertyItems: [
        intel_laptop_display_iceLake,
        intel_laptop_device_id_iceLake
      ],
    )
  ];
  static List<IgpuPropertyModel> intel_laptop_iceLake_2 = [
    intel_desktop.copyWith(
      propertyItems: [intel_laptop_display_none_iceLake],
    )
  ];

  static DevicePropertyItem intel_nuc_display_1th =
      intel_laptop_display_1th.copyWith();

  static List<IgpuPropertyModel> intel_nuc_1th = [
    intel_desktop.copyWith(
      propertyItems: [intel_laptop_display_1th, framebuffe_singlelink],
    )
  ];

  static DevicePropertyItem intel_nuc_display_2th =
      intel_laptop_display_2th.copyWith(
    value: '10000300',
    comment: 'HD3000核显输出显示',
  );

  static DevicePropertyItem intel_nuc_device_id =
      intel_laptop_device_id.copyWith();

  static List<IgpuPropertyModel> intel_nuc_2th_1 = [
    intel_desktop.copyWith(
      propertyItems: [intel_nuc_display_2th],
    )
  ];

  static List<IgpuPropertyModel> intel_nuc_2th_2 = [
    intel_desktop.copyWith(
      propertyItems: [
        display_none_2th,
      ],
    ),
  ];

  static DevicePropertyItem intel_nuc_display_3th = DevicePropertyItem(
    key: 'AAPL,ig-platform-id',
    dataType: 'data',
    value: '0B006601',
    comment: 'HD4000核显输出显示',
  );
  static DevicePropertyItem intel_nuc_device_id_3th =
      intel_laptop_device_id.copyWith(
    value: '66010000',
  );

  static List<IgpuPropertyModel> intel_nuc_3th_1 = [
    intel_desktop.copyWith(
      propertyItems: [intel_nuc_display_3th, intel_nuc_device_id_3th],
    ),
  ];

  static List<IgpuPropertyModel> intel_nuc_3th_2 = [
    intel_desktop.copyWith(
      propertyItems: [
        display_none_3th,
      ],
    ),
  ];

  static DevicePropertyItem intel_nuc_display_4th = DevicePropertyItem(
    key: 'AAPL,ig-platform-id',
    dataType: 'data',
    value: '0300220D',
    comment:
        'HD4200,HD4400,HD4600,HD P4600等核显(建议在核显高级配置中勾选4代核显专用补丁,已修补可能出现的小问题)',
  );
  static DevicePropertyItem intel_nuc_device_id_4th =
      intel_laptop_device_id.copyWith(
    value: '12040000',
  );

  static List<IgpuPropertyModel> intel_nuc_4th_1 = [
    intel_desktop.copyWith(
      propertyItems: [intel_nuc_display_4th, intel_nuc_device_id_4th],
    ),
  ];

  static List<IgpuPropertyModel> intel_nuc_4th_2 = [
    intel_desktop.copyWith(
      propertyItems: [
        display_none_3th,
      ],
    ),
  ];

  static DevicePropertyItem intel_nuc_display_5th = DevicePropertyItem(
    key: 'AAPL,ig-platform-id',
    dataType: 'data',
    value: '02002616',
    comment: 'HD5500核显',
  );

  static DevicePropertyItem intel_nuc_display_5th_4 = display_none_3th;

  static DevicePropertyItem intel_nuc_device_id_5th_1 =
      intel_laptop_device_id.copyWith(
    value: '16160000',
  );

  static DevicePropertyItem intel_nuc_device_id_5th_2 =
      intel_laptop_device_id.copyWith(
    value: '26160000',
  );

  static DevicePropertyItem intel_nuc_device_id_5th_3 =
      intel_laptop_device_id.copyWith(
    value: '26160000',
  );

  static List<IgpuPropertyModel> intel_nuc_5th_1 = [
    intel_desktop.copyWith(
      propertyItems: [intel_nuc_display_5th, intel_nuc_device_id_5th_1],
    )
  ];
  static List<IgpuPropertyModel> intel_nuc_5th_2 = [
    intel_desktop.copyWith(
      propertyItems: [
        intel_nuc_display_5th.copyWith(comment: 'HD5600核显'),
        intel_nuc_device_id_5th_2
      ],
    )
  ];
  static List<IgpuPropertyModel> intel_nuc_5th_3 = [
    intel_desktop.copyWith(
      propertyItems: [
        intel_nuc_display_5th.copyWith(value: '00002B16', comment: 'HD6000核显'),
        intel_nuc_device_id_5th_3
      ],
    )
  ];
  static List<IgpuPropertyModel> intel_nuc_5th_4 = [
    intel_desktop.copyWith(
      propertyItems: [intel_nuc_display_5th_4],
    )
  ];

  static DevicePropertyItem intel_nuc_display_6th_1 = DevicePropertyItem(
    key: 'AAPL,ig-platform-id',
    dataType: 'data',
    value: '00001B59',
    comment: 'HD520,HD530等仿冒HD620核显(用于Ventura以上系统)',
  );
  static DevicePropertyItem intel_nuc_device_id_6th_1 =
      intel_laptop_device_id.copyWith(
    value: '16590000',
  );
  static DevicePropertyItem intel_nuc_display_6th_2 =
      intel_laptop_display_6th_1.copyWith(
    value: '00001E19',
    comment: 'HD 515核显',
  );

  static DevicePropertyItem intel_nuc_display_6th_3 =
      intel_laptop_display_6th_1.copyWith(
    value: '02001619',
    comment: 'HD 520/530核显',
  );
  static DevicePropertyItem intel_nuc_device_id_6th_3 =
      intel_laptop_device_id.copyWith(
    value: '16190000',
  );

  static DevicePropertyItem intel_nuc_display_6th_4 =
      intel_laptop_display_6th_1.copyWith(
    value: '02002619',
    comment: 'HD 540/550核显',
  );
  static DevicePropertyItem intel_nuc_device_id_6th_4 =
      intel_laptop_device_id.copyWith(
    value: '16190000',
  );
  static DevicePropertyItem intel_nuc_display_6th_5 =
      intel_laptop_display_6th_1.copyWith(
    value: '05003B19',
    comment: 'HD 580核显',
  );

  static DevicePropertyItem intel_nuc_display_6th_6 =
      intel_laptop_display_6th_1.copyWith(
    value: '00001619',
    comment: 'HD P530核显(比如e3 1245v5自带核显)',
  );
  static DevicePropertyItem intel_nuc_device_id_6th_6 =
      intel_laptop_device_id.copyWith(
    value: '16190000',
  );

  static DevicePropertyItem intel_nuc_display_6th_7 = display_none_3th;

  static List<IgpuPropertyModel> intel_nuc_6th_1 = [
    intel_desktop.copyWith(
      propertyItems: [intel_nuc_display_6th_1, intel_nuc_device_id_6th_1],
    )
  ];
  static List<IgpuPropertyModel> intel_nuc_6th_2 = [
    intel_desktop.copyWith(
      propertyItems: [intel_nuc_display_6th_2],
    )
  ];
  static List<IgpuPropertyModel> intel_nuc_6th_3 = [
    intel_desktop.copyWith(
      propertyItems: [intel_nuc_display_6th_3, intel_nuc_device_id_6th_3],
    )
  ];
  static List<IgpuPropertyModel> intel_nuc_6th_4 = [
    intel_desktop.copyWith(
      propertyItems: [intel_nuc_display_6th_4, intel_nuc_device_id_6th_4],
    )
  ];
  static List<IgpuPropertyModel> intel_nuc_6th_5 = [
    intel_desktop.copyWith(
      propertyItems: [intel_nuc_display_6th_5],
    )
  ];
  static List<IgpuPropertyModel> intel_nuc_6th_6 = [
    intel_desktop.copyWith(
      propertyItems: [intel_nuc_display_6th_6, intel_nuc_device_id_6th_6],
    )
  ];
  static List<IgpuPropertyModel> intel_nuc_6th_7 = [
    intel_desktop.copyWith(
      propertyItems: [intel_nuc_display_6th_7],
    )
  ];

  static DevicePropertyItem intel_nuc_display_7th_1 = DevicePropertyItem(
    key: 'AAPL,ig-platform-id',
    dataType: 'data',
    value: '00001E59',
    comment: 'HD 615核显',
  );

  static DevicePropertyItem intel_nuc_display_7th_2 =
      intel_nuc_display_7th_1.copyWith(
    value: '00001B59',
    comment: 'HD 630,HD P630核显',
  );
  static DevicePropertyItem intel_nuc_device_id_7th_2 =
      intel_laptop_device_id.copyWith(
    value: '16590000',
  );

  static DevicePropertyItem intel_nuc_display_7th_3 =
      intel_laptop_display_6th_1.copyWith(
    value: '02002659',
    comment: 'HD 640/650核显',
  );

  static DevicePropertyItem intel_nuc_display_7th_4 =
      intel_laptop_display_6th_1.copyWith(
    value: '00001659',
    comment: 'HD/UHD 620核显',
  );
  static DevicePropertyItem intel_nuc_device_id_7th_4 =
      intel_laptop_device_id.copyWith(
    value: '16590000',
  );

  static DevicePropertyItem intel_nuc_display_7th_5 = display_none_3th;

  static List<IgpuPropertyModel> intel_nuc_7th_1 = [
    intel_desktop.copyWith(
      propertyItems: [intel_nuc_display_7th_1],
    )
  ];
  static List<IgpuPropertyModel> intel_nuc_7th_2 = [
    intel_desktop.copyWith(
      propertyItems: [intel_nuc_display_7th_2, intel_nuc_device_id_7th_2],
    )
  ];
  static List<IgpuPropertyModel> intel_nuc_7th_3 = [
    intel_desktop.copyWith(
      propertyItems: [intel_nuc_display_7th_3],
    )
  ];
  static List<IgpuPropertyModel> intel_nuc_7th_4 = [
    intel_desktop.copyWith(
      propertyItems: [intel_nuc_display_7th_4, intel_nuc_device_id_7th_4],
    )
  ];
  static List<IgpuPropertyModel> intel_nuc_7th_5 = [
    intel_desktop.copyWith(
      propertyItems: [intel_nuc_display_7th_5],
    )
  ];

  static DevicePropertyItem intel_nuc_display_8th_1 = DevicePropertyItem(
    key: 'AAPL,ig-platform-id',
    dataType: 'data',
    value: '00009B3E',
    comment: 'UHD 620/630核显',
  );
  static DevicePropertyItem intel_nuc_device_id_8th_1 =
      intel_laptop_device_id.copyWith(
    value: '9B3E0000',
  );

  static DevicePropertyItem intel_nuc_display_8th_2 =
      intel_nuc_display_7th_1.copyWith(
    value: '0000A53E',
    comment: 'UHD 655核显',
  );
  static DevicePropertyItem intel_nuc_device_id_8th_2 =
      intel_laptop_device_id.copyWith(
    value: 'A53E0000',
  );

  static DevicePropertyItem intel_nuc_display_8th_3 =
      intel_laptop_display_6th_1.copyWith(
    value: '0400A53E',
    comment: 'Intel lris Plus 655核显',
  );
  static DevicePropertyItem intel_nuc_device_id_8th_3 =
      intel_laptop_device_id.copyWith(
    value: 'A53E0000',
  );

  static DevicePropertyItem intel_nuc_display_8th_4 = display_none_3th;

  static List<IgpuPropertyModel> intel_nuc_8th_1 = [
    intel_desktop.copyWith(
      propertyItems: [intel_nuc_display_8th_1, intel_nuc_device_id_8th_1],
    )
  ];
  static List<IgpuPropertyModel> intel_nuc_8th_2 = [
    intel_desktop.copyWith(
      propertyItems: [intel_nuc_display_8th_2, intel_nuc_device_id_8th_2],
    )
  ];
  static List<IgpuPropertyModel> intel_nuc_8th_3 = [
    intel_desktop.copyWith(
      propertyItems: [intel_nuc_display_8th_3, intel_nuc_device_id_8th_3],
    )
  ];
  static List<IgpuPropertyModel> intel_nuc_8th_4 = [
    intel_desktop.copyWith(
      propertyItems: [intel_nuc_display_8th_4],
    )
  ];

  static DevicePropertyItem intel_nuc_display_9th_1 = DevicePropertyItem(
    key: 'AAPL,ig-platform-id',
    dataType: 'data',
    value: '00009B3E',
    comment: 'UHD 620/630核显',
  );
  static DevicePropertyItem intel_nuc_device_id_9th_1 =
      intel_laptop_device_id.copyWith(
    value: '9B3E0000',
  );

  static DevicePropertyItem intel_nuc_display_9th_2 =
      intel_nuc_display_9th_1.copyWith(
    value: '0000A53E',
    comment: 'UHD 655核显',
  );
  static DevicePropertyItem intel_nuc_device_id_9th_2 =
      intel_laptop_device_id.copyWith(
    value: 'A53E0000',
  );

  static DevicePropertyItem intel_nuc_display_9th_3 = display_none_3th;

  static List<IgpuPropertyModel> intel_nuc_9th_1 = [
    intel_desktop.copyWith(
      propertyItems: [intel_nuc_display_9th_1, intel_nuc_device_id_9th_1],
    )
  ];
  static List<IgpuPropertyModel> intel_nuc_9th_2 = [
    intel_desktop.copyWith(
      propertyItems: [intel_nuc_display_9th_2, intel_nuc_device_id_9th_2],
    )
  ];
  static List<IgpuPropertyModel> intel_nuc_9th_3 = [
    intel_desktop.copyWith(
      propertyItems: [intel_nuc_display_9th_3],
    )
  ];

  static List<IgpuPropertyModel> intel_nuc_10th_1 = [
    intel_desktop.copyWith(
      propertyItems: [intel_nuc_display_9th_1, intel_nuc_device_id_9th_1],
    )
  ];

  static List<IgpuPropertyModel> intel_nuc_10th_2 = [
    intel_desktop.copyWith(
      propertyItems: [intel_nuc_display_9th_2, intel_nuc_device_id_9th_2],
    )
  ];

  static List<IgpuPropertyModel> intel_nuc_10th_3 = [
    intel_desktop.copyWith(
      propertyItems: [intel_nuc_display_9th_3],
    )
  ];

  static DevicePropertyItem intel_nuc_display_iceLake_1 = DevicePropertyItem(
    key: 'AAPL,ig-platform-id',
    dataType: 'data',
    value: '0000528A',
    comment: 'G4/G7系列核显',
  );
  static DevicePropertyItem intel_nuc_device_id_iceLake =
      intel_laptop_device_id.copyWith(
    value: '528A0000',
  );

  static DevicePropertyItem intel_nuc_display_iceLake_2 = display_none_3th;

  static List<IgpuPropertyModel> intel_nuc_iceLake_1 = [
    intel_desktop.copyWith(
      propertyItems: [intel_nuc_display_iceLake_1, intel_nuc_device_id_iceLake],
    )
  ];
  static List<IgpuPropertyModel> intel_nuc_iceLake_2 = [
    intel_desktop.copyWith(
      propertyItems: [intel_nuc_display_iceLake_2],
    )
  ];
}
