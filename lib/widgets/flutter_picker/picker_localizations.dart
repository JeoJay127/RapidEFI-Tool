import 'package:flutter/widgets.dart';

/// 当前只内置英文和中文，并保留自定义语言注册入口。
class PickerLocalizations {
  static final PickerLocalizations _fallback =
      PickerLocalizations(const Locale('en'));

  final Locale locale;

  const PickerLocalizations(this.locale);

  String get cancelText => _value('cancelText');
  String get confirmText => _value('confirmText');

  /// 后续如果需要扩展更多文字，可以统一走这个入口。
  String text(String key) => _value(key);

  String _value(String key) {
    final languageCode = locale.languageCode.toLowerCase();
    return _localizedValues[languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }

  static PickerLocalizations of(BuildContext context) {
    return Localizations.of<PickerLocalizations>(
            context, PickerLocalizations) ??
        _fallback;
  }

  static bool isSupported(Locale locale) {
    return languages.contains(locale.languageCode.toLowerCase());
  }

  /// 当前内置支持的语言。
  /// 默认只支持英文和中文，后续可以继续追加。
  static List<String> get languages => List.unmodifiable(_localizedValues.keys);

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  static final Map<String, Map<String, String>> _localizedValues =
      <String, Map<String, String>>{
    'en': <String, String>{
      'cancelText': 'Cancel',
      'confirmText': 'Confirm',
    },
    'zh': <String, String>{
      'cancelText': '取消',
      'confirmText': '确定',
    },
  };

  /// 当前支持“取消”和“确定”，也允许追加其他文字。
  static void registerCustomLanguage(
    String languageCode, {
    String? cancelText,
    String? confirmText,
    Map<String, String>? extra,
  }) {
    final code = languageCode.trim().toLowerCase();
    if (code.isEmpty) return;

    final fallback = _localizedValues['en']!;
    _localizedValues[code] = <String, String>{
      'cancelText': cancelText ?? fallback['cancelText']!,
      'confirmText': confirmText ?? fallback['confirmText']!,
      if (extra != null) ...extra,
    };
  }
}
