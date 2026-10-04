import 'device_property_item.dart';

class IgpuPropertyModel {
  String pciPath;
  List<DevicePropertyItem> propertyItems;

  /// 原始硬件设备 ID，仅用于推荐判断，不作为设备属性写入 plist。
  String sourceDeviceId;
  IgpuPropertyModel({
    required this.pciPath,
    required this.propertyItems,
    this.sourceDeviceId = '',
  });
  IgpuPropertyModel copyWith(
      {String? pciPath,
      List<DevicePropertyItem>? propertyItems,
      String? sourceDeviceId}) {
    final sourcePropertyItems = propertyItems ?? this.propertyItems;
    return IgpuPropertyModel(
      pciPath: pciPath ?? this.pciPath,
      sourceDeviceId: sourceDeviceId ?? this.sourceDeviceId,
      propertyItems:
          sourcePropertyItems.map((item) => item.copyWith()).toList(),
    );
  }

  factory IgpuPropertyModel.fromJson(Map<String, dynamic> json) {
    var mm = IgpuPropertyModel(
      pciPath: json['pciPath'],
      sourceDeviceId: json['sourceDeviceId'] as String? ?? '',
      propertyItems: (json['propertyItems'] as List<dynamic>)
          .map((item) =>
              DevicePropertyItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );

    return mm;
  }

  Map<String, dynamic> toJson() {
    return {
      'pciPath': pciPath,
      if (sourceDeviceId.isNotEmpty) 'sourceDeviceId': sourceDeviceId,
      'propertyItems': propertyItems.map((item) => item.toJson()).toList(),
    };
  }
}
