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
