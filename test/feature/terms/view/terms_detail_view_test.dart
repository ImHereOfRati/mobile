import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:iamhere/feature/terms/service/dto/terms_version_response_dto.dart';
import 'package:iamhere/feature/terms/service/terms_request_service.dart';
import 'package:iamhere/feature/terms/view/terms_detail_view.dart';
import 'package:iamhere/shared/base/api_response/api_response.dart';
import 'package:iamhere/shared/component/theme/im_here_theme_data_dark.dart';
import 'package:iamhere/shared/component/theme/im_here_theme_data_light.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'terms_detail_view_test.mocks.dart';

@GenerateMocks([TermsRequestService])
void main() {
  late MockTermsRequestService mockTermsService;

  setUp(() async {
    mockTermsService = MockTermsRequestService();
    await GetIt.instance.reset();
    GetIt.instance.registerSingleton<TermsRequestService>(mockTermsService);
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  Widget createWidgetUnderTest(int termDefinitionId) {
    return ScreenUtilInit(
      designSize: const Size(402, 874),
      builder: (context, child) {
        return MaterialApp(
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: ThemeMode.system,
          home: TermsDetailView(termDefinitionId: termDefinitionId),
        );
      },
    );
  }

  group('TermsDetailView Widget Tests', () {
    testWidgets('TermsDetailView 생성 테스트', (WidgetTester tester) async {
      // Arrange
      final termDto = TermsVersionResponseDto(
        version: '1.0',
        content: '테스트 약관 내용',
        effectiveDate: DateTime(2024, 1, 1),
      );
      final apiResponse = APIResponse<TermsVersionResponseDto>(
        code: 200,
        message: 'OK',
        data: termDto,
      );

      when(
        mockTermsService.requestTermsDetail(1),
      ).thenAnswer((_) async => apiResponse);

      // Act
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest(1));

      // Assert - 위젯이 생성되어야 함
      expect(find.byType(TermsDetailView), findsOneWidget);
    });

    testWidgets('로딩 중 CircularProgressIndicator 표시 테스트', (
      WidgetTester tester,
    ) async {
      // Arrange — Completer를 사용해 영구적으로 pending 상태 유지 (타이머 없음)
      final completer = Completer<APIResponse<TermsVersionResponseDto>>();

      when(
        mockTermsService.requestTermsDetail(1),
      ).thenAnswer((_) => completer.future);

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Act
      await tester.pumpWidget(createWidgetUnderTest(1));
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 테스트 종료 전 completer를 완료시켜 pending future 해제
      completer.complete(
        APIResponse(
          code: 200,
          message: 'OK',
          data: TermsVersionResponseDto(
            version: '1.0',
            content: '내용',
            effectiveDate: DateTime(2024),
          ),
        ),
      );
    });

    testWidgets('약관 내용 렌더링 테스트', (WidgetTester tester) async {
      // Arrange
      const content = '제1조 (목적) 본 약관은...';
      final termDto = TermsVersionResponseDto(
        version: '1.0',
        content: content,
        effectiveDate: DateTime(2024, 1, 1),
      );
      final apiResponse = APIResponse<TermsVersionResponseDto>(
        code: 200,
        message: 'OK',
        data: termDto,
      );

      when(
        mockTermsService.requestTermsDetail(1),
      ).thenAnswer((_) async => apiResponse);

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Act
      await tester.pumpWidget(createWidgetUnderTest(1));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text(content), findsOneWidget);
    });
  });

  group('TermsVersionResponse Unit Tests', () {
    test('TermsVersionResponse 객체 생성 테스트', () {
      // Arrange
      final effectiveDate = DateTime(2024, 1, 1);
      const version = '1.0';
      const content = '[약관 내용]';

      // Act
      final response = TermsVersionResponseDto(
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
      final response = TermsVersionResponseDto(
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
      final response = TermsVersionResponseDto.fromJson(json);

      // Assert
      expect(response.version, '2.0');
      expect(response.content, '변경된 약관 내용');
      expect(response.effectiveDate.year, 2024);
      expect(response.effectiveDate.month, 6);
      expect(response.effectiveDate.day, 1);
    });
  });
}
