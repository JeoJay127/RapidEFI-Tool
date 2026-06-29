import 'nvram_add_item.dart';

class NvramAdd {
  Map<String, List<NvramAddItem>?>? addList;
  NvramAdd({this.addList});
  NvramAdd copyWith({
    Map<String, List<NvramAddItem>?>? addList,
  }) {
    return NvramAdd(
      addList: addList ?? this.addList,
    );
  }

  factory NvramAdd.fromJson(Map<String, dynamic> json) {
    return NvramAdd(
        addList: (json['addList'] as Map<String, dynamic>?)?.map((key, value) =>
            MapEntry(
                key,
                (value as List<dynamic>?)
                    ?.map((item) => NvramAddItem.fromJson(item))
                    .toList())));
  }
  Map<String, dynamic> toJson() {
    return {
      'addList': addList?.map((key, value) =>
          MapEntry(key, value?.map((item) => item.toJson()).toList())),
    };
  }
}
