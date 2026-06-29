import 'package:rapidefi/utils/config/models/kernel/kernel_kext.dart';
import 'package:rapidefi/utils/config/models/kernel/kext_group.dart';

String kextDescriptionLabel(KernelKext kext) {
  final function = kext.function.trim();
  if (function.isNotEmpty) return function;

  final note = kext.note.where((item) => item.trim().isNotEmpty).join(' ');
  if (note.isNotEmpty) return note;

  return kextTitleLabel(kext);
}

String kextTitleLabel(KernelKext kext) {
  final bundlePath = kext.bundlePath.trim();
  return bundlePath.isNotEmpty ? bundlePath : '';
}

String kextBundleNameLabel(KernelKext kext) {
  final bundlePath = kext.bundlePath.trim();
  if (bundlePath.isEmpty) return '';

  return bundlePath.split('/').last;
}

String kextFunctionOrBundleLabel(KernelKext kext) {
  final function = kext.function.trim();
  return function.isNotEmpty ? function : kext.bundlePath;
}

String kextGroupTitleDescriptionLabel(KextGroup group) {
  final description = group.description.trim();
  if (description.isEmpty) return group.title;

  return '${group.title}($description)';
}
