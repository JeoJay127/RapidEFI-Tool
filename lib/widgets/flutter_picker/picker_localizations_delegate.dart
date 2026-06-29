import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'picker_localizations.dart';

class PickerLocalizationsDelegate
    extends LocalizationsDelegate<PickerLocalizations> {
  const PickerLocalizationsDelegate();

  static const PickerLocalizationsDelegate delegate =
      PickerLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => PickerLocalizations.isSupported(locale);

  @override
  Future<PickerLocalizations> load(Locale locale) {
    return SynchronousFuture<PickerLocalizations>(PickerLocalizations(locale));
  }

  @override
  bool shouldReload(covariant PickerLocalizationsDelegate old) => false;
}
