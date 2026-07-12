import 'package:rapidefi/utils/config/config_model.dart';
import 'package:rapidefi/utils/hardware/ssdt/ssdt_selection.dart';

Set<String> customSsdtManagedAmlPaths(SsdtSelection selection) {
  return selection.items
      .map((item) => _amlPath(item.name))
      .where((path) => path.isNotEmpty)
      .toSet();
}

Set<String> removeCustomSsdtPrebuiltItems(
  ConfigModel model,
  SsdtSelection selection,
) {
  final managedPaths = customSsdtManagedAmlPaths(selection);
  if (managedPaths.isEmpty) return const <String>{};

  final removedPaths = <String>{};
  model.acpi.acpiAddItems.removeWhere((item) {
    final path = item.path.trim();
    final shouldRemove = managedPaths.contains(path.toLowerCase());
    if (shouldRemove) removedPaths.add(path);
    return shouldRemove;
  });

  return removedPaths;
}

String _amlPath(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '';
  final path = trimmed.toLowerCase().endsWith('.aml')
      ? trimmed
      : '$trimmed.aml';
  return path.toLowerCase();
}
