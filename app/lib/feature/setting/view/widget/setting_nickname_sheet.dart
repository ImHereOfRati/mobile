import 'package:flutter/material.dart';
import 'package:iamhere/components/components.dart';
import 'package:iamhere/feature/setting/viewmodel/account_view_model.dart';

/// 저장에 성공하면 `true`로 닫힌다.
Future<bool?> showNicknameSheet(
  BuildContext context, {
  required String initial,
  required Future<String?> Function(String nickname) onSave,
}) {
  return showImHereSheet<bool>(
    context,
    title: '닉네임 수정',
    builder: (_) => _NicknameSheet(initial: initial, onSave: onSave),
  );
}

class _NicknameSheet extends StatefulWidget {
  final String initial;
  final Future<String?> Function(String nickname) onSave;

  const _NicknameSheet({required this.initial, required this.onSave});

  @override
  State<_NicknameSheet> createState() => _NicknameSheetState();
}

class _NicknameSheetState extends State<_NicknameSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final message = await widget.onSave(_controller.text);
    if (!mounted) return;
    if (message == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _saving = false;
      _error = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final metrics = ImHereMetrics.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ImHereTextField(
            label: '닉네임',
            controller: _controller,
            maxLength: nicknameMaxLength,
            errorText: _error,
            enabled: !_saving,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _saving ? null : _save(),
          ),
          SizedBox(height: metrics.resolve(ImHereSpace.md)),
          // 두 버튼은 항상 너비를 똑같이 나눈다. 확인 다이얼로그와 같은 규칙이다.
          Row(
            children: [
              Expanded(
                child: ImHereButton(
                  label: '취소',
                  tone: ImHereButtonTone.weak,
                  expand: true,
                  onPressed: _saving
                      ? null
                      : () => Navigator.of(context).pop(false),
                ),
              ),
              SizedBox(width: metrics.resolve(ImHereSpace.xs)),
              Expanded(
                child: ImHereButton(
                  label: '저장',
                  expand: true,
                  loading: _saving,
                  onPressed: _saving ? null : _save,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
