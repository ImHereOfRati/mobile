import 'package:iamhere/feature/geofence/model/recipient.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'recipient_select_state.dart';

part 'recipient_select_view_model.g.dart';

@Riverpod(keepAlive: false)
class RecipientSelectViewModel extends _$RecipientSelectViewModel {
  @override
  RecipientSelectState build(List<String>? initialSelectedKeys) {
    return RecipientSelectState(selectedKeys: initialSelectedKeys?.toSet() ?? {});
  }

  void toggleSelection(String selectionKey) {
    final current = Set<String>.from(state.selectedKeys);
    current.contains(selectionKey) ? current.remove(selectionKey) : current.add(selectionKey);
    state = state.copyWith(selectedKeys: current);
  }

  void selectAll(List<Recipient> recipients) {
    final allKeys = recipients.map((r) => r.selectionKey).toSet();
    state = state.copyWith(selectedKeys: state.selectedKeys.length == allKeys.length ? {} : allKeys);
  }

  List<Recipient> getSelectedRecipients(List<Recipient> all) => all.where((r) => state.selectedKeys.contains(r.selectionKey)).toList();

  List<Recipient>? confirmSelection(List<Recipient> all) {
    final selected = getSelectedRecipients(all);
    return selected.isEmpty ? null : selected;
  }
}
