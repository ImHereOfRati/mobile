import 'package:iamhere/friend/view_model/contact.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recipient_select_view_model.g.dart';

/// 수신자 선택 상태
class RecipientSelectState {
  final Set<int> selectedIds;

  RecipientSelectState({Set<int>? selectedIds})
    : selectedIds = selectedIds ?? {};

  RecipientSelectState copyWith({Set<int>? selectedIds}) {
    return RecipientSelectState(selectedIds: selectedIds ?? this.selectedIds);
  }

  int get selectedCount => selectedIds.length;
}

@Riverpod(keepAlive: false)
class RecipientSelectViewModel extends _$RecipientSelectViewModel {
  @override
  RecipientSelectState build(List<int>? initialSelectedIds) {
    // 초기 선택된 ID가 있으면 복원
    return RecipientSelectState(selectedIds: initialSelectedIds?.toSet() ?? {});
  }

  /// 연락처 선택/해제 토글
  void toggleSelection(int? contactId) {
    if (contactId == null) return;

    final currentIds = Set<int>.from(state.selectedIds);
    if (currentIds.contains(contactId)) {
      currentIds.remove(contactId);
    } else {
      currentIds.add(contactId);
    }

    state = state.copyWith(selectedIds: currentIds);
  }

  /// 전체 선택/해제
  void selectAll(List<Contact> contacts) {
    final currentIds = Set<int>.from(state.selectedIds);
    final allContactIds = contacts
        .where((c) => c.id != null)
        .map((c) => c.id!)
        .toSet();

    if (currentIds.length == allContactIds.length) {
      // 전체 선택 해제
      state = state.copyWith(selectedIds: {});
    } else {
      // 전체 선택
      state = state.copyWith(selectedIds: allContactIds);
    }
  }

  /// 선택된 연락처 리스트 반환
  List<Contact> getSelectedContacts(List<Contact> allContacts) {
    return allContacts
        .where((contact) => state.selectedIds.contains(contact.id))
        .toList();
  }

  /// 선택 확인 및 유효성 검사
  List<Contact>? confirmSelection(List<Contact> allContacts) {
    final selectedContacts = getSelectedContacts(allContacts);

    if (selectedContacts.isEmpty) {
      return null; // 유효성 검사 실패
    }

    return selectedContacts;
  }
}
