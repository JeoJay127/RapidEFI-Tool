import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:path/path.dart' as path;
import 'package:rapidefi/pages/shared/widgets/title_card.dart';
import 'package:rapidefi/utils/config/models/acpi/acpi.dart';
import 'package:rapidefi/utils/config/models/acpi/acpi_add_item.dart';
import 'package:rapidefi/utils/config/models/acpi/acpi_delete_item.dart';
import 'package:rapidefi/utils/config/models/acpi/acpi_patch_item.dart';
import 'package:rapidefi/utils/config/models/acpi/acpi_quirks.dart';
import 'package:rapidefi/utils/config/presets/platform_profiles/platform_configs.dart';
import 'package:rapidefi/utils/file_util.dart';
import 'package:rapidefi/utils/ssdttool/parser.dart';
import 'package:rapidefi/widgets/inkwell_widget.dart';

import '../utils/config/config_model.dart';
import '../utils/config/services/config_session.dart';
import 'package:rapidefi/pages/manual/manual_page.dart';

class ProcessPage extends StatefulWidget {
  const ProcessPage({super.key});

  @override
  State<ProcessPage> createState() => _ProcessPageState();
}

class _ProcessPageState extends State<ProcessPage> {
  ConfigModel? _configModel;
  String? _acpiSourceDirectory;

  bool _highlighted = false;
  bool _importing = false;
  int _configRevision = 0;

  bool get _hasConfigModel => _configModel != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: TitleCard(
              title: '加工EFI',
              content: _buildImportHeader(),
              expander: const Text(
                'RapidEFI工具配置的EFI,会在EFI输出文件夹生成一个名为configModel的文件,'
                '请将此文件导入工具如下指定区域,即可再次编辑当前EFI\n\n'
                '此功能仅支持RapidEFI V3.0.0以上版本,不支持以前旧版本',
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Flexible(
          child: Text(
            '(对RapidEFI配置的EFI再次加工)',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            _buildActionButton(
              text: '清除当前配置',
              enabled: _hasConfigModel && !_importing,
              onTap: _clearConfigModel,
            ),
            _buildActionButton(
              text: _importing ? '正在导入...' : '导入configModel文件',
              enabled: !_importing,
              onTap: _pickAndImportConfigModel,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String text,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final backgroundColor = enabled
        ? Colors.grey.withValues(alpha: 0.1)
        : Colors.grey.withValues(alpha: 0.05);

    return InkWellWidget(
      width: 140,
      height: 36,
      radius: 8,
      backgroundColor: backgroundColor,
      onTap: enabled ? onTap : null,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: enabled ? null : Theme.of(context).disabledColor,
        ),
      ),
    );
  }

  Widget _buildContent() {
    return DropTarget(
      onDragDone: _handleDragDone,
      onDragEntered: (_) => _setHighlighted(true),
      onDragExited: (_) => _setHighlighted(false),
      child: _buildDropTargetBody(),
    );
  }

  Widget _buildDropTargetBody() {
    final configModel = _configModel;

    if (configModel != null) {
      return Stack(
        children: [
          Positioned.fill(
            child: _buildManualPage(configModel),
          ),
          if (_highlighted || _importing)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        child: Text(
                          _importing
                              ? '正在导入configModel...'
                              : '松开鼠标重新导入configModel',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    return _buildEmptyDropArea();
  }

  Widget _buildManualPage(ConfigModel configModel) {
    return ManualPage(
      key: ValueKey<int>(_configRevision),
      configModel: configModel,
      configModelMode: ConfigModelMode.process,
      acpiSourceDirectory: _acpiSourceDirectory,
    );
  }

  Widget _buildEmptyDropArea() {
    return DropTarget(
      onDragDone: _handleDragDone,
      onDragEntered: (_) => _setHighlighted(true),
      onDragExited: (_) => _setHighlighted(false),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: _importing ? null : _pickAndImportConfigModel,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: _highlighted
                ? Colors.grey.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _highlighted
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          child: Center(
            child: Text(
              _importing ? '正在导入configModel...' : '拖拽configModel文件到这里\n或点击选择文件',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleDragDone(DropDoneDetails detail) async {
    if (detail.files.isEmpty) return;

    final filePath = detail.files.last.path;
    if (!_isConfigModelFile(filePath)) {
      _setHighlighted(false);
      return;
    }

    await _readConfigModelFromPath(filePath);
  }

  Future<void> _pickAndImportConfigModel() async {
    if (_importing) return;

    final selectPath = await FileUtils.openFile('');

    if (selectPath.isEmpty) return;

    await _readConfigModelFromPath(selectPath);
  }

  Future<void> _readConfigModelFromPath(String filePath) async {
    if (_importing) return;

    _setImporting(true);

    try {
      final configModel = await FileUtils.readFromFile(
        directoryPath: filePath,
      );
      _validateImportedConfigModel(configModel);
      _syncAcpiFromSourceConfig(configModel, filePath);
      final acpiSourceDirectory = _findAcpiSourceDirectory(filePath);

      if (!mounted) return;

      setState(() {
        _configModel = configModel;
        _acpiSourceDirectory = acpiSourceDirectory;
        _highlighted = false;
        _configRevision++;
      });
    } catch (error, stackTrace) {
      debugPrint('read configModel failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _configModel = null;
        _acpiSourceDirectory = null;
        _highlighted = false;
        _configRevision++;
      });
      showToast('导入的配置数据不符合要求，请重新导入 configModel 文件');
    } finally {
      _setImporting(false);
    }
  }

  bool _isConfigModelFile(String filePath) {
    if (filePath.isEmpty) return false;
    final file = File(filePath);
    if (!file.existsSync()) return false;
    return file.uri.pathSegments.last == 'configModel';
  }

  void _validateImportedConfigModel(ConfigModel configModel) {
    final platformModel = Configs().configsRepository.getPlatformModel(
          configModel.cpuType,
          configModel.platformType,
        );

    if (platformModel == null ||
        !platformModel.platforms.containsKey(configModel.platformCode) ||
        configModel.platformInfo.generic == null) {
      throw const FormatException('Invalid imported configModel data');
    }
  }

  String? _findAcpiSourceDirectory(String configModelPath) {
    final acpiDirectory = Directory(
      path.join(path.dirname(configModelPath), 'EFI', 'OC', 'ACPI'),
    );
    if (!acpiDirectory.existsSync()) return null;
    return acpiDirectory.path;
  }

  void _syncAcpiFromSourceConfig(
    ConfigModel configModel,
    String configModelPath,
  ) {
    final configPlist = File(
      path.join(path.dirname(configModelPath), 'EFI', 'OC', 'config.plist'),
    );
    if (!configPlist.existsSync()) return;

    final result = PlistParser().loadPlist(configPlist.path);
    if (result.status != PlistParseStatus.success) return;

    final acpi = _asMap(result.data?['ACPI']);
    if (acpi.isEmpty) return;

    configModel.acpi = Acpi(
      acpiAddItems: _parseList(acpi['Add'], AcpiAddItem.fromJson),
      acpiDeleteItems: _parseList(acpi['Delete'], AcpiDeleteItem.fromJson),
      acpiPatchItems: _parseList(acpi['Patch'], AcpiPatchItem.fromJson),
      acpiQuirks: acpi['Quirks'] is Map
          ? AcpiQuirks.fromJson(_asMap(acpi['Quirks']))
          : configModel.acpi.acpiQuirks,
    );
  }

  List<T> _parseList<T>(
    Object? raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => fromJson(_asMap(item)))
        .toList();
  }

  Map<String, dynamic> _asMap(Object? raw) {
    if (raw is! Map) return {};
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }

  void _clearConfigModel() {
    if (!_hasConfigModel || _importing) return;

    setState(() {
      _configModel = null;
      _acpiSourceDirectory = null;
      _highlighted = false;
      _configRevision++;
    });
  }

  void _setHighlighted(bool value) {
    if (_highlighted == value || _importing) return;

    setState(() {
      _highlighted = value;
    });
  }

  void _setImporting(bool value) {
    if (!mounted || _importing == value) return;

    setState(() {
      _importing = value;
    });
  }
}
