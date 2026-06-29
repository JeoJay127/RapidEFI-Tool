import 'hardware_model_parsing.dart';

class Monitor {
  final double? size;
  final String? connectorType;
  final String? resolution;
  final String? currentRefreshRate;
  final String? hardwareID;
  final String? connectedGPU;
  final String? edid;

  const Monitor({
    this.size,
    this.connectorType,
    this.resolution,
    this.currentRefreshRate,
    this.hardwareID,
    this.connectedGPU,
    this.edid,
  });

  factory Monitor.fromJson(Map<String, dynamic> json) {
    return Monitor(
      size: HardwareModelParsing.doubleValue(json['Size']),
      connectorType: HardwareModelParsing.string(json['Connector Type']),
      resolution: HardwareModelParsing.string(json['Resolution']),
      currentRefreshRate: HardwareModelParsing.string(
        json['CurrentRefreshRate'],
      ),
      hardwareID: HardwareModelParsing.string(json['HardwareID']),
      connectedGPU: HardwareModelParsing.string(json['Connected GPU']),
      edid: HardwareModelParsing.string(json['EDID']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Size': size,
      'Connector Type': connectorType,
      'Resolution': resolution,
      'CurrentRefreshRate': currentRefreshRate,
      'HardwareID': hardwareID,
      'Connected GPU': connectedGPU,
      'EDID': edid,
    };
  }
}

class MonitorsInfo {
  final Map<String, Monitor> monitors;

  const MonitorsInfo({
    this.monitors = const {},
  });

  factory MonitorsInfo.fromJson(Object? json) {
    return MonitorsInfo(
      monitors: HardwareModelParsing.objectMap(json, Monitor.fromJson),
    );
  }

  Map<String, dynamic> toJson() {
    return monitors.map(
      (key, value) => MapEntry(key, value.toJson()),
    );
  }

  bool get isEmpty => monitors.isEmpty;

  bool get isNotEmpty => monitors.isNotEmpty;
}
