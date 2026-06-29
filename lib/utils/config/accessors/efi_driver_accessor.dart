import 'package:rapidefi/utils/config/config_model.dart';
import 'package:rapidefi/utils/config/catalogs/efi_drivers/efi_driver_option.dart';
import 'package:rapidefi/utils/config/models/uefi/uefi_drivers_item.dart';

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
        if (itemPath == option.path.toLowerCase() ||
            itemPath.contains(option.path.toLowerCase())) {
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
        (path) => itemPath == path || itemPath.contains(path),
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
}
