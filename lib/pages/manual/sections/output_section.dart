import 'package:flutter/widgets.dart';
import 'package:rapidefi/pages/manual/manual_config_controller.dart';
import 'package:rapidefi/pages/manual/widgets/output/output_widget.dart';
import 'package:provider/provider.dart';
import 'package:rapidefi/utils/device_util.dart';
import 'package:rapidefi/utils/file_util.dart';

class OutputSectionView extends StatelessWidget {
  const OutputSectionView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<ManualConfigController>();
    final configService = controller.configService;

    return OutputWidget(
      directoryPath: configService.outputDirectory,
      onPickDirectory: Device.isWeb
          ? null
          : (outputDirectory) => FileUtils.openFileExplorer(outputDirectory),
      onChanged: (outputDirectory) {
        controller.editor.setOutputDirectory(outputDirectory);
      },
    );
  }
}
