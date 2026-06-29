import 'package:provider/provider.dart';
import 'package:rapidefi/utils/config/models/kernel/kext_group.dart';
import 'package:rapidefi/utils/config/presets/sections/config_kext_groups.dart';
import 'package:rapidefi/utils/config/presets/sections/config_kernel.dart';
import 'package:rapidefi/utils/config/services/config_option_provider.dart';
import 'package:flutter/material.dart';

import 'package:rapidefi/pages/shared/formatters/kext_label.dart';
import 'package:rapidefi/pages/shared/widgets/categorized_choice_list_card.dart';

class OptionalKextWidget extends StatefulWidget {
  const OptionalKextWidget({super.key, this.revision = 0});

  final int revision;

  @override
  State<OptionalKextWidget> createState() => _OptionalKextWidgetState();
}

class _OptionalKextWidgetState extends State<OptionalKextWidget>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  late final List<_KextCategory> _categories;

  @override
  void initState() {
    super.initState();
    _categories = [
      _KextCategory(
        name: '显卡',
        options: [
          KextGroup.single(ConfigKernel.WhateverGreen),
          KextGroup.single(ConfigKernel.FakePCIID),
          KextGroup.single(ConfigKernel.NootRX),
          KextGroup.single(ConfigKernel.RadeonBoost),
          KextGroup.single(ConfigKernel.RadeonSensor),
          KextGroup.single(ConfigKernel.SMCRadeonGPU),
        ],
      ),
      _KextCategory(
        name: '电源管理',
        options: [
          KextGroup.single(ConfigKernel.AMDRyzenCPUPowerManagement),
          KextGroup.single(ConfigKernel.NullCPUPowerManagement),
          ConfigKextGroups.appleIntelCpuPowerManagement,
        ],
      ),
      _KextCategory(
        name: '睡眠',
        options: [
          KextGroup.single(ConfigKernel.HibernationFixup),
          KextGroup.single(ConfigKernel.RTCMemoryFixup),
        ],
      ),
      _KextCategory(
        name: '磁盘',
        options: [
          KextGroup.single(ConfigKernel.NVMeFix),
          KextGroup.single(ConfigKernel.Innie),
          KextGroup.single(ConfigKernel.SATAUnsupported),
          KextGroup.single(ConfigKernel.CtlnaAHCIPort),
        ],
      ),
      _KextCategory(
        name: 'CPU相关',
        options: [
          ConfigKextGroups.cpuFriend,
          KextGroup.single(ConfigKernel.CpuTopologyRebuild),
          KextGroup.single(ConfigKernel.CpuTscSync),
          KextGroup.single(ConfigKernel.ForgedInvariant),
          KextGroup.single(ConfigKernel.VoodooTSCSync),
        ],
      ),
      _KextCategory(
        name: 'AMD平台',
        options: [
          KextGroup.single(ConfigKernel.SMCAMDProcessor),
          KextGroup.single(ConfigKernel.AmdTscSync),
          KextGroup.single(ConfigKernel.BFixup),
          KextGroup.single(ConfigKernel.IntelMKLFixup),
        ],
      ),
      _KextCategory(
        name: 'USB相关',
        options: [
          KextGroup.single(ConfigKernel.XHCIUnsupported),
          KextGroup.single(ConfigKernel.GenericUSBXHCI),
          KextGroup.single(ConfigKernel.XLNCUSBFix),
          KextGroup.single(ConfigKernel.DummyUSBEHCIPCI),
          KextGroup.single(ConfigKernel.DummyUSBXHCIPCI),
          KextGroup.single(ConfigKernel.HoRNDIS),
        ],
      ),
      _KextCategory(
        name: 'SD卡',
        options: [
          ConfigKextGroups.realtekCardReader,
          KextGroup.single(ConfigKernel.EmeraldSDHC),
        ],
      ),
      _KextCategory(
        name: '其他',
        options: [
          KextGroup.single(ConfigKernel.AMFIPass),
          KextGroup.single(ConfigKernel.BlueToolFixup),
          KextGroup.single(ConfigKernel.NullEthernet),
          KextGroup.single(ConfigKernel.FeatureUnlock),
          ConfigKextGroups.voodooPS2KeyboardAndMouse,
          KextGroup.single(ConfigKernel.NoTouchID),
        ],
      ),
    ];
    _tabController = TabController(vsync: this, length: _categories.length);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  ChoiceListCategory<KextGroup> _buildChoiceListCategory(
    _KextCategory category,
    ConfigOptionProvider provider,
  ) {
    return ChoiceListCategory<KextGroup>(
      name: category.name,
      tips: category.options
          .map((group) => group.bundleNames.join(', '))
          .toList(),
      choices: category.options,
      selectedChoices:
          KextGroup.selectedByAny(category.options, provider.selectedKexts),
      labelBuilder: _groupDescriptionLabel,
      onChanged: (List<KextGroup> value) {
        provider.updateKexts(
          KextGroup.expand(category.options),
          KextGroup.expand(value),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConfigOptionProvider>(builder: (context, provider, child) {
      return CategorizedChoiceListCard<KextGroup>(
        title: "可选Kexts驱动:",
        subTitle: "(可选驱动,非必要不添加)",
        controller: _tabController,
        categories: _categories
            .map((category) => _buildChoiceListCategory(category, provider))
            .toList(),
      );
    });
  }
}

class _KextCategory {
  const _KextCategory({
    required this.name,
    required this.options,
  });

  final String name;
  final List<KextGroup> options;
}

String _groupDescriptionLabel(KextGroup group) {
  if (group.kexts.length == 1) {
    return kextDescriptionLabel(group.kexts.first);
  }

  if (group.description.trim().isNotEmpty) {
    return kextGroupTitleDescriptionLabel(group);
  }

  return group.title;
}
