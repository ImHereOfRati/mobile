import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/terms/service/dto/terms_type.dart';
import 'package:iamhere/feature/terms/service/terms_request_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'terms_list_request_service_test.mocks.dart';

@GenerateMocks([Dio])
void main() {
  late TermsRequestService termsService;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    termsService = TermsRequestService(mockDio);
  });

  group('TermsListRequestService - requestTermsList', () {
    test('성공: 약관 목록을 올바르게 반환해야 함', () async {
      // Arrange
      final responseData = {
        'imhereResponseCode': 'SUCCESS',
        'message': 'success',
        'data': [
          {
            'id': 1,
            'version': 1,
            'type': 'SERVICE',
            'title': '서비스 이용약관',
            'content': '서비스 이용약관 본문',
            'effectiveDate': '2026-06-10T20:52:03.289021734',
            'isRequired': true,
          },
          {
            'id': 2,
            'version': 3,
            'type': 'PRIVACY',
            'title': '개인정보 처리방침',
            'content': '개인정보 처리방침 본문',
            'effectiveDate': '2026-06-11T20:52:03.289021734',
            'isRequired': true,
          },
        ],
      };

      when(mockDio.get('/api/terms', options: anyNamed('options'))).thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/terms'),
        ),
      );

      // Act
      final result = await termsService.requestTermsList();

      // Assert
      expect(result.data, hasLength(2));
      expect(result.data![0].id, 1);
      expect(result.data![0].version, 1);
      expect(result.data![0].title, '서비스 이용약관');
      expect(result.data![0].type, TermsType.service);
      expect(result.data![0].content, '서비스 이용약관 본문');
      expect(result.data![0].isRequired, true);
      expect(result.data![1].id, 2);
      expect(result.data![1].version, 3);
      expect(result.data![1].title, '개인정보 처리방침');
      expect(result.data![1].type, TermsType.privacy);
      expect(result.data![1].isRequired, true);

      verify(mockDio.get('/api/terms', options: anyNamed('options'))).called(1);
    });

    test('실패: 200이 아닌 상태 코드 시 예외를 발생해야 함', () async {
      // Arrange
      when(mockDio.get('/api/terms', options: anyNamed('options'))).thenAnswer(
        (_) async => Response(
          data: {},
          statusCode: 400,
          requestOptions: RequestOptions(path: '/api/terms'),
        ),
      );

      // Act & Assert
      expect(() => termsService.requestTermsList(), throwsException);
    });

    test('실패: Dio 예외 발생 시 예외를 전파해야 함', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/api/terms');
      when(
        mockDio.get('/api/terms', options: anyNamed('options')),
      ).thenThrow(DioException(requestOptions: requestOptions));

      // Act & Assert
      expect(() => termsService.requestTermsList(), throwsException);
    });
  });
}
