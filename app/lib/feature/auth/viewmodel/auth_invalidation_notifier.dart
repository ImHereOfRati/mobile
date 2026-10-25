import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_invalidation_notifier.g.dart';

@Riverpod(keepAlive: true)
class AuthInvalidationNotifier extends _$AuthInvalidationNotifier {
  @override
  int build() => 0;

  void requestInvalidation() {
    state++;
  }
}
