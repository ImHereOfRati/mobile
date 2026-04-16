import 'package:iamhere/friend/view_model/contact_view_model.dart';
import 'package:iamhere/friend/view_model/contact_view_model_interface.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'contact_view_model_provider.g.dart';

@riverpod
ContactViewModelInterface contactViewModelInterface(Ref ref) {
  return ref.watch(contactViewModelProvider.notifier);
}
