import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rapidefi/application/app.dart';
import 'package:rapidefi/utils/app_info.dart';
import 'package:rapidefi/utils/hardware/hardware_info.dart';
import 'package:sp_util/sp_util.dart';
import 'package:window_manager/window_manager.dart';
import 'utils/constant.dart';
import 'utils/device_util.dart';
import 'utils/file_util.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _bootstrap();
  runApp(const RapidEFIApp());
}

Future<void> _bootstrap() async {
  await SpUtil.getInstance();
  await _cacheAppVersions();
  await _configurePlatformWindow();
  _configureAndroidSystemUi();
}

Future<void> _cacheAppVersions() async {
  final appVersion = await AppInfo.version;
  SpUtil.putString(Constant.appVersionKey, appVersion);

  final ocVersion = await FileUtils.getOCVerion();
  SpUtil.putString(Constant.openCoreVersionKey, ocVersion);
}

Future<void> _configurePlatformWindow() async {
  if (!Device.isDesktop) return;

  HardwareInfo.prefetch();
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    title: Constant.appName,
    minimumSize: Size(900, 600),
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: false,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}

void _configureAndroidSystemUi() {
  if (!Device.isAndroid) return;
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
}
