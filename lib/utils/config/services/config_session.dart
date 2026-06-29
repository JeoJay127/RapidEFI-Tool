import 'dart:convert';
import 'package:rapidefi/utils/config/config_model.dart';

enum ConfigModelMode { manual, auto, process, history }

enum ConfigScope {
  all,
  acpi,
  booter,
  booterQuirks,
  bootArgs,
  csr,
  deviceProperties,
  kernel,
  kernelEmulate,
  kernelForce,
  kernelKexts,
  optionalKexts,
  uefi,
  uefiDrivers,
  uefiQuirks,
}

class ConfigSession {
  ConfigSession._({
    required ConfigModel current,
    required Map<String, dynamic> baselineJson,
  })  : _current = current,
        _baselineJson = baselineJson;

  factory ConfigSession.from(ConfigModel model) {
    final current = model.detached();
    return ConfigSession._(
      current: current,
      baselineJson: _cloneJsonMap(current.toJson()),
    );
  }

  ConfigModel _current;
  Map<String, dynamic> _baselineJson;
  final List<ConfigPatchRecord> _patchRecords = [];

  ConfigModel get current => _current;

  ConfigModel get baseline =>
      ConfigModel.fromJson(_cloneJsonMap(_baselineJson));

  List<ConfigPatchRecord> get patchRecords => List.unmodifiable(_patchRecords);

  void replace(ConfigModel model) {
    _current = model.detached();
    _baselineJson = _cloneJsonMap(_current.toJson());
    _patchRecords.clear();
  }

  void checkpoint(String label, Set<ConfigScope> scopes) {
    _patchRecords.add(ConfigPatchRecord(
      label: label,
      scopes: scopes,
      createdAt: DateTime.now(),
    ));
  }

  void reset(ConfigScope scope) {
    if (scope == ConfigScope.all) {
      _current = baseline;
      _patchRecords.clear();
      return;
    }

    final source = baseline;
    switch (scope) {
      case ConfigScope.acpi:
        _current.acpi = source.acpi;
        break;
      case ConfigScope.booter:
        _current.booter = source.booter;
        break;
      case ConfigScope.booterQuirks:
        _current.booter.booterQuirks = source.booter.booterQuirks;
        break;
      case ConfigScope.bootArgs:
        BootArgsAccessor.setBootArgs(
          _current,
          BootArgsAccessor.getBootArgList(source),
        );
        break;
      case ConfigScope.csr:
        NvramSettingsAccessor.setCsrSetting(
          _current,
          NvramSettingsAccessor.getCsrSetting(source),
        );
        break;
      case ConfigScope.deviceProperties:
        _current.deviceProperties = source.deviceProperties;
        break;
      case ConfigScope.kernel:
        _current.kernel = source.kernel;
        break;
      case ConfigScope.kernelEmulate:
        _current.kernel.kernelEmulate = source.kernel.kernelEmulate;
        break;
      case ConfigScope.kernelForce:
        _current.kernel.kernelForceItems = source.kernel.kernelForceItems;
        break;
      case ConfigScope.kernelKexts:
        _current.kernel.kernelKexts = source.kernel.kernelKexts;
        break;
      case ConfigScope.optionalKexts:
        _current.kernel.kernelKexts = source.kernel.kernelKexts;
        break;
      case ConfigScope.uefi:
        _current.uefi = source.uefi;
        break;
      case ConfigScope.uefiDrivers:
        _current.uefi.uefiDriversItems = source.uefi.uefiDriversItems;
        break;
      case ConfigScope.uefiQuirks:
        _current.uefi.uefiQuirks = source.uefi.uefiQuirks;
        break;
      case ConfigScope.all:
        break;
    }

    _patchRecords.removeWhere((record) => record.scopes.contains(scope));
  }

  void resetMany(Iterable<ConfigScope> scopes) {
    for (final scope in scopes) {
      reset(scope);
    }
  }

  static Map<String, dynamic> _cloneJsonMap(Map<String, dynamic> source) {
    return jsonDecode(jsonEncode(source)) as Map<String, dynamic>;
  }
}

class ConfigPatchRecord {
  const ConfigPatchRecord({
    required this.label,
    required this.scopes,
    required this.createdAt,
  });

  final String label;
  final Set<ConfigScope> scopes;
  final DateTime createdAt;
}
