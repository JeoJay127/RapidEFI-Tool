class BootArgModel {
  String arg;
  //备注
  String comment;

  BootArgModel({
    required this.arg,
    this.comment = '',
  });

  factory BootArgModel.fromJson(Map<String, dynamic> json) {
    return BootArgModel(
      arg: json['arg'],
      comment: json['comment'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'arg': arg,
      'comment': comment,
    };
  }
}
