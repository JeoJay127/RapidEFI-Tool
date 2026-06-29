import 'hardware_model_parsing.dart';

/// 系统信息
class System {
  String? caption;
  String? csName;
  String? osArchitecture;
  String? buildNumber;
  String? serialNumber;

  System({
    this.caption,
    this.csName,
    this.osArchitecture,
    this.buildNumber,
    this.serialNumber,
  });

  factory System.fromJson(Map<String, dynamic> json) {
    return System(
      caption: HardwareModelParsing.string(json['Caption']),
      csName: HardwareModelParsing.string(json['CSName']),
      osArchitecture: HardwareModelParsing.string(json['OSArchitecture']),
      buildNumber: HardwareModelParsing.string(json['BuildNumber']),
      serialNumber: HardwareModelParsing.string(json['SerialNumber']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Caption': caption,
      'CSName': csName,
      'OSArchitecture': osArchitecture,
      'BuildNumber': buildNumber,
      'SerialNumber': serialNumber,
    };
  }
}
