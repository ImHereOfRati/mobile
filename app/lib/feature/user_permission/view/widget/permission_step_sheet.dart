import 'package:flutter/material.dart';
import 'package:iamhere/components/components.dart';
import 'package:iamhere/core/util/korean_text.dart';
import 'package:iamhere/feature/user_permission/model/permission_guide_content.dart';
import 'package:iamhere/feature/user_permission/view/widget/pulsing_highlight.dart';

/// 설정 화면이나 시스템 창으로 이동하기 전에, 무엇을 해야 하는지 단계별로
/// 알려 준다. 확인하면 true, 닫으면 false를 돌려준다.
Future<bool> showPermissionStepSheet(
  BuildContext context,
  PermissionGuideContent content,
) async {
  final confirmed = await showImHereSheet<bool>(
    context,
    title: KoreanText.keepWords(content.title),
    builder: (sheetContext) => _StepSheetBody(content: content),
  );
  return confirmed == true;
}

class _StepSheetBody extends StatelessWidget {
  final PermissionGuideContent content;

  const _StepSheetBody({required this.content});

  @override
  Widget build(BuildContext context) {
    final metrics = ImHereMetrics.of(context);
    final colors = ImHereColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (content.purpose != null) ...[
                  Text(
                    KoreanText.keepWords(content.purpose!),
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.textMuted,
                      height: 1.55,
                    ),
                  ),
                  SizedBox(height: metrics.resolve(ImHereSpace.lg)),
                ],
                for (var i = 0; i < content.steps.length; i++) ...[
                  _Step(number: i + 1, step: content.steps[i]),
                  if (i < content.steps.length - 1)
                    SizedBox(height: metrics.resolve(ImHereSpace.md)),
                ],
                SizedBox(height: metrics.resolve(ImHereSpace.lg)),
                _Preview(content: content),
              ],
            ),
          ),
        ),
        SizedBox(height: metrics.resolve(ImHereSpace.md)),
        ImHereButton(
          label: content.confirmLabel,
          size: ImHereButtonSize.lg,
          expand: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        SizedBox(height: metrics.resolve(ImHereSpace.xs)),
        ImHereButton(
          label: '나중에 할게요',
          tone: ImHereButtonTone.ghost,
          expand: true,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  final int number;
  final GuideStep step;

  const _Step({required this.number, required this.step});

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    final metrics = ImHereMetrics.of(context);
    final textTheme = Theme.of(context).textTheme;
    final base = textTheme.bodyLarge?.copyWith(
      color: colors.text,
      fontWeight: FontWeight.w500,
      height: 1.45,
    );

    return Semantics(
      label: [
        '$number단계',
        step.text,
        if (step.note != null) step.note!,
      ].join(', '),
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: metrics.resolve(24),
            height: metrics.resolve(24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.action,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: textTheme.labelLarge?.copyWith(
                color: colors.onAction,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: metrics.resolve(ImHereSpace.sm)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    style: base,
                    children: _spans(
                      step.text,
                      step.highlights,
                      base?.copyWith(
                        color: colors.action,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (step.note != null) ...[
                  SizedBox(height: metrics.resolve(ImHereSpace.xxs)),
                  Text(
                    KoreanText.keepWords(step.note!),
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.textMuted,
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// [highlights]에 든 말만 강조하고, 나머지는 단어 단위로 줄이 바뀌게 한다.
  static List<InlineSpan> _spans(
    String text,
    List<String> highlights,
    TextStyle? emphasis,
  ) {
    final matches = <({int start, int end})>[];
    for (final highlight in highlights) {
      final start = text.indexOf(highlight);
      if (start >= 0) {
        matches.add((start: start, end: start + highlight.length));
      }
    }
    matches.sort((a, b) => a.start.compareTo(b.start));

    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final match in matches) {
      if (match.start < cursor) continue;
      if (match.start > cursor) {
        spans.add(
          TextSpan(
            text: KoreanText.keepWords(text.substring(cursor, match.start)),
          ),
        );
      }
      spans.add(
        TextSpan(
          text: KoreanText.keepWords(text.substring(match.start, match.end)),
          style: emphasis,
        ),
      );
      cursor = match.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: KoreanText.keepWords(text.substring(cursor))));
    }
    return spans;
  }
}

/// 실제 설정 화면이 어떻게 보일지 흉내 낸 미리보기. 눌러야 할 항목은 깜빡인다.
class _Preview extends StatelessWidget {
  final PermissionGuideContent content;

  const _Preview({required this.content});

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    final metrics = ImHereMetrics.of(context);
    final textTheme = Theme.of(context).textTheme;

    return ExcludeSemantics(
      child: ImHereSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              KoreanText.keepWords(content.previewTitle),
              style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
            ),
            SizedBox(height: metrics.resolve(ImHereSpace.sm)),
            for (final option in content.options) ...[
              _PreviewOption(option: option),
              SizedBox(height: metrics.resolve(ImHereSpace.xxs)),
            ],
          ],
        ),
      ),
    );
  }
}

class _PreviewOption extends StatelessWidget {
  final GuideOption option;

  const _PreviewOption({required this.option});

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    final metrics = ImHereMetrics.of(context);
    final textTheme = Theme.of(context).textTheme;

    final row = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: metrics.resolve(ImHereSpace.sm),
        vertical: metrics.resolve(ImHereSpace.sm),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              KoreanText.keepWords(option.label),
              style: textTheme.bodyMedium?.copyWith(
                color: option.target ? colors.action : colors.text,
                fontWeight: option.target ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          if (option.target)
            Text(
              '여기를 눌러요',
              style: textTheme.labelLarge?.copyWith(
                color: colors.action,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );

    if (option.target) return PulsingHighlight(child: row);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.transparent,
          width: metrics.resolve(2),
        ),
      ),
      child: row,
    );
  }
}
