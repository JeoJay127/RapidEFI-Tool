import 'igpu_model.dart';

class DeviceProperties {
  List<IgpuPropertyModel>? addList;
  List<IgpuPropertyModel>? deleteList;
  DeviceProperties({this.addList, this.deleteList});

  DeviceProperties copyWith({
    List<IgpuPropertyModel>? addList,
    List<IgpuPropertyModel>? deleteList,
  }) {
    return DeviceProperties(
      addList: _copyIgpuPropertyModels(addList ?? this.addList),
      deleteList: _copyIgpuPropertyModels(deleteList ?? this.deleteList),
    );
  }

  List<IgpuPropertyModel> _copyIgpuPropertyModels(
    List<IgpuPropertyModel>? source,
  ) {
    return source?.map((item) => item.copyWith()).toList() ?? [];
  }

  factory DeviceProperties.fromJson(Map<String, dynamic> json) {
    var addList = DeviceProperties(
      addList: (json['addList'] as List<dynamic>?)
              ?.map((item) =>
                  IgpuPropertyModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const <IgpuPropertyModel>[],
      deleteList: (json['deleteList'] as List<dynamic>?)
              ?.map((item) =>
                  IgpuPropertyModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const <IgpuPropertyModel>[],
    );

    return addList;
  }
  Map<String, dynamic> toJson() {
    return {
      'addList': addList?.map((e) => e.toJson()).toList(),
      'deleteList': deleteList?.map((e) => e.toJson()).toList(),
    };
  }
}
