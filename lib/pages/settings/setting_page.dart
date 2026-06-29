import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rapidefi/extension/bool_extension.dart';
import 'package:rapidefi/extension/color_extension.dart';
import 'package:rapidefi/pages/update_check.dart';
import 'package:rapidefi/pages/settings/out_efi_options.dart';
import 'package:rapidefi/pages/shared/widgets/choice_list.dart';
import 'package:rapidefi/pages/shared/widgets/settings_choice_card.dart';
import 'package:rapidefi/pages/shared/widgets/title_card.dart';
import 'package:rapidefi/utils/app_info.dart';
import 'package:rapidefi/utils/constant.dart';
import 'package:rapidefi/utils/theme.dart';
import 'package:rapidefi/pages/settings/theme_widget.dart';
import 'package:rapidefi/widgets/inkwell_widget.dart';
import 'package:sp_util/sp_util.dart';

const String snippet = '''
1.工具默认勾选【配置EFI时添加OpenCore引导主题】.RapidEFI工具配置输出EFI的时候,会添加一个OpenCore的引导主题.如果不需要主题,可以去掉勾选.

2.工具默认勾选【生成configModel文件到EFI文件夹】.RapidEFI工具配置输出EFI的时候,会在EFI输出文件夹生成一个名为configModel的文件.该文件可用于再次编辑调整当前EFI.具体可参考工具【加工EFI】部分.

3.如果勾选【EFI压缩成Zip文件】,工具输出EFI的同时会将当前EFI压缩成一个Zip文件。注意压缩Zip文件,会影响输出EFI整体进度。尤其性能比较差的硬件,影响更为明显.谨慎勾选此项.
''';

const String copyRights = '''
版权所有（C）2024 JeoJay

使用许可

允许个人或组织在以下条件下使用：

1.非商业用途：
本软件完全免费且开源,仅限于非商业用途,禁止售卖此软件。

2.注明出处：
任何形式的转载、引用或在第三方网站使用本软件的内容，必须明确注明出处，并包含以下信息：

本软件由JeoJay开发。版权所有（C）2024 JeoJay.   (Copyright © 2024 com.jeojay. All rights reserved.)

3.不得修改版权声明：
转载或使用本软件的任何内容时，不得修改或删除原始的版权声明和注明出处的信息。

免责声明：
本软件按“原样”提供，不提供任何明示或暗示的担保。版权所有人不对使用本软件产生的任何直接或间接损害承担责任。

 ''';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  late final appTheme = context.watch<AppTheme>();
  bool _checkingUpdate = false;
  List<OutEfiOptions> EFIOptionsList = [
    OutEfiOptions(
        key: Constant.configOpenCoreTheme,
        enabled: SpUtil.getBool(Constant.configOpenCoreTheme, defValue: true)
            .nullSafe,
        name: '配置EFI时添加OpenCore引导主题'),
    OutEfiOptions(
        key: Constant.outConfigModel,
        enabled:
            SpUtil.getBool(Constant.outConfigModel, defValue: true).nullSafe,
        name: '生成configModel文件到EFI文件夹'),
    OutEfiOptions(
        key: Constant.zipEFI,
        enabled: SpUtil.getBool(Constant.zipEFI, defValue: false).nullSafe,
        name: 'EFI压缩成Zip文件'),
  ];

  List<Widget> get children {
    return [
      const TitleCard(
        title: '版权申明',
        snippet: copyRights,
      ),
      SettingsChoiceCard<String>(
          title: '深色模式 :',
          choices: themeModeCHMap.values.toList(),
          selectedChoices: [themeModeCHMap[appTheme.themeMode.name] ?? ''],
          onChanged: (List<String> value) {
            String? selectedValue = value.firstOrNull;
            var key = themeModeCHMap.keys.firstWhere(
              (type) => themeModeCHMap[type] == selectedValue,
              orElse: () => appTheme.themeMode.name,
            );
            appTheme.mode = themeModeMap[key]!;
          }),
      TitleCard(
          title: '主题颜色 :',
          content: Row(
            children: [
              const SizedBox(
                width: 15,
              ),
              InkWellWidget(
                height: 30,
                width: 30,
                radius: 6,
                backgroundColor: appTheme.theme,
              ),
            ],
          ),
          expander: ThemeWidget(
              onTap: (primaryColor) {
                appTheme.primaryColor = primaryColor;
              },
              hasExpaner: false,
              primary: appTheme.theme,
              defaultPrimary: Colors.blue,
              defaultCustomPrimary:
                  Theme.of(context).colorScheme.primary.toMaterialColor())),
      TitleCard(
        title: '应用字体 :',
        content: Row(
          children: [
            const SizedBox(
              width: 15,
            ),
            Text(appFontFamilyMap[appTheme.appFontFamily]!),
          ],
        ),
        expander: ChoiceList(
          isMultipleSelection: false,
          allowToggle: false,
          onChanged: (value) {
            if (value.isNotEmpty) {
              final matchingKeys = appFontFamilyMap.entries
                  .where((entry) => entry.value == value.first)
                  .map((entry) => entry.key)
                  .toList();
              if (matchingKeys.isNotEmpty) {
                appTheme.appFontFamily = matchingKeys.first;
              }
            }
          },
          choices: appFontFamilyMap.values.toList(),
          selectedChoices: [appFontFamilyMap[appTheme.appFontFamily]!],
        ),
      ),
      SettingsChoiceCard<String>(
        title: 'EFI相关设置 :',
        choices: EFIOptionsList.map((e) => e.name).toList(),
        selectedChoices:
            EFIOptionsList.where((e) => e.enabled).map((e) => e.name).toList(),
        isMultipleSelection: true,
        allowToggle: false,
        onChanged: (List<String> value) {
          final valueSet = value.toSet();

          for (var op in EFIOptionsList) {
            op.enabled = valueSet.contains(op.name);
            SpUtil.putBool(op.key, op.enabled);
          }
        },
        snippet: snippet,
      ),
      TitleCard(
        title: '版本更新 :',
        content: _buildUpdateContent(),
      ),
    ];
  }

  Widget _buildUpdateContent() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FutureBuilder<String>(
          future: AppInfo.version,
          builder: (context, snapshot) {
            final version = snapshot.data ?? '--';
            return Text(
              '当前版本: $version',
              style: const TextStyle(fontSize: 13),
            );
          },
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 92,
          height: 30,
          child: ElevatedButton(
            onPressed: _checkingUpdate ? null : _checkUpdate,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              textStyle: const TextStyle(fontSize: 13),
            ),
            child: Text(_checkingUpdate ? '检测中...' : '检测更新'),
          ),
        ),
      ],
    );
  }

  Future<void> _checkUpdate() async {
    setState(() => _checkingUpdate = true);
    try {
      await UpdateDialog.checkLatestRelease(context, silent: false);
    } finally {
      if (mounted) setState(() => _checkingUpdate = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        itemCount: children.length,
        separatorBuilder: (BuildContext context, int index) {
          return const SizedBox(height: 10);
        },
        itemBuilder: (BuildContext context, int index) {
          return children[index];
        },
      ),
    );
  }
}
