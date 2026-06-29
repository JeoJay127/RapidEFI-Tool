import 'device_property_item.dart';

class IgpuPropertyModel {
  String pciPath;
  List<DevicePropertyItem> propertyItems;
  IgpuPropertyModel({
    required this.pciPath,
    required this.propertyItems,
  });
  IgpuPropertyModel copyWith(
      {String? pciPath, List<DevicePropertyItem>? propertyItems}) {
    final sourcePropertyItems = propertyItems ?? this.propertyItems;
    return IgpuPropertyModel(
      pciPath: pciPath ?? this.pciPath,
      propertyItems:
          sourcePropertyItems.map((item) => item.copyWith()).toList(),
    );
  }

  factory IgpuPropertyModel.fromJson(Map<String, dynamic> json) {
    var mm = IgpuPropertyModel(
      pciPath: json['pciPath'],
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
      'propertyItems': propertyItems.map((item) => item.toJson()).toList(),
    };
  }
}
