import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/friend/service/friend_restriction_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'friend_restriction_service_test.mocks.dart';

@GenerateMocks([Dio])
void main() {
  late FriendRestrictionService service;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    service = FriendRestrictionService(dio: mockDio);
  });

  group('fetchRestrictions', () {
    test('성공 시 제한 목록을 반환해야 함', () async {
      when(
        mockDio.get(
          '/api/friends/restrictions',
          options: anyNamed('options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'imhereResponseCode': 'SUCCESS',
            'message': 'OK',
            'data': {
              'content': [
                {
                  'id': 'restriction-1',
                  'restrictor': {
                    'id': 'restrictor-id',
                    'email': 'owner@test.com',
                    'nickname': '나',
                    'oAuth2Provider': 'KAKAO',
                  },
                  'restricted': {
                    'id': 'target-id',
                    'email': 'blocked@test.com',
                    'nickname': '차단된유저',
                    'oAuth2Provider': 'KAKAO',
                  },
                  'type': 'BLOCK',
                  'createdAt': '2026-04-15T10:00:00',
                  'updatedAt': '2026-04-15T10:00:00',
                  'expiredAt': null,
                },
              ],
              'hasNext': false,
            },
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/friends/restrictions'),
        ),
      );

      final result = await service.fetchRestrictions();

      expect(result.length, 1);
      expect(result[0].targetNickname, '차단된유저');
      expect(result[0].restrictionType, 'BLOCK');
    });

    test('실패 시 빈 리스트를 반환해야 함', () async {
      when(
        mockDio.get(
          '/api/friends/restrictions',
          options: anyNamed('options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/friends/restrictions'),
        ),
      );

      final result = await service.fetchRestrictions();
      expect(result, isEmpty);
    });
  });

  group('deleteRestriction', () {
    test('성공 시 true를 반환해야 함', () async {
      when(
        mockDio.delete(
          '/api/friends/restrictions/restriction-1',
          options: anyNamed('options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'imhereResponseCode': 'SUCCESS',
            'message': 'OK',
            'data': null,
          },
          statusCode: 200,
          requestOptions: RequestOptions(
            path: '/api/friends/restrictions/restriction-1',
          ),
        ),
      );

      final result = await service.deleteRestriction('restriction-1');

      expect(result, isTrue);
    });

    test('실패 시 false를 반환해야 함', () async {
      when(
        mockDio.delete(
          '/api/friends/restrictions/restriction-1',
          options: anyNamed('options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: '/api/friends/restrictions/restriction-1',
          ),
        ),
      );

      final result = await service.deleteRestriction('restriction-1');
      expect(result, isFalse);
    });
  });
}
