import 'hardware_model_parsing.dart';

class AudioEndpoint {
  String? endpoint;

  AudioEndpoint({this.endpoint});

  factory AudioEndpoint.fromJson(Map<String, dynamic> json) {
    return AudioEndpoint(
      endpoint: HardwareModelParsing.string(json['endpoint']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'endpoint': endpoint,
    };
  }
}

class AudioDevice {
  String? busType;
  String? deviceID;
  String? subsystemID;
  String? acpiPath;
  String? pciPath;

  AudioDevice({
    this.busType,
    this.deviceID,
    this.subsystemID,
    this.acpiPath,
    this.pciPath,
  });

  factory AudioDevice.fromJson(Map<String, dynamic> json) {
    return AudioDevice(
      busType: HardwareModelParsing.string(json['Bus Type']),
      deviceID: HardwareModelParsing.string(json['Device ID']),
      subsystemID: HardwareModelParsing.string(json['Subsystem ID']),
      acpiPath: HardwareModelParsing.string(json['ACPI Path']),
      pciPath: HardwareModelParsing.string(json['PCI Path']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Bus Type': busType,
      'Device ID': deviceID,
      'Subsystem ID': subsystemID,
      'ACPI Path': acpiPath,
      'PCI Path': pciPath,
    };
  }
}

class AudioDevicesInfo {
  Map<String, AudioDevice>? audioDevices;

  AudioDevicesInfo({this.audioDevices});

  factory AudioDevicesInfo.fromJson(Object? json) => AudioDevicesInfo(
        audioDevices: HardwareModelParsing.objectMap(
          json,
          AudioDevice.fromJson,
        ),
      );
  Map<String, dynamic> toJson() =>
      audioDevices?.map((key, value) => MapEntry(key, value.toJson())) ?? {};
}
