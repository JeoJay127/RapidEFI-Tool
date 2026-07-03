import 'package:rapidefi/utils/config/config_model.dart';
import 'package:rapidefi/utils/config/catalogs/efi_drivers/efi_driver_option.dart';
import 'package:rapidefi/utils/config/models/uefi/uefi_drivers_item.dart';
import 'package:path/path.dart' as path;

class EfiDriverAccessor {
  EfiDriverAccessor._();

  static List<EfiDriverOption> optionsByCategory(
    List<EfiDriverOption> catalog,
    String category,
  ) {
    return catalog.where((option) => option.category == category).toList();
  }

  static EfiDriverOption? selectedOption(
    ConfigModel model,
    List<EfiDriverOption> catalog,
    String category,
  ) {
    final options = optionsByCategory(catalog, category);
    for (final item in model.uefi.uefiDriversItems) {
      final itemPath = item.path.toLowerCase();
      for (final option in options) {
        if (_sameDriverPath(itemPath, option.path)) {
          return option;
        }
      }
    }
    return null;
  }

  static void updateDriverByCategory(
    ConfigModel model,
    List<EfiDriverOption> catalog,
    String category,
    String driverPath,
  ) {
    final categoryPaths = optionsByCategory(catalog, category)
        .map((option) => option.path.toLowerCase())
        .toSet();
    if (categoryPaths.isEmpty) return;

    var replaced = false;
    final items = model.uefi.uefiDriversItems.map((item) {
      final itemPath = item.path.toLowerCase();
      final isCategoryDriver = categoryPaths.any(
        (driverPath) => _sameDriverPath(itemPath, driverPath),
      );
      if (!isCategoryDriver) return item;
      replaced = true;
      return item.copyWith(path: driverPath, comment: '');
    }).toList();

    if (!replaced) {
      items.add(UefiDriversItem(
        path: driverPath,
        enabled: true,
      ));
    }

    model.uefi.uefiDriversItems = items;
  }

  static bool _sameDriverPath(String left, String right) {
    final normalizedLeft = left.toLowerCase();
    final normalizedRight = right.toLowerCase();

    return normalizedLeft == normalizedRight ||
        path.basename(normalizedLeft) == path.basename(normalizedRight);
  }
}
