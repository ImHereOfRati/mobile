import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iamhere/feature/geofence/model/recipient.dart';
import 'package:iamhere/feature/geofence/view_model/recipient/recipient_select_view_model.dart';

void showRecipientSelectionError(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('최소 1명 이상 선택해주세요')));
}

void confirmRecipientSelection(
  BuildContext context,
  WidgetRef ref,
  List<Recipient> all,
  List<String>? initialSelectedKeys,
) {
  final res = ref
      .read(recipientSelectViewModelProvider(initialSelectedKeys).notifier)
      .confirmSelection(all);
  if (res != null) {
    Navigator.of(context).pop(res);
  } else {
    showRecipientSelectionError(context);
  }
}
