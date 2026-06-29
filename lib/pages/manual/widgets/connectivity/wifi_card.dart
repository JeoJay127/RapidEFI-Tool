import 'package:fluent_ui/fluent_ui.dart';
import 'package:rapidefi/pages/manual/widgets/connectivity/bluetooth_widget.dart';
import 'package:rapidefi/pages/manual/widgets/connectivity/brcm_wifi.dart';
import 'package:rapidefi/pages/shared/widgets/choice_list.dart';
import 'package:rapidefi/pages/shared/formatters/kext_label.dart';
import 'package:rapidefi/pages/shared/widgets/kext_choice_list.dart';
import 'package:rapidefi/pages/shared/widgets/oclp_link_button.dart';
import 'package:rapidefi/pages/shared/widgets/scrollable_choice_list_panel.dart';
import 'package:rapidefi/pages/shared/widgets/title_card.dart';
import 'package:rapidefi/pages/manual/widgets/connectivity/usb_wifi.dart';
import 'package:rapidefi/pages/manual/widgets/connectivity/wifi_type.dart';
import 'package:rapidefi/utils/config/catalogs/bluetooth_nvram/bluetooth_nvram_option.dart';
import 'package:rapidefi/utils/config/models/kernel/kernel_kext.dart';
import 'package:rapidefi/utils/config/models/nvram/nvram_add.dart';
import 'package:rapidefi/utils/config/presets/sections/config_kext_groups.dart';
import 'package:rapidefi/utils/config/presets/sections/config_kernel.dart';
import 'package:rapidefi/utils/config/config_model.dart';
import 'package:rapidefi/widgets/state_keep_container.dart';

class WifiCard extends StatefulWidget {
  final ValueChanged<List<KernelKext>> onChanged;
  final List<KernelKext>? choices;
  final ConfigModel configModel;
  final ValueChanged? onUSBWiFiChange;
  final ValueChanged? onBluetoothNramOptionChange;
  final NvramAdd? nvramAdd;
  final List<BluetoothNvramOption> bluetoothNvramOptions;
  final BluetoothNvramOption? selectedBluetoothNvramOption;
  const WifiCard({
    super.key,
    required this.configModel,
    required this.onChanged,
    this.choices,
    this.onUSBWiFiChange,
    this.onBluetoothNramOptionChange,
    this.nvramAdd,
    this.bluetoothNvramOptions = const [],
    this.selectedBluetoothNvramOption,
  });

  static final removableKexts = [
    ConfigKernel.AirportItlwm_Sequoia,
    ConfigKernel.AirportItlwm_Sonoma_14_4,
    ConfigKernel.AirportItlwm_Sonoma,
    ConfigKernel.AirportItlwm_Ventura,
    ConfigKernel.AirportItlwm_Monterey,
    ConfigKernel.AirportItlwm_BigSur,
    ConfigKernel.AirportItlwm_Catalina,
    ConfigKernel.AirportItlwm_Mojave,
    ConfigKernel.AirportItlwm_HighSierra,
    ConfigKernel.itlwm,
    ConfigKernel.AirportBrcmFixup,
    ConfigKernel.IO80211ElCap_AirPortBrcm4331,
    ConfigKernel.IO80211ElCap_AppleAirPortBrcm43224,
    ...BrcmWifi.removableKexts,
    ...ConfigKextGroups.atherosWifiModels.kexts,
    ...ConfigKextGroups.atherosWifiLegacySupport.kexts,
    ...ConfigKextGroups.atherosWifiModernSupport.kexts,
  ];

  @override
  State<WifiCard> createState() => _WifiCardState();
}

class _WifiCardState extends State<WifiCard> {
  int currentIndex = 0;
  List<Tab>? tabs;
  late List<KernelKext> choices = widget.choices ?? [];

  late final List<KernelKext> intelAirportOptions = [
    ConfigKernel.AirportItlwm_Sequoia,
    ConfigKernel.AirportItlwm_Sonoma_14_4,
    ConfigKernel.AirportItlwm_Sonoma,
    ConfigKernel.AirportItlwm_Ventura,
    ConfigKernel.AirportItlwm_Monterey,
    ConfigKernel.AirportItlwm_BigSur,
    ConfigKernel.AirportItlwm_Catalina,
    ConfigKernel.AirportItlwm_Mojave,
    ConfigKernel.AirportItlwm_HighSierra,
  ];
  late final KernelKext intelItlwmOption = ConfigKernel.itlwm;
  late final List<KernelKext> bcmOptions = [
    ConfigKernel.AirportBrcmFixup,
    ConfigKernel.IO80211ElCap_AirPortBrcm4331,
    ConfigKernel.IO80211ElCap_AppleAirPortBrcm43224,
  ];
  late final List<KernelKext> atherosOptions =
      ConfigKextGroups.atherosWifiModels.kexts;

  late List<KernelKext> intelSelectedChoices = List.of(
    _selectedKexts.where((kext) => intelAirportOptions.contains(kext)),
  );
  late List<KernelKext> bcmSelectedChoices = List.of(
    _selectedKexts.where((kext) => bcmOptions.contains(kext)),
  );
  late List<KernelKext> atherosSelectedChoices = List.of(
    _selectedKexts.where((kext) => atherosOptions.contains(kext)),
  );

  TabWidthBehavior tabWidthBehavior = TabWidthBehavior.sizeToContent;
  CloseButtonVisibilityMode closeButtonVisibilityMode =
      CloseButtonVisibilityMode.never;
  bool showScrollButtons = true;
  List<String> titles = [
    "英特尔(Intel)",
    "博通(Brcm)",
    "高通(Atheros)",
    "USB Wi-Fi",
    "蓝牙驱动"
  ];

  List<IconData> iconDatas = [
    FluentIcons.wifi,
    FluentIcons.wifi,
    FluentIcons.wifi,
    FluentIcons.usb,
    FluentIcons.bluetooth,
  ];

  List<KernelKext> get _selectedKexts => widget.configModel.kernel.kernelKexts;

  bool get itlwmSelected => _selectedKexts.contains(intelItlwmOption);

  void _handleIntelSelectionChange(List<KernelKext> selected) {
    setState(() {
      intelSelectedChoices = List.of(selected);
    });
    _updateOverallSelection();
  }

  void _handleBcmSelectionChange(List<KernelKext> selected) {
    setState(() {
      bcmSelectedChoices = List.of(selected);
    });
    _updateOverallSelection();
  }

  void _handleAtherosSelectionChange(List<KernelKext> selected) {
    setState(() {
      atherosSelectedChoices = List.of(selected);
    });
    _updateOverallSelection();
  }

  void _updateOverallSelection() {
    final overallSelected = <KernelKext>[
      ...intelSelectedChoices,
      ...bcmSelectedChoices,
      ...atherosSelectedChoices,
    ];
    widget.onChanged(overallSelected);
  }

  @override
  Widget build(BuildContext context) {
    final subviews = [
      StateKeepContainer(
        child: ScrollableChoiceListPanel(
          children: [
            ChoiceList(
              choices: [],
              header: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: const Text(
                  '方案一，使用AirportItlwm驱动,英特尔(Intel系列)Z大WiFi驱动,加入以下所有WiFi驱动(体积较大,谨慎选择).注意与方案二冲突，可能造成启动崩溃，不可同时使用!!!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              footer: WifiTypeWidget(
                choices: intelAirportOptions,
                selectedChoices: intelSelectedChoices,
                isMultipleSelection: true,
                expandTitle: '加入以下所有WiFi驱动(体积较大,谨慎选择)',
                onChanged: (List<KernelKext> value) {
                  _handleIntelSelectionChange.call(value);
                },
              ),
            ),
            KextChoiceList(
              choices: [intelItlwmOption],
              header: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: const Text(
                  '方案二,使用itlwm驱动(需配合HeliPort客户端),英特尔(Intel系列)Z大WiFi驱动.注意与方案一冲突，可能造成启动崩溃，不可同时使用!!!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              selectedChoices: itlwmSelected ? [intelItlwmOption] : [],
              isMultipleSelection: true,
              labelBuilder: kextDescriptionLabel,
              onChanged: (List<KernelKext> value) {
                List<KernelKext> selectedWifiIds = [];
                if (value.isNotEmpty) {
                  selectedWifiIds = [intelItlwmOption];
                  intelSelectedChoices.clear();
                }
                _handleIntelSelectionChange.call(selectedWifiIds);
              },
            ),
          ],
        ),
      ),
      StateKeepContainer(
        child: ScrollableChoiceListPanel(
          child: BrcmWifi(
            onChanged: (k) {
              _handleBcmSelectionChange(k);
            },
            selectedKexts: widget.configModel.kernel.kernelKexts,
          ),
        ),
      ),
      StateKeepContainer(
        child: ScrollableChoiceListPanel(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 10, left: 10),
              child: Text(
                "工具提供的驱动支持macOS Mojave 10.14 ~ macOS Sequoia 15系统！注意Monterey 12及以上系统还需要使用OCLP补丁后方可正常使用！！！",
                style: TextStyle(fontSize: 12),
              ),
            ),
            WifiTypeWidget(
              choices: atherosOptions,
              selectedChoices: atherosSelectedChoices,
              onChanged: _handleAtherosSelectionChange,
            )
          ],
        ),
      ),
      StateKeepContainer(
          child: USBWiFi(
        enableUSBWiFi: widget.configModel.enableUSBWiFi,
        onChanged: (value) {
          widget.onUSBWiFiChange?.call(value);
        },
      )),
      StateKeepContainer(
        child: BluetoothWidget(
          nvramAdd: widget.nvramAdd,
          nvramOptions: widget.bluetoothNvramOptions,
          selectedNvramOption: widget.selectedBluetoothNvramOption,
          onChanged: (value) {
            widget.onBluetoothNramOptionChange?.call(value);
          },
        ),
      ),
    ];

    tabs = List.generate(titles.length, (index) {
      return Tab(
        text: Text(titles[index]),
        icon: Icon(iconDatas[index]),
        body: subviews[index],
      );
    });

    return TitleCard(
      title: "WiFi蓝牙驱动:",
      subTitle: "(默认不配置WiFi驱动,请自行配置添加)",
      content: const OclpLinkButton(buttonText: '获取Intel专用修改版OCLP'),
      expander: SizedBox(
        height: 300,
        child: TabView(
          tabs: tabs!,
          currentIndex: currentIndex,
          onChanged: (index) => setState(() => currentIndex = index),
          tabWidthBehavior: tabWidthBehavior,
          closeButtonVisibility: closeButtonVisibilityMode,
          showScrollButtons: showScrollButtons,
        ),
      ),
    );
  }
}
