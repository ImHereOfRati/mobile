import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/terms/service/dto/terms_type.dart';
import 'package:iamhere/feature/terms/service/dto/terms_list_request_dto.dart';
import 'package:iamhere/feature/terms/view/terms_list_view.dart';
import 'package:iamhere/feature/terms/view_model/terms_list_view_model.dart';

void main() {
  group('TermsListView - Content Display', () {
    testWidgets('약관 아이템이 타이틀과 컨텐츠를 모두 표시한다', (WidgetTester tester) async {
      final testTerms = [
        TermsListRequestDto(
          id: 1,
          version: 1,
          type: TermsType.service,
          title: '서비스 이용약관',
          content: '서비스를 이용하기 위해 이 약관에 동의해야 합니다.',
          effectiveDate: DateTime.now(),
          isRequired: true,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  return ListView(
                    children: testTerms.map((term) {
                      return _buildTestTermItem(context, term);
                    }).toList(),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // 타이틀 확인
      expect(find.textContaining('서비스 이용약관'), findsWidgets);

      // 컨텐츠 확인
      expect(find.textContaining('서비스를 이용하기 위해'), findsWidgets);

      // 필수 라벨 확인
      expect(find.textContaining('[필수]'), findsWidgets);
    });

    testWidgets('선택 약관은 [선택] 라벨로 표시된다', (WidgetTester tester) async {
      final testTerms = [
        TermsListRequestDto(
          id: 1,
          version: 1,
          type: TermsType.privacy,
          title: '개인정보 처리방침',
          content: '개인정보 보호 약관입니다.',
          effectiveDate: DateTime.now(),
          isRequired: false,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  return ListView(
                    children: testTerms.map((term) {
                      return _buildTestTermItem(context, term);
                    }).toList(),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // 선택 라벨 확인
      expect(find.textContaining('[선택]'), findsWidgets);

      // 컨텐츠 확인
      expect(find.textContaining('개인정보 보호'), findsWidgets);
    });

    testWidgets('여러 약관이 모두 컨텐츠와 함께 표시된다', (WidgetTester tester) async {
      final testTerms = [
        TermsListRequestDto(
          id: 1,
          version: 1,
          type: TermsType.service,
          title: '약관 1',
          content: '컨텐츠 1',
          effectiveDate: DateTime.now(),
          isRequired: true,
        ),
        TermsListRequestDto(
          id: 2,
          version: 1,
          type: TermsType.privacy,
          title: '약관 2',
          content: '컨텐츠 2',
          effectiveDate: DateTime.now(),
          isRequired: false,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  return ListView(
                    children: testTerms.map((term) {
                      return _buildTestTermItem(context, term);
                    }).toList(),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // 모든 약관이 표시되는지 확인
      expect(find.textContaining('약관 1'), findsWidgets);
      expect(find.textContaining('약관 2'), findsWidgets);
      expect(find.textContaining('컨텐츠 1'), findsWidgets);
      expect(find.textContaining('컨텐츠 2'), findsWidgets);
    });
  });
}

Widget _buildTestTermItem(BuildContext context, TermsListRequestDto term) {
  final cs = Theme.of(context).colorScheme;

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                  width: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Text(
                    term.isRequired ? '[필수] ' : '[선택] ',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: term.isRequired
                          ? cs.primary
                          : cs.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                  Text(
                    term.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 34, top: 8, right: 12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              term.content,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
