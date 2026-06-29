import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:rapidefi/pages/manual/manual_config_controller.dart';
import 'package:rapidefi/pages/manual/widgets/connectivity/nic_widget.dart';
import 'package:rapidefi/pages/manual/widgets/connectivity/sound_widget.dart';
import 'package:rapidefi/pages/manual/widgets/connectivity/usb_widget.dart';
import 'package:rapidefi/pages/manual/widgets/connectivity/wifi_card.dart';
import 'package:rapidefi/utils/config/config_model.dart';
import 'package:rapidefi/utils/config/models/kernel/kernel_kext.dart';
import 'package:rapidefi/utils/config/presets/sections/config_kernel.dart';

class ConnectivitySectionView extends StatelessWidget {
  const ConnectivitySectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<ManualConfigController, int>(
      selector: (_, controller) => controller.connectivityRevision,
      builder: (context, _, __) {
        final controller = context.read<ManualConfigController>();
        final model = controller.model;

        final selectedKexts = controller.configService.selectedKexts(model);

        final audioKext = [
          ConfigKernel.AppleALC,
          ConfigKernel.VoodooHDA,
        ].firstWhere(
          selectedKexts.contains,
          orElse: () => KernelKext(),
        );

        final usbDriverType = [
          ConfigKernel.USBInjectAll,
          ConfigKernel.USBToolBox,
        ].firstWhere(
          selectedKexts.contains,
          orElse: () => KernelKext(),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 10,
          children: [
            SoundWidget(
              soundDriverType: audioKext.bundlePath.isEmpty ? null : audioKext,
              alcidPickerSelection: model.alcidPickerSelection ??
                  ['', '', BootArgsAccessor.getAlcid(model) ?? 1],
              hpet: model.hpetPath,
              onChanged: (
                soundDriverType,
                hpet,
                alcidPickerSelection,
              ) {
                controller.updateConnectivity((editor) {
                  editor.updateSoundDriverType(
                    soundDriverType,
                    hpet,
                    alcidPickerSelection: alcidPickerSelection,
                  );
                });
              },
            ),
            NicWidget(
              selectedKexts: selectedKexts,
              onChanged: (value) {
                controller.updateConnectivity((editor) {
                  editor.replaceKexts(NicWidget.ethernetOptions, value);
                });
              },
            ),
            WifiCard(
              configModel: model,
              bluetoothNvramOptions: controller
                  .configService.bluetoothInternalControllerInfoOptions,
              selectedBluetoothNvramOption:
                  controller.editor.selectedBluetoothNvramOption(),
              nvramAdd: model.nvram.nvramAdd,
              onChanged: (wifiIds) {
                controller.updateConnectivity((editor) {
                  editor.replaceKexts(WifiCard.removableKexts, wifiIds);
                  editor.updateWifiTypes(wifiIds);
                });
              },
              onUSBWiFiChange: (value) {
                controller.updateConnectivity((editor) {
                  editor.updateUSBWiFiType(value);
                });
              },
              onBluetoothNramOptionChange: (value) {
                controller.updateConnectivity((editor) {
                  editor.updateBluetoothNvramOption(value);
                });
              },
            ),
            USBWidget(
              usbDriverType: usbDriverType,
              uefiQuirks: model.uefi.uefiQuirks,
              utbMapPath: controller.configService.utbMapPath,
              onUTBMapPathChanged: (utbMapPath) {
                controller.updateConnectivity((editor) {
                  editor.setUtbMapPath(utbMapPath);
                  if (utbMapPath != null &&
                      utbMapPath.isNotEmpty &&
                      usbDriverType.bundlePath ==
                          ConfigKernel.USBToolBox.bundlePath) {
                    editor.addKexts([ConfigKernel.UTBMap]);
                  } else {
                    editor.removeKexts([ConfigKernel.UTBMap]);
                  }
                });
              },
              onUEFIQuirksChanged: (releaseUsbOwnership) {
                controller.updateConnectivity((editor) {
                  editor.updateReleaseUsbOwnership(releaseUsbOwnership);
                });
              },
              onChanged: (usbKext) {
                controller.updateConnectivity((editor) {
                  editor.replaceKexts(
                    USBWidget.choices,
                    usbKext == null ? [] : [usbKext],
                  );
                  if (usbKext?.bundlePath ==
                          ConfigKernel.USBToolBox.bundlePath &&
                      controller.configService.utbMapPath != null &&
                      controller.configService.utbMapPath!.isNotEmpty) {
                    editor.addKexts([ConfigKernel.UTBMap]);
                  } else {
                    editor.removeKexts([ConfigKernel.UTBMap]);
                  }
                });
              },
            ),
          ],
        );
      },
    );
  }
}
