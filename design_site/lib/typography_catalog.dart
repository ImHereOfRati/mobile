import 'package:flutter/material.dart';
import 'package:iamhere/components/components.dart';

class TypographyCatalog extends StatelessWidget {
  const TypographyCatalog({super.key});

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).textTheme;
    final samples = [
      ('큰 제목', '지금 필요한 소식', type.headlineLarge),
      ('화면 제목', '알림을 보낼 장소', type.headlineMedium),
      ('섹션 제목', '저장한 장소', type.titleLarge),
      ('목록 제목', '회사에 도착했어요', type.titleMedium),
      ('본문', '도착하면 선택한 친구에게 알려드려요.', type.bodyLarge),
      ('보조 설명', '알림은 언제든 끌 수 있어요.', type.bodyMedium),
      ('작은 정보', '오늘 오전 9:41', type.bodySmall),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ImHereParagraph(
          text: '제목에서 먼저 핵심을 말하고, 본문에는 다음 행동에 필요한 정보만 담습니다.',
        ),
        const SizedBox(height: 24),
        Text('역할별 스타일', style: type.titleMedium),
        const SizedBox(height: 16),
        for (final (name, example, style) in samples) ...[
          _TypeSample(name: name, example: example, style: style!),
          if (name != '작은 정보') ...[
            const SizedBox(height: 16),
            const ImHereBorder(tone: ImHereDividerTone.subtle),
            const SizedBox(height: 16),
          ],
        ],
        const SizedBox(height: 32),
        Text('크기 단계', style: type.titleMedium),
        const SizedBox(height: 4),
        const ImHereParagraph(
          text: '글자 크기와 줄 높이는 한 쌍으로 씁니다. 굵기는 500과 700 두 가지예요.',
          muted: true,
        ),
        const SizedBox(height: 16),
        for (final t in ImHereTypeScale.values) ...[
          Text(
            '${t.name} · ${t.size.round()} / ${t.lineHeight.round()}',
            style: type.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            '도착했어요',
            style: ImHereType.style(
              t,
              ImHereType.bold,
              ImHereColors.of(context).text,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _TypeSample extends StatelessWidget {
  const _TypeSample({
    required this.name,
    required this.example,
    required this.style,
  });

  final String name;
  final String example;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final weight = ((style.fontWeight?.index ?? 3) + 1) * 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$name · ${style.fontSize?.round()}px / $weight',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Text(example, style: style),
      ],
    );
  }
}
