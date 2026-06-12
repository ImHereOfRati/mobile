import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/terms/service/dto/terms_consent_request_dto.dart';
import 'package:iamhere/feature/terms/service/terms_response_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'terms_response_service_test.mocks.dart';

@GenerateMocks([Dio])
void main() {
  late TermsResponseService service;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    service = TermsResponseService(mockDio);
  });

  test('전체 약관 동의 요청은 consents[].id 형태로 전송되어야 한다', () async {
    final consents = [
      const TermsConsentItemDto(id: 2, agreed: true),
      const TermsConsentItemDto(id: 3, agreed: false),
    ];

    when(
      mockDio.post(
        '/api/auth/activation',
        data: {
          'consents': [
            {'id': 2, 'agreed': true},
            {'id': 3, 'agreed': false},
          ],
        },
        options: anyNamed('options'),
      ),
    ).thenAnswer(
      (_) async => Response(
        data: {
          'imhereResponseCode': 'SUCCESS',
          'message': 'OK',
          'data': {
            'accessToken': 'access-token',
            'refreshToken': 'refresh-token',
          },
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/auth/activation'),
      ),
    );

    final result = await service.requestToAllAgreeAboutRequiredTerms(consents);

    expect(result.data, isNotNull);
    expect(result.data!.accessToken, 'access-token');
    expect(result.data!.refreshToken, 'refresh-token');
  });
}
