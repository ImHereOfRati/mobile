import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'show_permission_prep_provider.g.dart';

@Riverpod(keepAlive: true)
class ShowPermissionPrep extends _$ShowPermissionPrep {
  @override
  bool build() => false;

  void show() => state = true;

  void hide() => state = false;
}
