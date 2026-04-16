import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/core/dio/properties/api_config.dart';
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
        mockDio.get(ApiConfig.friendListPath, options: anyNamed('options')),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'data': [
              {
                'friendRelationshipId': 'uuid-1',
                'friendEmail': 'a@test.com',
                'friendAlias': '친구A',
              },
              {
                'friendRelationshipId': 'uuid-2',
                'friendEmail': 'b@test.com',
                'friendAlias': '친구B',
              },
            ],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ApiConfig.friendListPath),
        ),
      );

      final result = await service.fetchFriendList();

      expect(result.length, 2);
      expect(result[0].friendAlias, '친구A');
      expect(result[1].friendRelationshipId, 'uuid-2');
    });

    test('실패 시 빈 리스트를 반환해야 함', () async {
      when(
        mockDio.get(ApiConfig.friendListPath, options: anyNamed('options')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ApiConfig.friendListPath),
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
        newFriendAlias: '새별명',
      );

      when(
        mockDio.post(
          ApiConfig.friendAliasPath,
          data: anyNamed('data'),
          options: anyNamed('options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'data': {
              'friendRelationshipId': 'uuid-1',
              'friendEmail': 'a@test.com',
              'friendAlias': '새별명',
            },
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ApiConfig.friendAliasPath),
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
          ApiConfig.friendBlockPath('uuid-1'),
          options: anyNamed('options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {'status': 200, 'message': 'success'},
          statusCode: 200,
          requestOptions: RequestOptions(
            path: ApiConfig.friendBlockPath('uuid-1'),
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
          ApiConfig.friendDeletePath('uuid-1'),
          options: anyNamed('options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {'status': 200, 'message': 'success'},
          statusCode: 200,
          requestOptions: RequestOptions(
            path: ApiConfig.friendDeletePath('uuid-1'),
          ),
        ),
      );

      final result = await service.deleteFriend('uuid-1');
      expect(result, isTrue);
    });
  });
}
