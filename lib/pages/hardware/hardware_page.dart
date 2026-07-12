import 'dart:convert';
import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:rapidefi/utils/config/services/config_service.dart';
import 'package:rapidefi/utils/file_util.dart';
import 'package:rapidefi/utils/hardware/hardware_info.dart';
import 'package:rapidefi/utils/hardware/ssdt/ssdt_selection.dart';
import 'widgets/hardware_toolbar.dart';
import 'widgets/hardware_status_bar.dart';
import 'widgets/cpu_section.dart';
import 'widgets/motherboard_section.dart';
import 'widgets/monitor_section.dart';
import 'widgets/memory_section.dart';
import 'widgets/storage_section.dart';
import 'widgets/gpu_section.dart';
import 'widgets/network_section.dart';
import 'widgets/audio_section.dart';
import 'widgets/bluetooth_section.dart';
import 'widgets/io_section.dart';
import 'widgets/bios_section.dart';
import 'widgets/personalized_efi_dialog.dart';
import 'hardware_page_controller.dart';

class HardwarePage extends StatefulWidget {
  const HardwarePage({super.key});

  @override
  State<HardwarePage> createState() => _HardwarePageState();
}

class _HardwarePageState extends State<HardwarePage> {
  final HardwarePageController _controller = HardwarePageController();
  bool detailed = false;
  int? _selectedAlcLayout;
  PersonalizedEfiResult? _personalizedResult;
  Map<String, dynamic>? _lastRawInfo;
  bool _lastBodyLoading = false;
  bool _bodyDragging = false;
  int _lastContentRevision = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
    _controller.init();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    final rawInfo = _controller.rawInfo;
    final hardwareChanged = !identical(_lastRawInfo, rawInfo);
    final contentChanged = _lastContentRevision != _controller.contentRevision;
    final loadingChangedForEmptyBody =
        rawInfo == null && _lastBodyLoading != _controller.isLoading;
    if (!hardwareChanged && !contentChanged && !loadingChangedForEmptyBody) {
      return;
    }

    setState(() {
      _lastContentRevision = _controller.contentRevision;
      _lastBodyLoading = _controller.isLoading;
      if (hardwareChanged) {
        _lastRawInfo = rawInfo;
        if (rawInfo != null) {
          _resetHardwareDerivedOptions(updateRawInfoMarker: false);
        }
      }
    });
  }

  void _resetHardwareDerivedOptions({bool updateRawInfoMarker = true}) {
    if (updateRawInfoMarker) {
      _lastRawInfo = null;
    }
    _selectedAlcLayout = null;
    final current = _personalizedResult;
    if (current == null) return;
    _personalizedResult = PersonalizedEfiResult(
      macOSVersion: current.macOSVersion,
      alcLayoutId: null,
      enableNpci: null,
      platformInfoGeneric: null,
      cpuType: null,
      platformType: null,
      platformCode: null,
      ssdtBuildMode: current.ssdtBuildMode,
      ssdtSelection: null,
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _outputEfi() {
    final info = _controller.allInfo;
    if (info == null) return;
    final ssdtBuildMode = _controller.customSsdtAvailable
        ? (_personalizedResult?.ssdtBuildMode ?? SsdtBuildMode.custom)
        : SsdtBuildMode.original;
    final result = PersonalizedEfiResult(
      macOSVersion: _personalizedResult?.macOSVersion ??
          ConfigService().macOSVeriosnName.first,
      alcLayoutId: _selectedAlcLayout ?? _personalizedResult?.alcLayoutId,
      enableNpci: _personalizedResult?.enableNpci,
      platformInfoGeneric: _personalizedResult?.platformInfoGeneric,
      cpuType: _personalizedResult?.cpuType,
      platformType: _personalizedResult?.platformType,
      platformCode: _personalizedResult?.platformCode,
      ssdtBuildMode: ssdtBuildMode,
      ssdtSelection: _personalizedResult?.ssdtSelection,
    );
    _controller.buildAndExportEfi(
      info: info,
      macOSVersion: result.macOSVersion,
      alcLayoutId: result.alcLayoutId,
      enableNpci: result.enableNpci,
      platformInfoGeneric: result.platformInfoGeneric,
      cpuType: result.cpuType,
      platformType: result.platformType,
      platformCode: result.platformCode,
      ssdtBuildMode: result.ssdtBuildMode,
      ssdtSelection: result.ssdtSelection,
      context: context,
    );
  }

  Future<void> _openPersonalizedEfi() async {
    final result = await PersonalizedEfiDialog.show(
      context,
      _controller.allInfo,
      _controller.rawInfo,
      initialAlcLayoutId: _selectedAlcLayout,
      initialEnableNpci: _personalizedResult?.enableNpci,
      initialMacOSVersion: _personalizedResult?.macOSVersion,
      initialPlatformInfoGeneric: _personalizedResult?.platformInfoGeneric,
      initialCpuType: _personalizedResult?.cpuType,
      initialPlatformType: _personalizedResult?.platformType,
      initialPlatformCode: _personalizedResult?.platformCode,
      initialSsdtBuildMode: _controller.customSsdtAvailable
          ? (_personalizedResult?.ssdtBuildMode ?? SsdtBuildMode.custom)
          : SsdtBuildMode.original,
      initialSsdtSelection: _personalizedResult?.ssdtSelection,
      customSsdtAvailable: _controller.customSsdtAvailable,
      customSsdtUnavailableReason: _controller.customSsdtAvailable
          ? null
          : '已导入外部硬件报告，但未提供 ACPI 表目录，不能定制 SSDT。',
    );
    if (result != null) {
      setState(() {
        _personalizedResult = result;
        _selectedAlcLayout = result.alcLayoutId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(child: _buildContent()),
      _buildStatusBar(),
    ]);
  }

  Widget _buildContent() {
    return Column(children: [
      _buildToolbar(),
      Expanded(child: _buildHardwareBody()),
    ]);
  }

  Widget _buildToolbar() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return HardwareToolbar(
          isLoading: _controller.isLoading,
          detailed: detailed,
          onRefresh: () {
            setState(() => _resetHardwareDerivedOptions());
            _controller.refreshHardwareInfo(clearCache: true);
          },
          onImport: _importHardwareMaterials,
          onExport: _controller.exportHardwareInfo,
          onExportAcpi: _exportLocalAcpiTables,
          onOutputEfi: _outputEfi,
          onPersonalizedEfi: _openPersonalizedEfi,
          onDetailedChanged: (v) => setState(() => detailed = v),
          importedHardwarePath: _controller.importedHardwarePath,
          importedAcpiTablesPath: _controller.importedAcpiTablesPath,
          showHardwareActions: Platform.isWindows,
          showAcpiExportAction: Platform.isMacOS || Platform.isLinux,
        );
      },
    );
  }

  Future<void> _exportLocalAcpiTables() async {
    await _controller.exportLocalAcpiTables(
      onRequestSudoPassword:
          Platform.isLinux ? () => _requestSudoPasswordForAcpiExport() : null,
    );
  }

  Future<String?> _requestSudoPasswordForAcpiExport() async {
    final password = await _requestSudoPassword();
    if (password != null && password.trim().isNotEmpty) {
      showToast('正在验证管理员密码...');
    }
    return password;
  }

  Future<String?> _requestSudoPassword() async {
    String password = '';
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('需要管理员权限'),
          content: TextField(
            autofocus: true,
            obscureText: true,
            decoration: const InputDecoration(labelText: '请输入电脑开机密码'),
            onChanged: (value) => password = value,
            onSubmitted: (value) => Navigator.pop(context, value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, password),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _importHardwareMaterials() async {
    final result = await _HardwareImportDialog.show(
      context,
      initialDirectory: _controller.outputDirectory,
      initialHardwareReportPath: _controller.importedHardwarePath,
      initialAcpiTablesPath: _controller.importedAcpiTablesPath,
    );
    if (result == null || result.hardwareReportPath.isEmpty) return;
    setState(() => _resetHardwareDerivedOptions());
    await _controller.importHardwareInfo(
      filePath: result.hardwareReportPath,
      acpiTablesPath: result.acpiTablesPath,
    );
  }

  Widget _buildHardwareBody() {
    final data = _controller.rawInfo;
    return DropTarget(
      onDragDone: _handleHardwareBodyDragDone,
      onDragEntered: (_) {
        if (!_isHardwareDragTargetActive(context)) return;
        setState(() => _bodyDragging = true);
      },
      onDragExited: (_) {
        if (!_isHardwareDragTargetActive(context)) return;
        setState(() => _bodyDragging = false);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Scrollbar(
            controller: _scrollController,
            child: _buildHardwareBodyContent(data),
          ),
          if (_bodyDragging)
            Positioned.fill(
              left: 20,
              top: 10,
              right: 20,
              bottom: 10,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 0.8,
                    ),
                  ),
                  child: Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surface
                            .withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                        child: Text(
                          '释放后自动识别硬件报告和 ACPI 表',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHardwareBodyContent(Map<String, dynamic>? data) {
    if (data == null && _controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (data != null) {
      return _buildSections(data);
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          '拖入当前工具导出的硬件报告文件夹\n(自动识别sysInfo.txt和ACPI目录)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return HardwareStatusBar(
          status: _controller.loadStatus,
          isLoading: _controller.isLoading,
          progress: _controller.loadProgress,
          elapsedMs: _controller.elapsedMilliseconds,
          importedHardwarePath: _controller.importedHardwarePath,
          importedAcpiTablesPath: _controller.importedAcpiTablesPath,
          showProgressDetails: Platform.isWindows,
        );
      },
    );
  }

  bool _isHardwareDragTargetActive(BuildContext context) {
    return TickerMode.valuesOf(context).enabled;
  }

  Future<void> _handleHardwareBodyDragDone(DropDoneDetails details) async {
    if (!_isHardwareDragTargetActive(context)) {
      if (_bodyDragging) setState(() => _bodyDragging = false);
      return;
    }

    final droppedPath = details.files.isEmpty ? '' : details.files.first.path;
    final reportFile = _resolveDroppedReportFile(droppedPath);
    final directory = _resolveDroppedDirectory(droppedPath, reportFile);
    if (reportFile == null || directory == null) {
      setState(() => _bodyDragging = false);
      showToast('未识别到有效硬件报告文件');
      return;
    }

    setState(() {
      _bodyDragging = false;
      _resetHardwareDerivedOptions();
    });
    await _controller.importHardwareInfo(
      filePath: reportFile.path,
      acpiTablesPath: _findAcpiDirectory(directory),
    );
  }

  Widget _buildSections(Map<String, dynamic> data) {
    final itemCount = (detailed ? _detailedSections : _simpleSections).length;
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      itemCount: itemCount,
      itemBuilder: (_, index) => _buildSectionAt(data, index),
    );
  }

  Widget _buildSectionAt(Map<String, dynamic> data, int index) {
    final sections = detailed ? _detailedSections : _simpleSections;
    final section = sections[index];
    if (section == _HardwareSectionGap.gap) {
      return const SizedBox(height: 6);
    }
    switch (section) {
      case _HardwareSection.cpu:
        return CpuSection(data, detailed: detailed);
      case _HardwareSection.motherboard:
        return MotherboardSection(data);
      case _HardwareSection.monitor:
        return MonitorSection(data);
      case _HardwareSection.memory:
        return MemorySection(data);
      case _HardwareSection.storage:
        return StorageSection(data, detailed: detailed);
      case _HardwareSection.gpu:
        return GpuSection(data, detailed: detailed);
      case _HardwareSection.network:
        return NetworkSection(data, detailed: detailed);
      case _HardwareSection.audio:
        return AudioSection(
          data,
          detailed: detailed,
          selectedAlcLayout: _selectedAlcLayout,
          onAlcLayoutChanged: (v) => setState(() => _selectedAlcLayout = v),
        );
      case _HardwareSection.bluetooth:
        return BluetoothSection(data, detailed: detailed);
      case _HardwareSection.io:
        return IOSection(data, detailed: detailed);
      case _HardwareSection.bios:
        return BiosSection(data);
    }
    return const SizedBox.shrink();
  }
}

enum _HardwareSection {
  cpu,
  motherboard,
  monitor,
  memory,
  storage,
  gpu,
  network,
  audio,
  bluetooth,
  io,
  bios,
}

enum _HardwareSectionGap { gap }

const List<Object> _simpleSections = [
  _HardwareSection.cpu,
  _HardwareSectionGap.gap,
  _HardwareSection.motherboard,
  _HardwareSectionGap.gap,
  _HardwareSection.memory,
  _HardwareSectionGap.gap,
  _HardwareSection.storage,
  _HardwareSectionGap.gap,
  _HardwareSection.gpu,
  _HardwareSectionGap.gap,
  _HardwareSection.network,
  _HardwareSectionGap.gap,
  _HardwareSection.audio,
  _HardwareSectionGap.gap,
  _HardwareSection.bluetooth,
  _HardwareSectionGap.gap,
  _HardwareSection.io,
  _HardwareSectionGap.gap,
  _HardwareSection.bios,
];

const List<Object> _detailedSections = [
  _HardwareSection.cpu,
  _HardwareSectionGap.gap,
  _HardwareSection.motherboard,
  _HardwareSectionGap.gap,
  _HardwareSection.monitor,
  _HardwareSectionGap.gap,
  _HardwareSection.memory,
  _HardwareSectionGap.gap,
  _HardwareSection.storage,
  _HardwareSectionGap.gap,
  _HardwareSection.gpu,
  _HardwareSectionGap.gap,
  _HardwareSection.network,
  _HardwareSectionGap.gap,
  _HardwareSection.audio,
  _HardwareSectionGap.gap,
  _HardwareSection.bluetooth,
  _HardwareSectionGap.gap,
  _HardwareSection.io,
  _HardwareSectionGap.gap,
  _HardwareSection.bios,
];

File? _resolveDroppedReportFile(String droppedPath) {
  if (droppedPath.isEmpty) return null;
  final file = File(droppedPath);
  if (file.existsSync()) {
    return _isReportFile(file) ? file : null;
  }

  final directory = Directory(droppedPath);
  if (directory.existsSync()) {
    final reportPath = _findReportPath(directory);
    return reportPath.isEmpty ? null : File(reportPath);
  }
  return null;
}

Directory? _resolveDroppedDirectory(String droppedPath, File? reportFile) {
  if (droppedPath.isEmpty) return null;
  final directory = Directory(droppedPath);
  if (directory.existsSync()) return directory;
  return reportFile?.parent;
}

String _findReportPath(Directory directory) {
  final namedCandidates = <File>[];
  for (final name in const ['sysInfo.txt', 'sysInfo.json']) {
    namedCandidates.add(
      File('${directory.path}${Platform.pathSeparator}$name'),
    );
  }
  for (final file in namedCandidates) {
    if (_isReportFile(file)) return file.path;
  }

  for (final entity in directory.listSync(followLinks: false)) {
    if (entity is! File) continue;
    final name = entity.path.split(Platform.pathSeparator).last;
    final lowerName = name.toLowerCase();
    if (lowerName.contains('sysinfo') && _isReportFile(entity)) {
      return entity.path;
    }
  }

  for (final entity in directory.listSync(followLinks: false)) {
    if (entity is! File) continue;
    if (_isReportFile(entity)) return entity.path;
  }
  return '';
}

bool _isReportFile(File file) {
  if (!file.existsSync()) return false;
  final lowerPath = file.path.toLowerCase();
  if (!lowerPath.endsWith('.txt') && !lowerPath.endsWith('.json')) {
    return false;
  }

  try {
    return jsonDecode(HardwareInfo.readHardwareReportFileSync(file.path))
        is Map;
  } catch (_) {
    return false;
  }
}

String _findAcpiDirectory(Directory directory) {
  if (_hasAcpiTableFiles(directory)) return directory.path;

  for (final candidate in _preferredAcpiDirectoryCandidates(directory)) {
    if (_hasAcpiTableFiles(candidate)) return candidate.path;
  }
  for (final candidate in _acpiDirectoryCandidates(directory)) {
    if (_hasAcpiTableFiles(candidate)) return candidate.path;
  }
  return '';
}

List<Directory> _preferredAcpiDirectoryCandidates(Directory directory) {
  try {
    return directory.listSync(followLinks: false).whereType<Directory>().where(
      (entity) {
        final name = entity.path.split(Platform.pathSeparator).last;
        final lowerName = name.toLowerCase();
        return lowerName == 'acpi' || lowerName == 'acpis';
      },
    ).toList();
  } catch (_) {
    return const <Directory>[];
  }
}

List<Directory> _acpiDirectoryCandidates(Directory directory) {
  final candidates = <Directory>[];
  void collect(Directory current, int depth) {
    if (depth > 3) return;
    List<FileSystemEntity> entities;
    try {
      entities = current.listSync(followLinks: false);
    } catch (_) {
      return;
    }
    for (final entity in entities) {
      if (entity is! Directory) continue;
      final name = entity.path.split(Platform.pathSeparator).last;
      if (name.toLowerCase().contains('acpi')) {
        candidates.add(entity);
      }
      collect(entity, depth + 1);
    }
  }

  collect(directory, 0);
  return candidates;
}

bool _hasAcpiTableFiles(Directory directory) {
  try {
    return directory.listSync(followLinks: false).whereType<File>().any((file) {
      final lowerPath = file.path.toLowerCase();
      return lowerPath.endsWith('.aml') || lowerPath.endsWith('.dat');
    });
  } catch (_) {
    return false;
  }
}

class _HardwareImportResult {
  const _HardwareImportResult({
    required this.hardwareReportPath,
    required this.acpiTablesPath,
  });

  final String hardwareReportPath;
  final String acpiTablesPath;
}

class _HardwareImportDialog extends StatefulWidget {
  const _HardwareImportDialog({
    required this.initialDirectory,
    this.initialHardwareReportPath = '',
    this.initialAcpiTablesPath = '',
  });

  final String initialDirectory;
  final String initialHardwareReportPath;
  final String initialAcpiTablesPath;

  static Future<_HardwareImportResult?> show(
    BuildContext context, {
    required String initialDirectory,
    String initialHardwareReportPath = '',
    String initialAcpiTablesPath = '',
  }) {
    return showDialog<_HardwareImportResult>(
      context: context,
      builder: (_) => _HardwareImportDialog(
        initialDirectory: initialDirectory,
        initialHardwareReportPath: initialHardwareReportPath,
        initialAcpiTablesPath: initialAcpiTablesPath,
      ),
    );
  }

  @override
  State<_HardwareImportDialog> createState() => _HardwareImportDialogState();
}

class _HardwareImportDialogState extends State<_HardwareImportDialog> {
  String _hardwareReportPath = '';
  String _acpiTablesPath = '';

  @override
  void initState() {
    super.initState();
    _hardwareReportPath = widget.initialHardwareReportPath;
    _acpiTablesPath = widget.initialAcpiTablesPath;
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
      title: const Text('导入硬件资料', textAlign: TextAlign.center),
      titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPickRow(
              title: '硬件报告',
              pathText: _hardwareReportPath,
              buttonText: '选择文件',
              onTap: _pickHardwareReport,
            ),
            const SizedBox(height: 12),
            _buildPickRow(
              title: 'ACPI 表目录',
              pathText: _acpiTablesPath,
              buttonText: '选择目录',
              onTap: _pickAcpiTables,
              optional: true,
            ),
            const SizedBox(height: 8),
            Text(
              _acpiTablesPath.isEmpty
                  ? '未选择 ACPI 表目录时，导入外部硬件报告后只能使用预制/原始 SSDT。'
                  : '将使用所选 ACPI 表目录进行定制 SSDT。',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
        TextButton(
          onPressed: _hardwareReportPath.isEmpty
              ? null
              : () => Navigator.pop(
                    context,
                    _HardwareImportResult(
                      hardwareReportPath: _hardwareReportPath,
                      acpiTablesPath: _acpiTablesPath,
                    ),
                  ),
          child: const Text('导入'),
        ),
      ],
    );
  }

  Widget _buildPickRow({
    required String title,
    required String pathText,
    required String buttonText,
    required VoidCallback onTap,
    bool optional = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final darkMode = colorScheme.brightness == Brightness.dark;
    final borderColor =
        darkMode ? const Color(0xFF6A6A6A) : Colors.grey.shade300;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 88,
          child: Text(optional ? '$title(可选)' : title),
        ),
        Expanded(
          child: Container(
            height: 32,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, width: 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              pathText.isEmpty ? '未选择' : pathText,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 88,
          height: 32,
          child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(padding: EdgeInsets.zero),
            child: Text(buttonText),
          ),
        ),
      ],
    );
  }

  Future<void> _pickHardwareReport() async {
    final path = await FileUtils.openFile(
      widget.initialDirectory,
      allowedExtensions: const ['txt', 'json'],
    );
    if (path.isEmpty || !mounted) return;
    setState(() => _hardwareReportPath = path);
  }

  Future<void> _pickAcpiTables() async {
    final path = await FileUtils.openFileExplorer(widget.initialDirectory);
    if (path.isEmpty || !mounted) return;
    setState(() => _acpiTablesPath = path);
  }
}
