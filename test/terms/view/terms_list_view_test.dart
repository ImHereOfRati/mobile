import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:iamhere/terms/service/dto/terms_list_request_dto.dart';
import 'package:iamhere/terms/service/dto/terms_type.dart';
import 'package:iamhere/terms/service/terms_list_request_service.dart';
import 'package:iamhere/terms/view/terms_list_view.dart';
import 'package:iamhere/terms/view_model/terms_list_view_model.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'terms_list_view_test.mocks.dart';

@GenerateMocks([TermsListRequestService])
void main() {
  late MockTermsListRequestService mockTermsService;

  setUp(() async {
    mockTermsService = MockTermsListRequestService();
    await GetIt.instance.reset();
    GetIt.instance.registerSingleton<TermsListRequestService>(mockTermsService);
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      child: ScreenUtilInit(
        designSize: const Size(402, 874),
        builder: (context, child) {
          return const MaterialApp(
            home: TermsListView(),
          );
        },
      ),
    );
  }

  group('TermsListView Widget Tests', () {
    testWidgets('TermsListView 생성 테스트',
        (WidgetTester tester) async {
      // Act
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.byType(TermsListView), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('TermsListRequestDto Unit Tests', () {
    test('필수 약관 필터링 테스트', () {
      // Arrange
      final allTerms = [
        TermsListRequestDto(
          termDefinitionId: 1,
          title: '서비스 이용약관',
          termsTypes: TermsType.service,
          isRequired: true,
        ),
        TermsListRequestDto(
          termDefinitionId: 2,
          title: '마케팅 정보 수신 동의',
          termsTypes: TermsType.marketing,
          isRequired: false,
        ),
        TermsListRequestDto(
          termDefinitionId: 3,
          title: '개인정보 처리방침',
          termsTypes: TermsType.privacy,
          isRequired: true,
        ),
      ];

      // Act
      final requiredTerms =
          allTerms.where((term) => term.isRequired).toList();
      final optionalTerms =
          allTerms.where((term) => !term.isRequired).toList();

      // Assert
      expect(requiredTerms, hasLength(2));
      expect(optionalTerms, hasLength(1));
      expect(
        requiredTerms.every((term) => term.isRequired),
        true,
      );
      expect(
        optionalTerms.every((term) => !term.isRequired),
        true,
      );
    });

    test('약관 ID 추출 테스트', () {
      // Arrange
      final terms = [
        TermsListRequestDto(
          termDefinitionId: 1,
          title: '약관1',
          termsTypes: TermsType.service,
          isRequired: true,
        ),
        TermsListRequestDto(
          termDefinitionId: 2,
          title: '약관2',
          termsTypes: TermsType.privacy,
          isRequired: true,
        ),
        TermsListRequestDto(
          termDefinitionId: 3,
          title: '약관3',
          termsTypes: TermsType.marketing,
          isRequired: false,
        ),
      ];

      // Act
      final ids = terms.map((term) => term.termDefinitionId).toList();

      // Assert
      expect(ids, [1, 2, 3]);
    });
  });
}
