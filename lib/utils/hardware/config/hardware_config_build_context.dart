import 'package:rapidefi/utils/hardware/analysis/hardware_analysis.dart';
import 'package:rapidefi/utils/hardware/config/hardware_config_options.dart';
import 'package:rapidefi/utils/hardware/model/allinfo.dart';
import 'package:rapidefi/utils/hardware/model/bluetooth.dart';
import 'package:rapidefi/utils/hardware/model/cpu.dart';
import 'package:rapidefi/utils/hardware/model/disk.dart';
import 'package:rapidefi/utils/hardware/model/gpu.dart';
import 'package:rapidefi/utils/hardware/model/network.dart';
import 'package:rapidefi/utils/hardware/model/sound.dart';
import 'package:rapidefi/utils/hardware/model/storage.dart';
import 'package:rapidefi/utils/hardware/model/usb.dart';

class HardwareConfigBuildContext {
  const HardwareConfigBuildContext({
    required this.hardwareInfo,
    required this.rawInfo,
    required this.options,
  });

  final HardwareAllInfo hardwareInfo;
  final Map<String, dynamic>? rawInfo;
  final HardwareConfigOptions options;

  Iterable<CPU> get cpus => hardwareInfo.cpu?.cpuList ?? const <CPU>[];

  Iterable<GraphicsCard> get graphicsCards =>
      hardwareInfo.graphicsInfoList?.graphicsCards?.values ??
      const <GraphicsCard>[];

  Iterable<NetworkAdapter> get networkAdapters =>
      hardwareInfo.networkInfoList?.networkAdapters?.values ??
      const <NetworkAdapter>[];

  Iterable<MapEntry<String, NetworkAdapter>> get networkAdapterEntries =>
      hardwareInfo.networkInfoList?.networkAdapters?.entries ??
      const <MapEntry<String, NetworkAdapter>>[];

  Iterable<MapEntry<String, BluetoothDevice>> get bluetoothDeviceEntries =>
      hardwareInfo.bluetoothDevicesList?.bluetoothDevices?.entries ??
      const <MapEntry<String, BluetoothDevice>>[];

  Iterable<AudioDevice> get audioDevices =>
      hardwareInfo.soundInfoList?.audioDevices?.values ?? const <AudioDevice>[];

  Iterable<StorageController> get storageControllers =>
      hardwareInfo.storageControllerList?.storageControllers?.values ??
      const <StorageController>[];

  Iterable<USBController> get usbControllers =>
      hardwareInfo.usbInfoList?.usbControllers?.values ??
      const <USBController>[];

  Iterable<MapEntry<String, StorageController>>
      get storageControllerDeviceEntries =>
          hardwareInfo.storageControllerList?.storageControllers?.entries ??
          const <MapEntry<String, StorageController>>[];

  Iterable<Disk> get disks => hardwareInfo.diskInfo?.disks ?? const <Disk>[];

  Map<String, dynamic> get rawInfoMap => rawInfo ?? const <String, dynamic>{};

  HardwareSupportSnapshot get supportSnapshot =>
      HardwareSupportResolver.resolveHardwareSupport(rawInfoMap);

  List<AudioEntry> get analyzedAudioEntries => audioEntries(rawInfoMap);

  AudioLayoutAnalysis? audioLayout({int? preferredLayout}) =>
      audioLayoutAnalysis(rawInfoMap, preferredLayout: preferredLayout);

  List<NetworkEntryAnalysis> get analyzedNetworkEntries =>
      networkEntries(rawInfoMap);

  List<StorageControllerEntryAnalysis> get analyzedStorageControllerEntries =>
      storageControllerEntries(rawInfoMap);

  List<SdCardEntryAnalysis> get analyzedSdCardEntries =>
      sdCardEntries(rawInfoMap);

  Set<String> get unsupportedStorageControllerIds =>
      unsupportedDiskControllerIds(rawInfoMap);

  CompatibilityNote? get cpuCompatibilityNote => supportSnapshot.cpu;

  CompatibilityNote? get gpuCompatibilityNote => supportSnapshot.gpu;

  CompatibilityNote? get networkCompatibilityNote =>
      supportSnapshot.network;

  CompatibilityNote? get audioCompatibilityNote =>
      supportSnapshot.audio;

  CompatibilityNote? get diskCompatibilityNote => supportSnapshot.disk;

  CompatibilityNote? get storageCompatibilityNote =>
      supportSnapshot.storage;

  CompatibilityNote? get sdCompatibilityNote => supportSnapshot.sd;

  Object? rawSection(String key) => rawInfo?[key];

  Object? rawAnySection(Iterable<String> keys) {
    final data = rawInfo;
    if (data == null) return null;

    for (final key in keys) {
      if (data.containsKey(key)) {
        return data[key];
      }
    }

    return null;
  }

  Object? get rawInputDevices => rawAnySection(
        const [
          'Input',
          'Touchpad',
          'TouchPad',
        ],
      );

  List<String> get inputDeviceTypes {
    return hardwareDevices(rawInputDevices)
        .map((entry) {
          final device = safeMap(entry.value);
          return [
            safeStr(device['Device Type']),
            safeStr(device['Bus Type']),
            safeStr(device['Type']),
            safeStr(device['Name']),
            entry.key,
          ].where((value) => value.trim().isNotEmpty).join(' ').toLowerCase();
        })
        .where((type) => type.isNotEmpty)
        .toList();
  }

  bool get hasI2cInputDevice =>
      inputDeviceTypes.any((type) => type.contains('i2c'));

  Object? get rawSdCardDevices => rawAnySection(
        const [
          'SDCard',
          'SD Card',
          'Card Reader',
        ],
      );
}
