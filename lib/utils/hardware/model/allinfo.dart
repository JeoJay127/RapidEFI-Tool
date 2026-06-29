import 'bios.dart';
import 'bluetooth.dart';
import 'cpu.dart';
import 'disk.dart';
import 'gpu.dart';
import 'hardware_model_parsing.dart';
import 'memory.dart';
import 'motherboard.dart';
import 'monitor.dart';
import 'network.dart';
import 'system.dart';
import 'sound.dart';
import 'storage.dart';
import 'usb.dart';

class HardwareAllInfo {
  final CPUs? cpu;
  final MotherBoard? motherBoard;
  final MonitorsInfo? monitorsInfo;
  final MemoryModulesInfo? memoryInfo;
  final DisksInfo? diskInfo;
  final StorageControllersInfo? storageControllerList;
  final GraphicsCardInfo? graphicsInfoList;
  final NetworkAdaptersInfo? networkInfoList;
  final AudioDevicesInfo? soundInfoList;
  final BluetoothDevicesInfo? bluetoothDevicesList;
  final USBControllersInfo? usbInfoList;
  final System? system;
  final Bios? biosInfo;

  HardwareAllInfo({
    this.cpu,
    this.motherBoard,
    this.monitorsInfo,
    this.memoryInfo,
    this.diskInfo,
    this.storageControllerList,
    this.graphicsInfoList,
    this.networkInfoList,
    this.soundInfoList,
    this.bluetoothDevicesList,
    this.usbInfoList,
    this.system,
    this.biosInfo,
  });

  factory HardwareAllInfo.fromJson(Object? json) {
    final data = HardwareModelParsing.map(json);

    return HardwareAllInfo(
      cpu: data['CPU'] != null ? CPUs.fromJson(data['CPU']) : null,
      motherBoard: data['Motherboard'] != null
          ? MotherBoard.fromJson(HardwareModelParsing.map(data['Motherboard']))
          : null,
      monitorsInfo: data['Monitor'] != null
          ? MonitorsInfo.fromJson(data['Monitor'])
          : null,
      memoryInfo: data['Memory'] != null
          ? MemoryModulesInfo.fromJson(data['Memory'])
          : null,
      diskInfo: data['Disk'] != null ? DisksInfo.fromJson(data['Disk']) : null,
      storageControllerList: data['Storage Controllers'] != null
          ? StorageControllersInfo.fromJson(data['Storage Controllers'])
          : null,
      graphicsInfoList:
          data['GPU'] != null ? GraphicsCardInfo.fromJson(data['GPU']) : null,
      networkInfoList: data['Network'] != null
          ? NetworkAdaptersInfo.fromJson(data['Network'])
          : null,
      soundInfoList: data['Audio'] != null
          ? AudioDevicesInfo.fromJson(data['Audio'])
          : null,
      bluetoothDevicesList: data['Bluetooth'] != null
          ? BluetoothDevicesInfo.fromJson(data['Bluetooth'])
          : null,
      usbInfoList: data['USB Controllers'] != null
          ? USBControllersInfo.fromJson(data['USB Controllers'])
          : null,
      system: data['System'] != null
          ? System.fromJson(HardwareModelParsing.map(data['System']))
          : null,
      biosInfo: data['BIOS'] != null
          ? Bios.fromJson(HardwareModelParsing.map(data['BIOS']))
          : null,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'CPU': cpu?.toJson(),
      'Motherboard': motherBoard?.toJson(),
      'Monitor': monitorsInfo?.toJson(),
      'Memory': memoryInfo?.toJson(),
      'Disk': diskInfo?.toJson(),
      'Storage Controllers': storageControllerList?.toJson(),
      'GPU': graphicsInfoList?.toJson(),
      'Network': networkInfoList?.toJson(),
      'Audio': soundInfoList?.toJson(),
      'Bluetooth': bluetoothDevicesList?.toJson(),
      'USB Controllers': usbInfoList?.toJson(),
      'System': system?.toJson(),
      'BIOS': biosInfo?.toJson(),
    };
  }
}
