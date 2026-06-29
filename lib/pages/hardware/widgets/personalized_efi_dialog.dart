import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:rapidefi/pages/manual/widgets/platform/os_version.dart';
import 'package:rapidefi/pages/manual/widgets/platform/smbios.dart';
import 'package:rapidefi/pages/shared/widgets/choice_chip_tile.dart';
import 'package:rapidefi/pages/shared/widgets/title_card.dart';
import 'package:rapidefi/utils/config/models/enums/config_enums.dart';
import 'package:rapidefi/utils/config/models/platform_info/pi_generic.dart';
import 'package:rapidefi/utils/config/services/config_service.dart';
import 'package:rapidefi/utils/config/support/macos_version.dart';
import 'package:rapidefi/utils/config/support/smbios_compatibility.dart';
import 'package:rapidefi/utils/hardware/analysis/hardware_analysis.dart';
import 'package:rapidefi/utils/hardware/config/hardware_config_build_context.dart';
import 'package:rapidefi/utils/hardware/config/hardware_config_options.dart';
import 'package:rapidefi/utils/hardware/config/hardware_platform_resolver.dart';
import 'package:rapidefi/utils/hardware/model/allinfo.dart';
import 'package:rapidefi/utils/hardware/ssdt/ssdt_platform_catalog.dart';
import 'package:rapidefi/utils/hardware/ssdt/ssdt_selection.dart';
import 'package:rapidefi/utils/ssdttool/table.dart';
import 'package:rapidefi/widgets/button_segment_widget.dart';
import 'package:rapidefi/widgets/checkbox_title.dart';
import 'package:rapidefi/widgets/radio_option_group.dart';

class PersonalizedEfiResult {
  final String macOSVersion;
  final int? alcLayoutId;
  final bool? enableNpci;
  final PlatformInfoGeneric? platformInfoGeneric;
  final CpuType? cpuType;
  final PlatformType? platformType;
  final String? platformCode;
  final SsdtBuildMode ssdtBuildMode;
  final SsdtSelection? ssdtSelection;

  const PersonalizedEfiResult({
    required this.macOSVersion,
    this.alcLayoutId,
    this.enableNpci,
    this.platformInfoGeneric,
    this.cpuType,
    this.platformType,
    this.platformCode,
    this.ssdtBuildMode = SsdtBuildMode.custom,
    this.ssdtSelection,
  });
}

class PersonalizedEfiDialog extends StatefulWidget {
  final HardwareAllInfo? hardwareInfo;
  final Map<String, dynamic>? rawInfo;
  final int? initialAlcLayoutId;
  final bool? initialEnableNpci;
  final String? initialMacOSVersion;
  final PlatformInfoGeneric? initialPlatformInfoGeneric;
  final CpuType? initialCpuType;
  final PlatformType? initialPlatformType;
  final String? initialPlatformCode;
  final SsdtBuildMode initialSsdtBuildMode;
  final SsdtSelection? initialSsdtSelection;
  final bool customSsdtAvailable;
  final String? customSsdtUnavailableReason;

  const PersonalizedEfiDialog({
    super.key,
    required this.hardwareInfo,
    required this.rawInfo,
    this.initialAlcLayoutId,
    this.initialEnableNpci,
    this.initialMacOSVersion,
    this.initialPlatformInfoGeneric,
    this.initialCpuType,
    this.initialPlatformType,
    this.initialPlatformCode,
    this.initialSsdtBuildMode = SsdtBuildMode.custom,
    this.initialSsdtSelection,
    this.customSsdtAvailable = true,
    this.customSsdtUnavailableReason,
  });

  static Future<PersonalizedEfiResult?> show(
    BuildContext context,
    HardwareAllInfo? hardwareInfo,
    Map<String, dynamic>? rawInfo, {
    int? initialAlcLayoutId,
    bool? initialEnableNpci,
    String? initialMacOSVersion,
    PlatformInfoGeneric? initialPlatformInfoGeneric,
    CpuType? initialCpuType,
    PlatformType? initialPlatformType,
    String? initialPlatformCode,
    SsdtBuildMode initialSsdtBuildMode = SsdtBuildMode.custom,
    SsdtSelection? initialSsdtSelection,
    bool customSsdtAvailable = true,
    String? customSsdtUnavailableReason,
  }) {
    return showDialog<PersonalizedEfiResult>(
      context: context,
      builder: (_) => PersonalizedEfiDialog(
        hardwareInfo: hardwareInfo,
        rawInfo: rawInfo,
        initialAlcLayoutId: initialAlcLayoutId,
        initialEnableNpci: initialEnableNpci,
        initialMacOSVersion: initialMacOSVersion,
        initialPlatformInfoGeneric: initialPlatformInfoGeneric,
        initialCpuType: initialCpuType,
        initialPlatformType: initialPlatformType,
        initialPlatformCode: initialPlatformCode,
        initialSsdtBuildMode: initialSsdtBuildMode,
        initialSsdtSelection: initialSsdtSelection,
        customSsdtAvailable: customSsdtAvailable,
        customSsdtUnavailableReason: customSsdtUnavailableReason,
      ),
    );
  }

  @override
  State<PersonalizedEfiDialog> createState() => _PersonalizedEfiDialogState();
}

class _PersonalizedEfiDialogState extends State<PersonalizedEfiDialog> {
  static const _basicColor = Color(0xFFFF3B30);
  static const _recommendColor = Color(0xFF2196F3);
  static const _optionalColor = Color(0xFFFFB000);

  late String _selectedVersion;
  late CpuType _selectedCpuType;
  late PlatformType _selectedPlatformType;
  late String _selectedPlatformCode;
  late SsdtBuildMode _selectedSsdtBuildMode;

  int? _selectedAlcLayout;
  bool _enableNpci = false;
  PlatformInfoGeneric? _selectedPlatformInfoGeneric;
  String? _alcModel;
  List<int> _alcLayouts = [];
  Set<String> _selectedSsdtKeys = {};

  int get _selectedDarwinMajor =>
      MacOSVersions.darwinMajorFromLabel(_selectedVersion);

  List<PlatformInfoGeneric> get _platformInfoGenerics {
    return SsdtPlatformCatalog.platformModel(
          _selectedCpuType,
          _selectedPlatformType,
        )?.platforms[_selectedPlatformCode]?.smbiosOptions ??
        const <PlatformInfoGeneric>[];
  }

  List<PlatformInfoGeneric> get _supportedPlatformInfoGenerics {
    return SMBIOSCompatibility.supportedByDarwinMajor(
      _platformInfoGenerics,
      _selectedDarwinMajor,
    );
  }

  List<SsdtItem> get _ssdtItems => SsdtPlatformCatalog.items(
        _selectedCpuType,
        _selectedPlatformType,
        _selectedPlatformCode,
      );

  @override
  void initState() {
    super.initState();
    final versions = ConfigService().macOSVeriosnName;
    _selectedVersion = widget.initialMacOSVersion ??
        (versions.isNotEmpty ? versions.first : '');
    _selectedSsdtBuildMode = widget.customSsdtAvailable
        ? widget.initialSsdtBuildMode
        : SsdtBuildMode.original;
    _initPlatform();
    _parseHardware();
    _syncPlatformInfoGeneric(
      current: widget.initialPlatformInfoGeneric,
      preferCurrent: true,
    );
    _selectedSsdtKeys =
        widget.initialSsdtSelection?.items.map((item) => item.key).toSet() ??
            _defaultSelectedSsdtKeys();
  }

  void _initPlatform() {
    final detected = _detectPlatform();
    _selectedCpuType = widget.initialCpuType ?? detected.cpuType;
    _selectedPlatformType = widget.initialPlatformType ?? detected.platformType;
    _selectedPlatformCode = _validPlatformCode(
      widget.initialPlatformCode ?? detected.platformCode,
    );
  }

  HardwarePlatformSelection _detectPlatform() {
    final info = widget.hardwareInfo;
    if (info != null) {
      try {
        return const HardwarePlatformResolver().resolve(
          HardwareConfigBuildContext(
            hardwareInfo: info,
            rawInfo: widget.rawInfo,
            options: const HardwareConfigOptions(),
          ),
        );
      } catch (_) {}
    }

    return HardwarePlatformSelection(
      cpuType: CpuType.intel,
      platformType: PlatformType.desktop,
      platformCode: _defaultPlatformCode(
        CpuType.intel,
        PlatformType.desktop,
      ),
    );
  }

  int _defaultPlatformIndex(CpuType cpuType, PlatformType platformType) {
    if (cpuType == CpuType.intel) {
      return platformType == PlatformType.hedt ? 3 : 4;
    }
    if (cpuType == CpuType.amd) {
      return platformType == PlatformType.hedt ? 0 : 1;
    }
    return 0;
  }

  String _defaultPlatformCode(CpuType cpuType, PlatformType platformType) {
    final codes = SsdtPlatformCatalog.platformCodes(cpuType, platformType);
    if (codes.isEmpty) return '';
    final index = _defaultPlatformIndex(cpuType, platformType);
    return codes[index.clamp(0, codes.length - 1)];
  }

  String _validPlatformCode(String? platformCode) {
    final codes = SsdtPlatformCatalog.platformCodes(
      _selectedCpuType,
      _selectedPlatformType,
    );
    if (codes.isEmpty) return '';
    if (platformCode != null && codes.contains(platformCode)) {
      return platformCode;
    }
    return _defaultPlatformCode(_selectedCpuType, _selectedPlatformType);
  }

  void _parseHardware() {
    final data = widget.rawInfo;
    if (data == null) return;

    final audioLayout = audioLayoutAnalysis(
      data,
      preferredLayout: widget.initialAlcLayoutId,
    );
    if (audioLayout != null) {
      _alcModel = audioLayout.model;
      _alcLayouts = audioLayout.layouts;
      _selectedAlcLayout = audioLayout.selectedLayout;
    }

    _enableNpci = widget.initialEnableNpci ??
        (safeMap(data['BIOS'])['Above 4G Decoding'] != true);
  }

  void _changePlatform({
    CpuType? cpuType,
    PlatformType? platformType,
    String? platformCode,
  }) {
    setState(() {
      _selectedCpuType = cpuType ?? _selectedCpuType;
      _selectedPlatformType = platformType ?? _selectedPlatformType;
      _selectedPlatformCode = platformCode == null
          ? _defaultPlatformCode(_selectedCpuType, _selectedPlatformType)
          : _validPlatformCode(platformCode);
      _selectedSsdtKeys = _defaultSelectedSsdtKeys();
      _syncPlatformInfoGeneric();
    });
  }

  Set<String> _defaultSelectedSsdtKeys() {
    final keys = SsdtPlatformCatalog.defaultSelectedKeys(
      _selectedCpuType,
      _selectedPlatformType,
      _selectedPlatformCode,
    );
    if (_shouldDefaultSelectGpi0()) {
      for (final item in _ssdtItems) {
        if (item.name == ACPITable.ssdtGPI0.name) {
          keys.add(item.key);
          break;
        }
      }
    }
    return keys;
  }

  bool _shouldDefaultSelectGpi0() {
    if (_selectedPlatformType != PlatformType.laptop) return false;
    final info = widget.hardwareInfo;
    if (info == null) return false;
    return HardwareConfigBuildContext(
      hardwareInfo: info,
      rawInfo: widget.rawInfo,
      options: const HardwareConfigOptions(),
    ).hasI2cInputDevice;
  }

  void _syncPlatformInfoGeneric({
    PlatformInfoGeneric? current,
    bool preferCurrent = false,
  }) {
    final candidates = _platformInfoGenerics;
    _selectedPlatformInfoGeneric = SMBIOSCompatibility.recommendForDarwinMajor(
      candidates,
      _selectedDarwinMajor,
      current: preferCurrent ? current : _selectedPlatformInfoGeneric,
    );
  }

  SsdtSelection? _buildSsdtSelection() {
    if (!widget.customSsdtAvailable) return null;
    if (_selectedSsdtBuildMode == SsdtBuildMode.original) return null;
    final selectedItems = _ssdtItems
        .where((item) => item.isBasic || _selectedSsdtKeys.contains(item.key))
        .toList();
    return SsdtSelection(
      cpuType: _selectedCpuType,
      platformType: _selectedPlatformType,
      platformCode: _selectedPlatformCode,
      items: selectedItems,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final darkMode = colorScheme.brightness == Brightness.dark;
    final dialogBackground =
        darkMode ? const Color(0xFF202020) : colorScheme.surface;
    return AlertDialog(
      backgroundColor: dialogBackground,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: darkMode ? 0.75 : 0.22),
      elevation: darkMode ? 18 : 8,
      title: const Text('EFI设置', textAlign: TextAlign.center),
      titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      content: SizedBox(
        width: 900,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            const Text(
              '当前内容为可选项，输出 EFI 时会根据当前设置生成对应文件',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.64,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  Expanded(flex: 1, child: _buildSsdtPanel()),
                  Expanded(flex: 1, child: _buildLeftOptions()),
                ],
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(
            context,
            PersonalizedEfiResult(
              macOSVersion: _selectedVersion,
              alcLayoutId: _selectedAlcLayout,
              enableNpci: _enableNpci,
              platformInfoGeneric: _selectedPlatformInfoGeneric,
              cpuType: _selectedCpuType,
              platformType: _selectedPlatformType,
              platformCode: _selectedPlatformCode,
              ssdtBuildMode: _selectedSsdtBuildMode,
              ssdtSelection: _buildSsdtSelection(),
            ),
          ),
          child: const Text('确认'),
        ),
      ],
    );
  }

  Widget _buildLeftOptions() {
    final hasAlc = _alcModel != null;
    return SingleChildScrollView(
      child: Column(
        spacing: 8,
        mainAxisSize: MainAxisSize.min,
        children: [
          OSVersionWidget(
            verions: ConfigService().macOSVeriosnName,
            macOSVersion: _selectedVersion,
            onChanged: (info) => setState(() {
              _selectedVersion = info;
              _syncPlatformInfoGeneric(preferCurrent: true);
            }),
          ),
          if (_supportedPlatformInfoGenerics.isNotEmpty)
            SMBiosWidget(
              platformInfoGenerics: _supportedPlatformInfoGenerics,
              selectedChoice: _selectedPlatformInfoGeneric,
              onChanged: (platformInfoGeneric) => setState(() {
                final darwinMajor =
                    SMBIOSCompatibility.recommendDarwinMajorForSMBIOS(
                  platformInfoGeneric,
                  _selectedDarwinMajor,
                );
                _selectedVersion =
                    MacOSVersions.byDarwinMajor(darwinMajor).label;
                _selectedPlatformInfoGeneric = platformInfoGeneric;
              }),
            ),
          if (hasAlc)
            TitleCard(
              title: '声卡布局 ID:',
              subTitle: _alcModel,
              content: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: fluent.ComboBox<String>(
                  isExpanded: false,
                  value: _selectedAlcLayout?.toString() ??
                      _alcLayouts.first.toString(),
                  items: _alcLayouts
                      .map(
                        (e) => fluent.ComboBoxItem(
                          value: e.toString(),
                          child: Text(e.toString()),
                        ),
                      )
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedAlcLayout = int.tryParse(v!)),
                ),
              ),
              snippet: 'AppleALC 支持多个布局 ID，不同 ID 可能影响音频接口可用性。',
            ),
          TitleCard(
            title: 'Above 4G Decoding设置',
            content: ChoiceChipTile(
              label: '添加npci=0x2000启动参数',
              selected: _enableNpci,
              onChanged: (bo) => setState(() => _enableNpci = bo),
            ),
            snippet: '主板 BIOS 中 Above 4G Decoding 未开启时，建议勾选此参数；已开启时去掉该启动参数。',
          ),
        ],
      ),
    );
  }

  Widget _buildSsdtPanel() {
    final colorScheme = Theme.of(context).colorScheme;
    final darkMode = colorScheme.brightness == Brightness.dark;
    final panelColor = darkMode
        ? const Color(0xFF2A2A2A)
        : colorScheme.surfaceContainerHighest;
    final onPanelColor = colorScheme.onSurface;
    final panelBorderColor =
        darkMode ? const Color(0xFF6A6A6A) : Colors.grey.shade300;
    final customSsdt = _selectedSsdtBuildMode == SsdtBuildMode.custom;
    final customEnabled = customSsdt && widget.customSsdtAvailable;
    final platformCodes = SsdtPlatformCatalog.platformCodes(
      _selectedCpuType,
      _selectedPlatformType,
    );

    return Container(
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: panelBorderColor),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      child: DefaultTextStyle(
        style: TextStyle(color: onPanelColor, fontSize: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '当前 CPU 类型、平台类型和平台信息来自硬件信息识别结果；如果识别有误，可以在下方手动微调。',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 64,
                  child: Text(
                    'SSDT类型:',
                    style: TextStyle(
                      color: onPanelColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                RadioOptionGroup(
                  groupValue: _selectedSsdtBuildMode.name,
                  direction: RadioGroupDirection.row,
                  radioScale: 0.78,
                  options: const [
                    RadioOptionData(
                      value: 'custom',
                      label: '定制SSDT',
                    ),
                    RadioOptionData(
                      value: 'original',
                      label: '预制SSDT',
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    if (value == SsdtBuildMode.custom.name &&
                        !widget.customSsdtAvailable) {
                      return;
                    }
                    _selectedSsdtBuildMode = SsdtBuildMode.values.firstWhere(
                      (mode) => mode.name == value,
                      orElse: () => SsdtBuildMode.custom,
                    );
                  }),
                ),
              ],
            ),
            if (!widget.customSsdtAvailable &&
                widget.customSsdtUnavailableReason != null) ...[
              const SizedBox(height: 6),
              Text(
                widget.customSsdtUnavailableReason!,
                style: TextStyle(
                  color: colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 10),
            _buildSegmentRow<CpuType>(
              label: 'CPU类型:',
              values: const [CpuType.intel, CpuType.amd],
              selected: _selectedCpuType,
              textOf: (value) => value == CpuType.intel ? 'Intel' : 'AMD',
              onChanged: (value) => _changePlatform(cpuType: value),
            ),
            const SizedBox(height: 10),
            _buildSegmentRow<PlatformType>(
              label: '平台类型:',
              values: PlatformType.values,
              selected: _selectedPlatformType,
              textOf: _platformTypeLabel,
              onChanged: (value) => _changePlatform(platformType: value),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                SizedBox(
                  width: 64,
                  child: Text(
                    '平台信息:',
                    style: TextStyle(
                      color: onPanelColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: fluent.ComboBox<String>(
                    isExpanded: true,
                    value: _selectedPlatformCode.isEmpty
                        ? null
                        : _selectedPlatformCode,
                    items: platformCodes
                        .map(
                          (code) => fluent.ComboBoxItem(
                            value: code,
                            child: Text(
                              SsdtPlatformCatalog.platformLabel(
                                _selectedCpuType,
                                _selectedPlatformType,
                                code,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null || value == _selectedPlatformCode) {
                        return;
                      }
                      _changePlatform(platformCode: value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IgnorePointer(
                  ignoring: !customEnabled,
                  child: Opacity(
                    opacity: customEnabled ? 1 : 0.56,
                    child: CheckboxTile(
                      label: '勾选所有',
                      selected: _ssdtItems.isNotEmpty &&
                          _selectedSsdtKeys.length == _ssdtItems.length,
                      onChanged: _toggleAllSsdt,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: IgnorePointer(
                ignoring: !customEnabled,
                child: Opacity(
                  opacity: customEnabled ? 1 : 0.56,
                  child: _buildSsdtList(enabled: customEnabled),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentRow<T>({
    required String label,
    required List<T> values,
    required T selected,
    required String Function(T value) textOf,
    required ValueChanged<T> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final onPanelColor = colorScheme.onSurface;
    final labels = values.map(textOf).toList();
    final selectedLabel = textOf(selected);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: TextStyle(
              color: onPanelColor,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ButtonSegmentWidget(
            key: ValueKey('$label:$selectedLabel:${labels.join('|')}'),
            labels: labels,
            segmentHeight: 32,
            horizontalPadding: 16,
            initialSelection: {selectedLabel},
            onSelectionChanged: (selection) {
              if (selection.isEmpty) return;
              final selectedValue = selection.first;
              final index = labels.indexOf(selectedValue);
              if (index < 0) return;
              onChanged(values[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSsdtList({required bool enabled}) {
    final colorScheme = Theme.of(context).colorScheme;
    final mutedColor = colorScheme.onSurfaceVariant;
    final selectedColor = colorScheme.primary;
    return ListView.builder(
      itemCount: _ssdtItems.length,
      itemBuilder: (context, index) {
        final item = _ssdtItems[index];
        final selected = item.isBasic || _selectedSsdtKeys.contains(item.key);
        return InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: !enabled || item.isBasic ? null : () => _toggleSsdt(item),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  child: Text(
                    '*',
                    style: TextStyle(
                      color: _groupColor(item.group),
                      fontSize: 16,
                    ),
                  ),
                ),
                SizedBox(
                  width: 30,
                  child: Checkbox(
                    value: selected,
                    onChanged: !enabled || item.isBasic
                        ? null
                        : (_) => _toggleSsdt(item),
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(color: mutedColor),
                    activeColor: selectedColor,
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    item.name,
                    style:
                        TextStyle(color: colorScheme.onSurface, fontSize: 12),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Text(
                    item.remark,
                    style:
                        TextStyle(color: colorScheme.onSurface, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegend() {
    return Center(
      child: Wrap(
        spacing: 8,
        children: const [
          _LegendText(
            text: '* 核心(官方推荐)',
            color: _PersonalizedEfiDialogState._basicColor,
          ),
          _LegendText(
            text: '* 推荐(功能修复)',
            color: _PersonalizedEfiDialogState._recommendColor,
          ),
          _LegendText(
            text: '* 可选(功能完善)',
            color: _PersonalizedEfiDialogState._optionalColor,
          ),
        ],
      ),
    );
  }

  void _toggleSsdt(SsdtItem item) {
    setState(() {
      final next = Set<String>.from(_selectedSsdtKeys);
      if (next.contains(item.key)) {
        next.remove(item.key);
      } else {
        next.add(item.key);
      }
      _selectedSsdtKeys = next;
    });
  }

  void _toggleAllSsdt(bool? selected) {
    setState(() {
      if (selected == true) {
        _selectedSsdtKeys = _ssdtItems.map((item) => item.key).toSet();
      } else {
        _selectedSsdtKeys = _ssdtItems
            .where((item) => item.isBasic)
            .map((item) => item.key)
            .toSet();
      }
    });
  }

  Color _groupColor(SsdtItemGroup group) {
    switch (group) {
      case SsdtItemGroup.basic:
        return _basicColor;
      case SsdtItemGroup.recommend:
        return _recommendColor;
      case SsdtItemGroup.optional:
        return _optionalColor;
    }
  }

  String _platformTypeLabel(PlatformType platformType) {
    switch (platformType) {
      case PlatformType.desktop:
        return '台式机';
      case PlatformType.laptop:
        return '笔记本';
      case PlatformType.nuc:
        return '迷你主机';
      case PlatformType.hedt:
        return '服务器';
    }
  }
}

class _LegendText extends StatelessWidget {
  const _LegendText({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
    );
  }
}
