import 'package:rapidefi/pages/shared/formatters/kext_label.dart';
import 'package:rapidefi/utils/config/models/kernel/kernel_kext.dart';
import 'package:rapidefi/utils/config/models/uefi/uefi_quirks.dart';
import 'package:rapidefi/utils/config/presets/sections/config_kernel.dart';
import 'package:flutter/material.dart';
import 'package:rapidefi/utils/device_util.dart';
import 'package:rapidefi/widgets/choose_file.dart';

import 'package:rapidefi/pages/shared/widgets/choice_list.dart';
import 'package:rapidefi/pages/shared/widgets/kext_choice_list.dart';

class USBWidget extends StatefulWidget {
  final ValueChanged onChanged;
  final ValueChanged<bool>? onUEFIQuirksChanged;
  final ValueChanged? onUTBMapPathChanged;
  final KernelKext? usbDriverType;
  final UefiQuirks? uefiQuirks;
  final String? utbMapPath;
  static final choices = [ConfigKernel.USBInjectAll, ConfigKernel.USBToolBox];

  const USBWidget({
    super.key,
    required this.onChanged,
    this.onUEFIQuirksChanged,
    this.onUTBMapPathChanged,
    this.usbDriverType,
    this.uefiQuirks,
    this.utbMapPath,
  });

  @override
  State createState() => _USBWidgetState();
}

class _USBWidgetState extends State<USBWidget> {
  late KernelKext? usbDriverType = widget.usbDriverType;
  late UefiQuirks uefiQuirks = widget.uefiQuirks ?? UefiQuirks();
  late String? utbMapPath = widget.utbMapPath;

  Widget chooseUTBMap() {
    return ChooseFileWidget(
      buttonText: '选择UTBMap',
      onValid: (filePath) async {
        return filePath.endsWith('UTBMap.kext');
      },
      onChanged: (filePath) {
        utbMapPath = filePath;
        widget.onUTBMapPathChanged?.call(filePath);
      },
      directoryPath: '',
      hintText: utbMapPath ?? '选择使用USBToolBox工具定制好的UTBMap.kext驱动',
      allowedExtensions: Device.isMacOS ? null : const ['kext'],
      openFile: Device.isMacOS ? true : !Device.isWindows,
    );
  }

  @override
  Widget build(BuildContext context) {
    final choices = USBWidget.choices;
    final bool owner = uefiQuirks.releaseUsbOwnership;
    const releaseUsbOwnershipText =
        "启用'UEFI->Quirks->ReleaseUsbOwnership'怪癖,从固件驱动程序中释放USB控制器的所有权,虽然大部分的主板都有自动释放USB所有权的功能(可以在主板BIOS设置中将XHCI EHCI hand-off开启即可),但是有些固件做不到(比如某些H110,B150,B250,联想Q270等OEM主板)。具体表现是,可能在启动mac系统时因USB问题卡住,无法进入系统,或者开机USB键盘鼠标无法正常使用。此怪癖,除非必要，否则不建议使用";
    return KextChoiceListCard(
      title: "USB驱动:",
      cardSubTitle: "(默认使用USBInjectAll)",
      choices: choices,
      selectedChoices: usbDriverType?.bundlePath.isNotEmpty == true
          ? [usbDriverType!]
          : [],
      isMultipleSelection: false,
      allowToggle: true,
      labelBuilder: kextDescriptionLabel,
      header: ChoiceList(
        choices: [releaseUsbOwnershipText],
        selectedChoices: [owner ? releaseUsbOwnershipText : ''],
        onChanged: (value) {
          widget.onUEFIQuirksChanged?.call(value.isNotEmpty);
        },
      ),
      footer: usbDriverType?.bundlePath == ConfigKernel.USBToolBox.bundlePath
          ? chooseUTBMap()
          : const SizedBox.shrink(),
      onChanged: (List<KernelKext> value) {
        usbDriverType = value.firstOrNull;
        widget.onChanged.call(usbDriverType);
        setState(() {});
      },
    );
  }
}
