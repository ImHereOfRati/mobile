import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AuthInvalidationNotifier extends ChangeNotifier {
  void requestInvalidation() {
    notifyListeners();
  }
}
