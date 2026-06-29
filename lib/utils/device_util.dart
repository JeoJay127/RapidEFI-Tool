import 'dart:io';
import 'package:flutter/foundation.dart';

class Device {
  static bool get isWeb => kIsWeb;
  static bool get isMacOS => !isWeb && Platform.isMacOS;
  static bool get isWindows => !isWeb && Platform.isWindows;
  static bool get isLinux => !isWeb && Platform.isLinux;
  static bool get isIOS => !isWeb && Platform.isIOS;
  static bool get isAndroid => !isWeb && Platform.isAndroid;
  static bool get isFuchsia => !isWeb && Platform.isFuchsia;
  static bool get isMobile => isIOS || isAndroid;
  static bool get isDesktop => !isWeb && (isMacOS || isLinux || isWindows);
}
