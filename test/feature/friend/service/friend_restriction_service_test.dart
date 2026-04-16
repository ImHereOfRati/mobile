import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/core/dio/api_config.dart';
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
      when(mockDio.get(
        ApiConfig.friendRestrictionPath,
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
            data: {
              'data': [
                {
                  'friendRestrictionId': 1,
                  'targetEmail': 'blocked@test.com',
                  'targetNickname': '차단된유저',
                  'restrictionType': 'BLOCK',
                  'createdAt': '2026-04-15T10:00:00',
                },
              ]
            },
            statusCode: 200,
            requestOptions:
                RequestOptions(path: ApiConfig.friendRestrictionPath),
          ));

      final result = await service.fetchRestrictions();

      expect(result.length, 1);
      expect(result[0].targetNickname, '차단된유저');
      expect(result[0].restrictionType, 'BLOCK');
    });

    test('실패 시 빈 리스트를 반환해야 함', () async {
      when(mockDio.get(
        ApiConfig.friendRestrictionPath,
        options: anyNamed('options'),
      )).thenThrow(DioException(
        requestOptions:
            RequestOptions(path: ApiConfig.friendRestrictionPath),
      ));

      final result = await service.fetchRestrictions();
      expect(result, isEmpty);
    });
  });

  group('deleteRestriction', () {
    test('성공 시 해제된 대상 이메일을 반환해야 함', () async {
      when(mockDio.delete(
        ApiConfig.friendRestrictionDeletePath(1),
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
            data: {
              'data': {'targetEmail': 'unblocked@test.com'}
            },
            statusCode: 201,
            requestOptions: RequestOptions(
                path: ApiConfig.friendRestrictionDeletePath(1)),
          ));

      final result = await service.deleteRestriction(1);

      expect(result, isNotNull);
      expect(result!.targetEmail, 'unblocked@test.com');
    });

    test('실패 시 null을 반환해야 함', () async {
      when(mockDio.delete(
        ApiConfig.friendRestrictionDeletePath(1),
        options: anyNamed('options'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(
            path: ApiConfig.friendRestrictionDeletePath(1)),
      ));

      final result = await service.deleteRestriction(1);
      expect(result, isNull);
    });
  });
}
