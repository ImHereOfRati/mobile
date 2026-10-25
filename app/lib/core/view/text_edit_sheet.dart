import 'package:flutter/material.dart';
import 'package:iamhere/components/components.dart';

/// 한 줄 텍스트를 고치는 시트. 저장에 성공하면 `true`로 닫힌다.
///
/// [onSave]가 null을 돌려주면 성공이고, 문자열을 돌려주면 그 문자열을 오류로
/// 보여 주며 시트를 유지한다.
Future<bool?> showTextEditSheet(
  BuildContext context, {
  required String title,
  required String label,
  required String initial,
  required int maxLength,
  required Future<String?> Function(String value) onSave,
}) {
  return showImHereSheet<bool>(
    context,
    title: title,
    builder: (_) => _TextEditSheet(
      label: label,
      initial: initial,
      maxLength: maxLength,
      onSave: onSave,
    ),
  );
}

class _TextEditSheet extends StatefulWidget {
  final String label;
  final String initial;
  final int maxLength;
  final Future<String?> Function(String value) onSave;

  const _TextEditSheet({
    required this.label,
    required this.initial,
    required this.maxLength,
    required this.onSave,
  });

  @override
  State<_TextEditSheet> createState() => _TextEditSheetState();
}

class _TextEditSheetState extends State<_TextEditSheet> {
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
            label: widget.label,
            controller: _controller,
            maxLength: widget.maxLength,
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
