import 'package:path/path.dart' as path;
import 'package:rapidefi/utils/config/config_model.dart';
import 'package:rapidefi/utils/config/models/acpi/acpi_add_item.dart';
import 'package:rapidefi/utils/config/models/kernel/kernel_kext.dart';

typedef EfiBuildHook = Future<bool> Function(ConfigDraft draft);

class ConfigDraft {
  const ConfigDraft({
    required this.sourceModel,
    required this.patchModel,
    required this.persistedModel,
    required this.acpiItems,
    required this.kexts,
    required this.outputDirectory,
    required this.efiName,
    required this.saveHistory,
    this.acpiSourceDirectory,
    this.saveConfigModel,
    this.zipEfi,
    this.afterConfigWritten,
  });

  final ConfigModel sourceModel;
  final ConfigModel patchModel;
  final ConfigModel persistedModel;
  final List<AcpiAddItem> acpiItems;
  final List<KernelKext> kexts;
  final String outputDirectory;
  final String efiName;
  final bool saveHistory;
  final String? acpiSourceDirectory;
  final bool? saveConfigModel;
  final bool? zipEfi;
  final EfiBuildHook? afterConfigWritten;

  String get efiRootPath => path.join(outputDirectory, efiName);
  String get ocPath => path.join(efiRootPath, 'EFI', 'OC');
  String get configPlistPath => path.join(ocPath, 'config.plist');
}
