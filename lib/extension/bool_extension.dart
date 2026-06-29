extension BoolExtension on bool? {
  bool get nullSafe => this ?? false;
}
