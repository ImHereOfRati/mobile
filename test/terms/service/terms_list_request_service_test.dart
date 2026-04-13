import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/terms/service/dto/terms_type.dart';
import 'package:iamhere/terms/service/terms_request_service.dart';
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
        'code': 200,
        'message': 'success',
        'data': {
          'content': [
            {
              'termDefinitionId': 1,
              'title': '서비스 이용약관',
              'termsTypes': 'SERVICE',
              'isRequired': true,
            },
            {
              'termDefinitionId': 2,
              'title': '개인정보 처리방침',
              'termsTypes': 'PRIVACY',
              'isRequired': true,
            },
          ],
          'totalPages': 1,
          'totalElements': 2,
          'number': 0,
          'size': 20,
          'last': true,
        },
      };

      when(mockDio.get('/api/user/terms')).thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/user/terms'),
        ),
      );

      // Act
      final result = await termsService.requestTermsList();

      // Assert
      expect(result.data.content, hasLength(2));
      expect(result.data.content[0].termDefinitionId, 1);
      expect(result.data.content[0].title, '서비스 이용약관');
      expect(result.data.content[0].termsTypes, TermsType.service);
      expect(result.data.content[0].isRequired, true);
      expect(result.data.content[1].termDefinitionId, 2);
      expect(result.data.content[1].title, '개인정보 처리방침');
      expect(result.data.content[1].termsTypes, TermsType.privacy);
      expect(result.data.content[1].isRequired, true);

      verify(mockDio.get('/api/user/terms')).called(1);
    });

    test('실패: 200이 아닌 상태 코드 시 예외를 발생해야 함', () async {
      // Arrange
      when(mockDio.get('/api/user/terms')).thenAnswer(
        (_) async => Response(
          data: {},
          statusCode: 400,
          requestOptions: RequestOptions(path: '/api/user/terms'),
        ),
      );

      // Act & Assert
      expect(() => termsService.requestTermsList(), throwsException);
    });

    test('실패: Dio 예외 발생 시 예외를 전파해야 함', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/api/user/terms');
      when(
        mockDio.get('/api/user/terms'),
      ).thenThrow(DioException(requestOptions: requestOptions));

      // Act & Assert
      expect(() => termsService.requestTermsList(), throwsException);
    });
  });

  group('TermsListRequestService - requestTermsDetail', () {
    test('성공: 약관 상세 정보를 올바르게 반환해야 함', () async {
      // Arrange
      const termId = 1;
      final responseData = {
        'code': 200,
        'message': 'OK',
        'data': {
          'version': 'v1.0',
          'content': '[서비스 이용약관]\n\n제1조 목적...',
          'effectiveDate': '2024-01-01T00:00:00',
        },
      };

      when(mockDio.get('/api/user/terms/version/$termId')).thenAnswer(
        (_) async => Response(
          data: responseData,
          statusCode: 200,
          requestOptions: RequestOptions(
            path: '/api/user/terms/version/$termId',
          ),
        ),
      );

      // Act
      final result = await termsService.requestTermsDetail(termId);

      // Assert
      expect(result.data.version, 'v1.0');
      expect(result.data.content, contains('서비스 이용약관'));
      expect(result.data.effectiveDate.year, 2024);
      expect(result.data.effectiveDate.month, 1);
      expect(result.data.effectiveDate.day, 1);

      verify(mockDio.get('/api/user/terms/version/$termId')).called(1);
    });

    test('실패: 200이 아닌 상태 코드 시 예외를 발생해야 함', () async {
      // Arrange
      const termId = 1;
      when(mockDio.get('/api/user/terms/version/$termId')).thenAnswer(
        (_) async => Response(
          data: {},
          statusCode: 404,
          requestOptions: RequestOptions(
            path: '/api/user/terms/version/$termId',
          ),
        ),
      );

      // Act & Assert
      expect(() => termsService.requestTermsDetail(termId), throwsException);
    });

    test('실패: Dio 예외 발생 시 예외를 전파해야 함', () async {
      // Arrange
      const termId = 1;
      final requestOptions = RequestOptions(
        path: '/api/user/terms/version/$termId',
      );
      when(
        mockDio.get('/api/user/terms/version/$termId'),
      ).thenThrow(DioException(requestOptions: requestOptions));

      // Act & Assert
      expect(() => termsService.requestTermsDetail(termId), throwsException);
    });
  });
}
