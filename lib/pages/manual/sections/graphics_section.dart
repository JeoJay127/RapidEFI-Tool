import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rapidefi/pages/manual/manual_config_controller.dart';
import 'package:rapidefi/pages/manual/widgets/graphics/dgpu.dart';
import 'package:rapidefi/pages/manual/widgets/graphics/igpu.dart';
import 'package:rapidefi/utils/config/config_model.dart';
import 'package:rapidefi/utils/config/models/enums/platform_type_enum.dart';
import 'package:rapidefi/utils/config/presets/sections/config_kernel.dart';
import 'package:rapidefi/utils/config/presets/sections/config_nvram.dart';

class IgpuSectionView extends StatelessWidget {
  const IgpuSectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<ManualConfigController, int>(
      selector: (_, controller) => controller.igpuRevision,
      builder: (context, _, __) {
        final controller = context.read<ManualConfigController>();
        final configService = controller.configService;
        final model = controller.model;
        final platformModel = controller.platformModel;

        if (!configService.showIGPU) {
          return const SizedBox.shrink();
        }

        return RepaintBoundary(
          child: IgpuWidget(
            platformCode: model.platformCode,
            igPlatformId: DevicePropertiesAccessor.getIntelIgPlatformId(model),
            preferExternalConnectors: model.platformType != PlatformType.laptop,
            igpuModels:
                platformModel.platforms[model.platformCode]?.igpuModes ?? [],
            edid: model.edid,
            connectorAllData:
                DevicePropertiesAccessor.getIntelConnectorAllData(model),
            selectedigpuModel: model.deviceProperties.addList,
            selectedDevicePropertyItems:
                controller.editor.selectedIGPUDeviceProperties(),
            onDevicePropertiesChanged: (deviceProperties) {
              controller.updateIgpu((editor) {
                editor.updateIGPUDeviceProperties(deviceProperties);
              });
            },
            onConnectorAllDataChanged: (connectorIndex, value) {
              controller.updateIgpu((editor) {
                editor.updateIntelConnectorAllData(connectorIndex, value);
              });
            },
            onChanged: (value) {
              controller.updateIgpu((editor) {
                editor.updateDeviceProperties(value);
              });
            },
            onEdidChanged: (value) {
              controller.updateIgpu((editor) {
                editor.setEdid(value);
              });
            },
          ),
        );
      },
    );
  }
}

class DgpuSectionView extends StatelessWidget {
  const DgpuSectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<ManualConfigController, int>(
      selector: (_, controller) =>
          controller.igpuRevision + controller.normalRevision,
      builder: (context, _, __) {
        final controller = context.read<ManualConfigController>();
        final model = controller.model;

        return RepaintBoundary(
          child: DgpuWidget(
            nootRXSelected: controller.configService.useNootRXKext,
            nvidiaSelected: BootArgsAccessor.contains(
              model,
              ConfigNvram.ngfxcompat_ngfxgl_nvda_drv_vrl.arg,
            ),
            onNvidiaChanged: (selected) {
              controller.update((editor) {
                final model = editor.configModel;
                if (selected) {
                  BootArgsAccessor.add(
                    model,
                    ConfigNvram.ngfxcompat_ngfxgl_nvda_drv_vrl.arg,
                  );
                } else {
                  BootArgsAccessor.remove(
                    model,
                    ConfigNvram.ngfxcompat_ngfxgl_nvda_drv_vrl.arg,
                  );
                }
              });
            },
            onNootRXChanged: (selected) {
              controller.update((editor) {
                editor.replaceKexts(
                  [ConfigKernel.NootRX],
                  selected ? [ConfigKernel.NootRX] : [],
                );
              });
            },
            onFakeGPUChanged: (dgpuPath, dgpuFakeID) {
              controller.update((editor) {
                editor.configFakeDGPU(dgpuPath, dgpuFakeID);
              });
            },
          ),
        );
      },
    );
  }
}
