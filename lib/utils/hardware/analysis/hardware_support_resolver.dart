import 'package:rapidefi/utils/hardware/analysis/hardware_analysis_models.dart';
import 'package:rapidefi/utils/hardware/analysis/hardware_compatibility.dart';

class HardwareSupportResolver {
  const HardwareSupportResolver._();

  static HardwareSupportSnapshot resolveHardwareSupport(
    Map<String, dynamic> rawInfo,
  ) {
    return HardwareSupportSnapshot(
      cpu: cpuCompatibility(rawInfo),
      gpu: gpuCompatibility(rawInfo),
      audio: audioCompatibility(rawInfo),
      network: networkCompatibility(rawInfo),
      storage: storageCompatibility(rawInfo),
      disk: diskCompatibility(rawInfo),
      sd: sdCompatibility(rawInfo),
    );
  }
}
