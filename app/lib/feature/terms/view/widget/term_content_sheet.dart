import 'package:flutter/material.dart';
import 'package:iamhere/components/components.dart';
import 'package:iamhere/feature/terms/model/dto/term.dart';

/// 약관 전문을 화면 이동 없이 시트로 보여 준다. 높이는 화면의 90%를 넘기지 않고,
/// 내용이 길면 시트 안에서 스크롤한다. 시트에서 바로 동의하면 true를 돌려준다.
Future<bool?> showTermContentSheet(
  BuildContext context,
  Term term, {
  bool agreed = false,
}) {
  return showImHereSheet<bool>(
    context,
    title: term.title,
    builder: (sheetContext) {
      final colors = ImHereColors.of(sheetContext);
      final metrics = ImHereMetrics.of(sheetContext);
      final textTheme = Theme.of(sheetContext).textTheme;
      final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.9;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${term.isRequired ? '필수' : '선택'} · 버전 ${term.version} · 시행일 ${term.effectiveDay}',
            style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
          ),
          SizedBox(height: metrics.resolve(ImHereSpace.sm)),
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight * 0.55),
              child: ImHereSurface(
                child: SingleChildScrollView(
                  child: Text(
                    term.content,
                    style: textTheme.bodyMedium?.copyWith(height: 1.6),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: metrics.resolve(ImHereSpace.md)),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ImHereButton(
                  label: '닫기',
                  tone: ImHereButtonTone.weak,
                  size: ImHereButtonSize.lg,
                  expand: true,
                  onPressed: () => Navigator.of(sheetContext).pop(),
                ),
              ),
              if (!agreed) ...[
                SizedBox(width: metrics.resolve(ImHereSpace.xs)),
                Expanded(
                  flex: 7,
                  child: ImHereButton(
                    label: '동의하기',
                    size: ImHereButtonSize.lg,
                    expand: true,
                    onPressed: () => Navigator.of(sheetContext).pop(true),
                  ),
                ),
              ],
            ],
          ),
        ],
      );
    },
  );
}
