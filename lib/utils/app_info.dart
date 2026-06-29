import 'package:package_info_plus/package_info_plus.dart';
import 'dart:async';

class AppInfo {
  static PackageInfo? _packageInfo;
  static Completer<PackageInfo>? _completer;

  static Future<PackageInfo> _getPackageInfo() {
    // 若已初始化，直接返回
    if (_packageInfo != null) return Future.value(_packageInfo);

    if (_completer != null) return _completer!.future;

    // 否则开始初始化
    _completer = Completer<PackageInfo>();
    PackageInfo.fromPlatform().then((info) {
      _packageInfo = info;
      _completer!.complete(info);
    }).catchError((e, stack) {
      _completer!.completeError(e, stack);
    });

    return _completer!.future;
  }

  static Future<String> get version async => (await _getPackageInfo()).version;
  static Future<String> get buildNumber async =>
      (await _getPackageInfo()).buildNumber;
  static Future<String> get appName async => (await _getPackageInfo()).appName;
  static Future<String> get packageName async =>
      (await _getPackageInfo()).packageName;
}
