import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:iamhere/terms/service/terms_list_request_service.dart';
import 'package:iamhere/terms/service/terms_version_response.dart';
import 'package:iamhere/terms/view/terms_detail_view.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'terms_detail_view_test.mocks.dart';

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

  Widget createWidgetUnderTest(int termDefinitionId) {
    return ScreenUtilInit(
      designSize: const Size(402, 874),
      builder: (context, child) {
        return MaterialApp(
          home: TermsDetailView(termDefinitionId: termDefinitionId),
        );
      },
    );
  }

  group('TermsDetailView Widget Tests', () {
    testWidgets('TermsDetailView 생성 테스트',
        (WidgetTester tester) async {
      // Arrange
      final termContent = TermsVersionResponse(
        version: '1.0',
        content: '테스트 약관 내용',
        effectiveDate: DateTime(2024, 1, 1),
      );

      when(mockTermsService.requestTermsDetail(1)).thenAnswer(
        (_) async => termContent,
      );

      // Act
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest(1));

      // Assert - 위젯이 생성되어야 함
      expect(find.byType(TermsDetailView), findsOneWidget);
    });
  });

  group('TermsVersionResponse Unit Tests', () {
    test('TermsVersionResponse 객체 생성 테스트', () {
      // Arrange
      final effectiveDate = DateTime(2024, 1, 1);
      const version = '1.0';
      const content = '[약관 내용]';

      // Act
      final response = TermsVersionResponse(
        version: version,
        content: content,
        effectiveDate: effectiveDate,
      );

      // Assert
      expect(response.version, version);
      expect(response.content, content);
      expect(response.effectiveDate, effectiveDate);
    });

    test('TermsVersionResponse JSON 직렬화 테스트', () {
      // Arrange
      final response = TermsVersionResponse(
        version: '1.0',
        content: '약관 내용',
        effectiveDate: DateTime(2024, 1, 1),
      );

      // Act
      final json = response.toJson();

      // Assert
      expect(json['version'], '1.0');
      expect(json['content'], '약관 내용');
      expect(json.containsKey('effectiveDate'), true);
    });

    test('TermsVersionResponse JSON 역직렬화 테스트', () {
      // Arrange
      final json = {
        'version': '2.0',
        'content': '변경된 약관 내용',
        'effectiveDate': '2024-06-01T00:00:00.000Z',
      };

      // Act
      final response = TermsVersionResponse.fromJson(json);

      // Assert
      expect(response.version, '2.0');
      expect(response.content, '변경된 약관 내용');
      expect(response.effectiveDate.year, 2024);
      expect(response.effectiveDate.month, 6);
      expect(response.effectiveDate.day, 1);
    });
  });
}
