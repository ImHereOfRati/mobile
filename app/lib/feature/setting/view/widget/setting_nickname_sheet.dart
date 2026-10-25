import 'package:flutter/material.dart';
import 'package:iamhere/core/view/text_edit_sheet.dart';
import 'package:iamhere/feature/setting/viewmodel/account_view_model.dart';

/// 저장에 성공하면 `true`로 닫힌다.
Future<bool?> showNicknameSheet(
  BuildContext context, {
  required String initial,
  required Future<String?> Function(String nickname) onSave,
}) {
  return showTextEditSheet(
    context,
    title: '닉네임 수정',
    label: '닉네임',
    initial: initial,
    maxLength: nicknameMaxLength,
    onSave: onSave,
  );
}
