import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/setting/view/terms_view.dart';
import 'package:iamhere/feature/terms/service/dto/terms_list_request_dto.dart';
import 'package:iamhere/feature/terms/service/dto/terms_type.dart';
import 'package:iamhere/feature/terms/view_model/terms_list_view_model.dart';

class _FakeTermsListViewModel extends TermsListViewModel {
  _FakeTermsListViewModel(this._terms);

  final List<TermsListRequestDto> _terms;

  @override
  Future<List<TermsListRequestDto>> build() async => _terms;
}

void main() {
  testWidgets('약관 보기 화면은 서버 약관과 개발자 정보를 렌더링해야 함', (
    WidgetTester tester,
  ) async {
    final terms = [
      TermsListRequestDto(
        id: 1,
        version: 1,
        type: TermsType.service,
        title: '서비스 이용약관',
        content: '서버에서 내려온 약관 본문',
        effectiveDate: DateTime(2026, 1, 1),
        isRequired: true,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          termsListViewModelProvider.overrideWith(
            () => _FakeTermsListViewModel(terms),
          ),
        ],
        child: ScreenUtilInit(
          designSize: const Size(402, 874),
          child: const MaterialApp(home: TermsView()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('서비스 이용약관'));
    await tester.pumpAndSettle();

    expect(find.text('약관 보기'), findsOneWidget);
    expect(find.text('서비스 이용약관'), findsOneWidget);
    expect(find.text('서버에서 내려온 약관 본문'), findsOneWidget);
    expect(find.text('개발자 정보'), findsOneWidget);
    expect(find.text('고동수'), findsOneWidget);
    expect(find.text('kod66170@gmail.com'), findsOneWidget);
  });
}
