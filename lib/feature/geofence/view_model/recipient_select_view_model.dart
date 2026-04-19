import 'package:iamhere/feature/geofence/model/recipient.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recipient_select_view_model.g.dart';

/// 수신자 선택 상태
/// 로컬/서버 친구 통합 선택키("local:{id}" | "server:{uuid}") 기준으로 관리
class RecipientSelectState {
  final Set<String> selectedKeys;

  RecipientSelectState({Set<String>? selectedKeys})
    : selectedKeys = selectedKeys ?? {};

  RecipientSelectState copyWith({Set<String>? selectedKeys}) {
    return RecipientSelectState(
      selectedKeys: selectedKeys ?? this.selectedKeys,
    );
  }

  int get selectedCount => selectedKeys.length;
}

@Riverpod(keepAlive: false)
class RecipientSelectViewModel extends _$RecipientSelectViewModel {
  @override
  RecipientSelectState build(List<String>? initialSelectedKeys) {
    return RecipientSelectState(
      selectedKeys: initialSelectedKeys?.toSet() ?? {},
    );
  }

  /// 수신자 선택/해제 토글
  void toggleSelection(String selectionKey) {
    final current = Set<String>.from(state.selectedKeys);
    if (current.contains(selectionKey)) {
      current.remove(selectionKey);
    } else {
      current.add(selectionKey);
    }
    state = state.copyWith(selectedKeys: current);
  }

  /// 전체 선택/해제
  void selectAll(List<Recipient> recipients) {
    final allKeys = recipients.map((r) => r.selectionKey).toSet();
    if (state.selectedKeys.length == allKeys.length) {
      state = state.copyWith(selectedKeys: {});
    } else {
      state = state.copyWith(selectedKeys: allKeys);
    }
  }

  /// 선택된 수신자 리스트 반환
  List<Recipient> getSelectedRecipients(List<Recipient> allRecipients) {
    return allRecipients
        .where((r) => state.selectedKeys.contains(r.selectionKey))
        .toList();
  }

  /// 선택 확인 및 유효성 검사
  List<Recipient>? confirmSelection(List<Recipient> allRecipients) {
    final selected = getSelectedRecipients(allRecipients);
    if (selected.isEmpty) return null;
    return selected;
  }
}
