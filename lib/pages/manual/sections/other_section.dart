import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rapidefi/pages/manual/manual_config_controller.dart';
import 'package:rapidefi/pages/manual/widgets/options/boot_args.dart';
import 'package:rapidefi/pages/manual/widgets/options/optional_kext.dart';
import 'package:rapidefi/pages/manual/widgets/options/optional_setting_widget.dart';

class OtherSectionView extends StatelessWidget {
  const OtherSectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<ManualConfigController, int>(
      selector: (_, controller) =>
          controller.normalRevision + controller.platformBaseRevision,
      builder: (context, revision, __) {
        final controller = context.read<ManualConfigController>();
        final model = controller.model;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 10,
          children: [
            BootArgs(revision: revision),
            OptionalKextWidget(revision: revision),
            OptionalSettingWidget(
              model: model,
              controller: controller,
              onAcpiAddItemsChanged: (value) {
                controller.update((editor) => editor.updateExtraSSDTs(value));
              },
              onAcpiPatchItemsChanged: (value) {
                controller.update(
                  (editor) => editor.updateAcpiPatchItems(value),
                );
              },
              onBooterQuirksChanged: (value) {
                controller.update((editor) => editor.updateBooterQuirks(value));
              },
              onKernelQuirksChanged: (value) {
                controller.update((editor) => editor.updateKernelQuirks(value));
              },
              onKernelEmulateChanged: (value) {
                controller.update((editor) => editor.updateKernelEmulate(value));
              },
              onHfsDriverPathChanged: (value) {
                controller.update(
                  (editor) => editor.updateHfsDriverByPath(value),
                );
              },
              onUefiOutputChanged: (value) {
                controller.update((editor) => editor.updateUEFIOutput(value));
              },
              onUefiQuirksChanged: (value) {
                controller.update((editor) => editor.updateUEFIQuirks(value));
              },
              onApfsTrimTimeoutChanged: (value) {
                controller.update(
                  (editor) => editor.updateSetApfsTrimTimeoutValue(value),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
