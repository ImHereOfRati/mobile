import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'contact_view_model.dart';
import 'contact_view_model_interface.dart';

part 'contact_view_model_provider.g.dart';

@riverpod
ContactViewModelInterface contactViewModelInterface(Ref ref) {
  return ref.watch(contactViewModelProvider.notifier);
}
