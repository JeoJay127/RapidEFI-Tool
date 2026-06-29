import 'package:rapidefi/utils/config/build/config_draft.dart';

class EfiBuildOptions {
  const EfiBuildOptions({
    this.outDirectory,
    this.efiNameOverride,
    this.acpiSourceDirectory,
    this.saveHistory = true,
    this.saveConfigModel,
    this.zipEfi,
    this.afterConfigWritten,
  });

  final String? outDirectory;
  final String? efiNameOverride;
  final String? acpiSourceDirectory;
  final bool saveHistory;
  final bool? saveConfigModel;
  final bool? zipEfi;
  final EfiBuildHook? afterConfigWritten;
}
