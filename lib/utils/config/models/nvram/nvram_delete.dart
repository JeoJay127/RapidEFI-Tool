import 'nvram_delete_item.dart';

class NvramDelete {
  Map<String, List<NvramDeleteItem>?>? deleteList;
  NvramDelete({this.deleteList});
  factory NvramDelete.fromJson(Map<String, dynamic> json) {
    return NvramDelete(
      deleteList: (json['deleteList'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(
              key,
              (value as List<dynamic>?)
                  ?.map((item) => NvramDeleteItem.fromJson(item))
                  .toList())),
    );
  }
  NvramDelete copyWith({Map<String, List<NvramDeleteItem>?>? deleteList}) {
    return NvramDelete(
      deleteList: deleteList ?? this.deleteList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deleteList': deleteList?.map((key, value) =>
          MapEntry(key, value?.map((item) => item.toJson()).toList())),
    };
  }
}
