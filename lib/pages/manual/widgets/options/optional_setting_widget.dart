import 'package:flutter/material.dart';
import 'package:rapidefi/pages/manual/manual_config_controller.dart';
import 'package:rapidefi/pages/manual/widgets/options/acpi_ssdt_widget.dart';
import 'package:rapidefi/pages/manual/widgets/options/booter_widget.dart';
import 'package:rapidefi/pages/manual/widgets/options/brand.dart';
import 'package:rapidefi/pages/manual/widgets/options/csr_setting.dart';
import 'package:rapidefi/pages/manual/widgets/options/kernel_widget.dart';
import 'package:rapidefi/pages/manual/widgets/options/rename_cpu_name.dart';
import 'package:rapidefi/pages/manual/widgets/options/special_motherboard.dart';
import 'package:rapidefi/pages/shared/widgets/tabbed_title_card.dart';
import 'package:rapidefi/pages/manual/widgets/options/uefi_widget.dart';
import 'package:rapidefi/pages/manual/widgets/options/uiscale.dart';
import 'package:rapidefi/utils/config/config_model.dart';
import 'package:rapidefi/utils/config/models/acpi/acpi_add_item.dart';
import 'package:rapidefi/utils/config/models/acpi/acpi_patch_item.dart';
import 'package:rapidefi/utils/config/models/booter/booter_quirks.dart';
import 'package:rapidefi/utils/config/models/kernel/kernel_emulate.dart';
import 'package:rapidefi/utils/config/models/kernel/kernel_quirks.dart';
import 'package:rapidefi/utils/config/models/uefi/uefi_output.dart';
import 'package:rapidefi/utils/config/models/uefi/uefi_quirks.dart';
import 'package:rapidefi/utils/config/presets/sections/config_booter.dart';
import 'package:rapidefi/widgets/state_keep_container.dart';

class OptionalSettingWidget extends StatefulWidget {
  const OptionalSettingWidget(
      {super.key,
      required this.model,
      required this.controller,
      this.onAcpiAddItemsChanged,
      this.onAcpiPatchItemsChanged,
      this.onBooterQuirksChanged,
      this.onKernelQuirksChanged,
      this.onKernelEmulateChanged,
      this.onHfsDriverPathChanged,
      this.onUefiOutputChanged,
      this.onUefiQuirksChanged,
      this.onApfsTrimTimeoutChanged});
  final ConfigModel model;
  final ManualConfigController controller;
  final ValueChanged<List<AcpiAddItem>>? onAcpiAddItemsChanged;
  final ValueChanged<List<AcpiPatchItem>>? onAcpiPatchItemsChanged;
  final ValueChanged<BooterQuirks>? onBooterQuirksChanged;
  final ValueChanged<KernelQuirks>? onKernelQuirksChanged;
  final ValueChanged<KernelEmulate>? onKernelEmulateChanged;
  final ValueChanged<String>? onHfsDriverPathChanged;
  final ValueChanged<UefiOutput>? onUefiOutputChanged;
  final ValueChanged<UefiQuirks>? onUefiQuirksChanged;
  final ValueChanged<int>? onApfsTrimTimeoutChanged;
  @override
  State<OptionalSettingWidget> createState() => _OptionalSettingWidgetState();
}

class _OptionalSettingWidgetState extends State<OptionalSettingWidget>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  late final List<String> tabName;

  @override
  void initState() {
    super.initState();
    tabName = [
      "品牌",
      "特殊主板",
      "SIP设置",
      "CPU改名",
      "OpenCore引导UI缩放设置",
      "ACPI配置",
      "Booter配置",
      "Kernel配置",
      "UEFI配置"
    ];
    _tabController = TabController(vsync: this, length: tabName.length);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Widget> _buildPages() {
    return [
      StateKeepContainer(
        child: BrandWidget(
          brand: widget.model.brand,
          onChanged: (brand) {
            widget.controller.updatePlatformBase((editor) {
              editor.updateBrand(brand);
            });
          },
        ),
      ),
      StateKeepContainer(
          child: SpecialMotherBoardWidget(
        specialMotherBoard: widget.model.specialMotherboard,
        onChanged: (specialMotherBoard) {
          widget.controller.update((editor) {
            editor.updateSpecialMotherBoard(specialMotherBoard);
          });
        },
      )),
      StateKeepContainer(
          child: CSRWidget(
        csrsetting: NvramSettingsAccessor.getCsrSetting(widget.model),
        onChanged: (csrsetting) {
          widget.controller.update((editor) {
            editor.updateCSRSetting(csrsetting);
          });
        },
      )),
      StateKeepContainer(
          child: RenameCPUNameWidget(
        processorType: widget.model.processorType,
        cpuName: NvramSettingsAccessor.getCustomCpuName(widget.model),
        onChanged: (processorType, cpuName) {
          widget.controller.update((editor) {
            editor.updateProcessorType(processorType, cpuName ?? "");
          });
        },
      )),
      StateKeepContainer(
        child: UIScaleWidget(
          uiScale: NvramSettingsAccessor.getUiScale(widget.model),
          onChanged: (uIScale) {
            widget.controller.update((editor) {
              editor.updateUIScale(uIScale);
            });
          },
        ),
      ),
      StateKeepContainer(
        child: AcpiSsdtWidget(
          acpi: widget.model.acpi,
          onChanged: (value) {
            if (value is List<AcpiAddItem>) {
              widget.onAcpiAddItemsChanged?.call(value);
            } else if (value is List<AcpiPatchItem>) {
              widget.onAcpiPatchItemsChanged?.call(value);
            }
          },
        ),
      ),
      StateKeepContainer(
          child: BooterWidget(
        booterQuirkTypes: ConfigBooter.booterQuirkTypes,
        booter: widget.model.booter,
        onChanged: (value) {
          widget.onBooterQuirksChanged?.call(value);
        },
      )),
      StateKeepContainer(
          child: KernelWidget(
        kernel: widget.model.kernel,
        onChanged: (value) {
          if (value is KernelQuirks) {
            widget.onKernelQuirksChanged?.call(value);
          } else if (value is KernelEmulate) {
            widget.onKernelEmulateChanged?.call(value);
          } else if (value is int) {
            widget.onApfsTrimTimeoutChanged?.call(value);
          }
        },
      )),
      StateKeepContainer(
        child: UEFIWidget(
          uefi: widget.model.uefi,
          efiDriverOptions: widget.controller.configService.efiDriverCatalog,
          onChanged: (value) {
            if (value is String) {
              widget.onHfsDriverPathChanged?.call(value);
            } else if (value is UefiOutput) {
              widget.onUefiOutputChanged?.call(value);
            } else if (value is UefiQuirks) {
              widget.onUefiQuirksChanged?.call(value);
            }
          },
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages();

    return TabbedTitleCard(
      title: "可选项设置:",
      subTitle: "(通常保持默认即可,除非有特殊需求时才需要修改)",
      initiallyExpanded: false,
      controller: _tabController,
      tabs: tabName.map((name) => Tab(text: name)).toList(),
      children: pages,
    );
  }
}
