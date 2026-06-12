import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/friend/service/dto/update_friend_alias_request_dto.dart';
import 'package:iamhere/feature/friend/service/friend_relationship_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'friend_relationship_service_test.mocks.dart';

@GenerateMocks([Dio])
void main() {
  late FriendRelationshipService service;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    service = FriendRelationshipService(dio: mockDio);
  });

  group('fetchFriendList', () {
    test('성공 시 친구 목록을 반환해야 함', () async {
      when(
        mockDio.get('/api/friendships', options: anyNamed('options')),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'imhereResponseCode': 'SUCCESS',
            'message': 'OK',
            'data': {
              'content': [
                {
                  'id': 'uuid-1',
                  'owner': {
                    'id': 'owner-id',
                    'email': 'owner@test.com',
                    'nickname': '나',
                    'oAuth2Provider': 'KAKAO',
                  },
                  'friend': {
                    'id': 'friend-1',
                    'email': 'a@test.com',
                    'nickname': '친구A',
                    'oAuth2Provider': 'KAKAO',
                  },
                  'friendAlias': '친구A',
                  'createdAt': '2026-06-11T20:51:42.260523562',
                  'updatedAt': '2026-06-11T20:51:42.260523562',
                },
                {
                  'id': 'uuid-2',
                  'owner': {
                    'id': 'owner-id',
                    'email': 'owner@test.com',
                    'nickname': '나',
                    'oAuth2Provider': 'KAKAO',
                  },
                  'friend': {
                    'id': 'friend-2',
                    'email': 'b@test.com',
                    'nickname': '친구B',
                    'oAuth2Provider': 'KAKAO',
                  },
                  'friendAlias': '친구B',
                  'createdAt': '2026-06-11T20:51:42.260523562',
                  'updatedAt': '2026-06-11T20:51:42.260523562',
                },
              ],
              'hasNext': false,
            },
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/friendships'),
        ),
      );

      final result = await service.fetchFriendList();

      expect(result.length, 2);
      expect(result[0].friendAlias, '친구A');
      expect(result[1].friendRelationshipId, 'uuid-2');
    });

    test('실패 시 빈 리스트를 반환해야 함', () async {
      when(
        mockDio.get('/api/friendships', options: anyNamed('options')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/friendships'),
        ),
      );

      final result = await service.fetchFriendList();
      expect(result, isEmpty);
    });
  });

  group('updateAlias', () {
    test('성공 시 변경된 친구 정보를 반환해야 함', () async {
      final request = UpdateFriendAliasRequestDto(
        friendRelationshipId: 'uuid-1',
        alias: '새별명',
      );

      when(
        mockDio.patch(
          '/api/friendships/uuid-1/alias',
          data: anyNamed('data'),
          options: anyNamed('options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'imhereResponseCode': 'SUCCESS',
            'message': 'OK',
            'data': {
              'id': 'uuid-1',
              'owner': {
                'id': 'owner-id',
                'email': 'owner@test.com',
                'nickname': '나',
                'oAuth2Provider': 'KAKAO',
              },
              'friend': {
                'id': 'friend-1',
                'email': 'a@test.com',
                'nickname': '친구A',
                'oAuth2Provider': 'KAKAO',
              },
              'friendAlias': '새별명',
              'createdAt': '2026-06-11T20:51:42.103264033',
              'updatedAt': '2026-06-11T20:51:42.103264033',
            },
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/friendships/uuid-1/alias'),
        ),
      );

      final result = await service.updateAlias(request);

      expect(result, isNotNull);
      expect(result!.friendAlias, '새별명');
    });
  });

  group('blockFriend', () {
    test('성공 시 true를 반환해야 함', () async {
      when(
        mockDio.post(
          '/api/friendships/uuid-1/block',
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
            path: '/api/friendships/uuid-1/block',
          ),
        ),
      );

      final result = await service.blockFriend('uuid-1');
      expect(result, isTrue);
    });
  });

  group('deleteFriend', () {
    test('성공 시 true를 반환해야 함', () async {
      when(
        mockDio.delete(
          '/api/friendships/uuid-1',
          options: anyNamed('options'),
        ),
        ).thenAnswer(
        (_) async => Response(
          data: {
            'imhereResponseCode': 'SUCCESS',
            'message': 'OK',
            'data': null,
          },
          statusCode: 204,
          requestOptions: RequestOptions(
            path: '/api/friendships/uuid-1',
          ),
        ),
      );

      final result = await service.deleteFriend('uuid-1');
      expect(result, isTrue);
    });
  });
}
