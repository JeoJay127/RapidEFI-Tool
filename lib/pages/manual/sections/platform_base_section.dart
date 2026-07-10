import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rapidefi/pages/manual/manual_config_controller.dart';
import 'package:rapidefi/pages/manual/sections/motherboard_section.dart';
import 'package:rapidefi/pages/manual/widgets/platform/amd.dart';
import 'package:rapidefi/pages/manual/widgets/platform/cpu.dart';
import 'package:rapidefi/pages/manual/widgets/platform/laptop.dart';
import 'package:rapidefi/pages/manual/widgets/platform/os_version.dart';
import 'package:rapidefi/pages/manual/widgets/platform/plantform.dart';
import 'package:rapidefi/pages/manual/widgets/platform/plantform_info.dart';
import 'package:rapidefi/pages/manual/widgets/platform/smbios.dart';
import 'package:rapidefi/utils/config/accessors/amd_settings_accessor.dart';
import 'package:rapidefi/utils/config/config_model.dart';
import 'package:rapidefi/utils/config/support/smbios_compatibility.dart';

/// 平台基础配置
class PlatformBaseSectionView extends StatelessWidget {
  const PlatformBaseSectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<ManualConfigController, int>(
      selector: (_, controller) => controller.platformBaseRevision,
      builder: (context, _, __) {
        final controller = context.read<ManualConfigController>();
        final configService = controller.configService;
        final model = controller.model;
        final platformModel = controller.platformModel;
        final smbiosCandidates =
            platformModel.platforms[model.platformCode]?.smbiosOptions ?? [];
        final supportedSmbios = SMBIOSCompatibility.supportedByDarwinMajor(
          smbiosCandidates,
          model.darwinMajorVersion,
        );
        final platformEntities = configService.getCachedPlatformInfos(
          cpuType: model.cpuType,
          platformType: model.platformType,
        );
        final selectedPlatformIndex = platformModel.indexOfCode(
          model.platformCode,
        );
        final safePlatformEntityIndex = selectedPlatformIndex.clamp(
          0,
          platformEntities.isEmpty ? 0 : platformEntities.length - 1,
        );
        final selectedPlatformEntity = platformEntities.isEmpty
            ? null
            : platformEntities[safePlatformEntityIndex];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 10,
          children: [
            CPUWidget(
              cpuType: model.cpuType,
              pentiumOrCeleron: model.pentiumOrCeleron,
              onPentiumChanged: (isPentiumOrCeleron) {
                controller.update((editor) {
                  editor.setPentiumOrCeleron(isPentiumOrCeleron);
                });
              },
              onChanged: (cpuType) {
                controller.selectCpuType(cpuType);
              },
            ),
            PlantformWidget(
              platformType: model.platformType,
              onChanged: (platformType) {
                controller.selectPlatformType(platformType);
              },
            ),
            if (selectedPlatformEntity != null)
              PlantFormInfoWidget(
                platformEntity: selectedPlatformEntity,
                infos:
                    platformModel.platforms.values.map((e) => e.label).toList(),
                selectedIndex: selectedPlatformIndex,
                showMobileComet: configService.showMobileComet,
                isMobileCometLake: model.isCometLakeU62,
                onCometLakeChange: (value) {
                  controller.update((editor) {
                    editor.setCometLakeU62(value);
                  });
                },
                onChanged: (info, index) {
                  controller.selectPlatformInfo(index);
                },
              ),
            if (configService.isAMD)
              AMDWidget(
                labels: configService.amdCores,
                showAMDSpecialMainboards: configService.isRyzen,
                usePrecastMMIO: model.usePrecastMMIO,
                useRyzenGPU: AmdSettingsAccessor.usesRyzenGpu(model),
                showRyzenGPU: configService.isRyzen,
                amdCore: AmdSettingsAccessor.getAmdCore(model),
                specialMotherboard: model.specialMotherboard,
                onAPUChanged: (useRyzenGPU) {
                  controller.update((editor) {
                    editor.setUsesRyzenGpu(useRyzenGPU);
                  });
                },
                onPrecastMMIOChanged: (usePrecastMMIO) {
                  controller.update((editor) {
                    editor.updateRyzenMMIO(usePrecastMMIO);
                  });
                },
                onChanged: (amdmlb, amdCore) {
                  controller.update((editor) {
                    editor.updateAMDOptions(amdmlb, amdCore);
                  });
                },
              ),
            OSVersionWidget(
              verions: configService.macOSVeriosnName,
              macOSVersion: model.macOSVersion,
              onChanged: (info) {
                controller.updatePlatformBase((editor) {
                  editor.setMacOSVersion(info);
                  final recommended =
                      SMBIOSCompatibility.recommendForDarwinMajor(
                    smbiosCandidates,
                    editor.configModel.darwinMajorVersion,
                    current: editor.configModel.platformInfo.generic,
                  );
                  if (recommended != null) {
                    editor.setPlatformInfoGeneric(recommended);
                  }
                });
              },
            ),
            SMBiosWidget(
                platformInfoGenerics: supportedSmbios,
                selectedChoice: model.platformInfo.generic,
                onChanged: (platformInfoGeneric) {
                  controller.updatePlatformBase((editor) {
                    final darwinMajor =
                        SMBIOSCompatibility.recommendDarwinMajorForSMBIOS(
                      platformInfoGeneric,
                      editor.configModel.darwinMajorVersion,
                    );
                    editor.setDarwinMajorVersion(darwinMajor);
                    editor.setPlatformInfoGeneric(
                      platformInfoGeneric,
                      syncCpuFriendRecommendation: true,
                    );
                  });
                }),
            if (configService.showLaptopKext)
              LaptopWidget(
                selectedKexts: configService.selectedKexts(model),
                onChanged: (selectedKexts) {
                  controller.updatePlatformBase((editor) {
                    editor.replaceKexts(
                      LaptopWidget.removableKexts,
                      selectedKexts,
                    );
                  });
                },
              ),
            // ── 主板型号配置（独立区域，最后应用，不被平台预设覆盖）─
            const MotherboardSectionView(),
          ],
        );
      },
    );
  }
}
