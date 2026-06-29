import 'package:flutter/foundation.dart';

class HistoryEventNotifier extends ChangeNotifier {
  HistoryEventNotifier._();

  static final HistoryEventNotifier instance = HistoryEventNotifier._();

  int _revision = 0;

  int get revision => _revision;

  void notifyHistoryChanged() {
    _revision++;
    notifyListeners();
  }
}
