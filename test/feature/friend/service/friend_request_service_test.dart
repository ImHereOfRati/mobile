import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/friend/service/dto/create_friend_request_dto.dart';
import 'package:iamhere/feature/friend/service/friend_request_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'friend_request_service_test.mocks.dart';

@GenerateMocks([Dio])
void main() {
  late FriendRequestService service;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    service = FriendRequestService(dio: mockDio);
  });

  group('sendRequest', () {
    test('성공 시 생성된 요청 ID를 반환해야 함', () async {
      final request = CreateFriendRequestDto(
        targetId: 'uuid-receiver',
        receiverEmail: 'receiver@test.com',
        message: '안녕하세요! 친구 요청 드립니다.',
      );

      when(
        mockDio.post(
          '/api/friends/requests',
          data: anyNamed('data'),
          options: anyNamed('options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'imhereResponseCode': 'SUCCESS',
            'message': 'OK',
            'data': {'friendRequestId': 'uuid-request'},
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/friends/requests'),
        ),
      );

      final result = await service.sendRequest(request);

      expect(result, isNotNull);
      expect(result!.friendRequestId, 'uuid-request');
    });

    test('실패 시 null을 반환해야 함', () async {
      final request = CreateFriendRequestDto(
        targetId: 'uuid-receiver',
        receiverEmail: 'receiver@test.com',
        message: '안녕하세요! 친구 요청 드립니다.',
      );

      when(
        mockDio.post(
          '/api/friends/requests',
          data: anyNamed('data'),
          options: anyNamed('options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/friends/requests'),
        ),
      );

      final result = await service.sendRequest(request);
      expect(result, isNull);
    });
  });

  group('fetchReceivedRequests', () {
    test('성공 시 받은 요청 목록을 반환해야 함', () async {
      when(
        mockDio.get(
          '/api/friends/requests',
          queryParameters: const {'type': 'RECEIVED'},
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
                  'id': 'request-1',
                  'requester': {
                    'id': 'sender-id',
                    'email': 'sender@test.com',
                    'nickname': '보낸사람',
                    'oAuth2Provider': 'KAKAO',
                  },
                  'receiver': {
                    'id': 'receiver-id',
                    'email': 'receiver@test.com',
                    'nickname': '받는사람',
                    'oAuth2Provider': 'KAKAO',
                  },
                  'message': '보낸 요청 목록용 메시지',
                  'createdAt': '2026-06-11T20:51:35.552912939',
                  'updatedAt': '2026-06-11T20:51:35.552912939',
                },
              ],
              'hasNext': false,
            },
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/friends/requests'),
        ),
      );

      final result = await service.fetchReceivedRequests();

      expect(result.length, 1);
      expect(result[0].friendRequestId, 'request-1');
      expect(result[0].requesterNickname, '보낸사람');
    });
  });

  group('fetchRequestDetail', () {
    test('성공 시 상세 정보를 반환해야 함', () async {
      when(
        mockDio.get(
          '/api/friends/requests/request-1',
          options: anyNamed('options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'imhereResponseCode': 'SUCCESS',
            'message': 'OK',
            'data': {
              'id': 'request-1',
              'requester': {
                'id': 'sender-id',
                'email': 'sender@test.com',
                'nickname': '보낸사람',
                'oAuth2Provider': 'KAKAO',
              },
              'receiver': {
                'id': 'receiver-id',
                'email': 'receiver@test.com',
                'nickname': '받는사람',
                'oAuth2Provider': 'KAKAO',
              },
              'message': '안녕하세요! 친구 해요!',
              'createdAt': '2026-06-11T20:51:36.192650026',
              'updatedAt': '2026-06-11T20:51:36.192650026',
            },
          },
          statusCode: 200,
          requestOptions: RequestOptions(
            path: '/api/friends/requests/request-1',
          ),
        ),
      );

      final result = await service.fetchRequestDetail('request-1');

      expect(result, isNotNull);
      expect(result!.message, '안녕하세요! 친구 해요!');
    });
  });

  group('acceptRequest', () {
    test('성공 시 친구 관계 정보를 반환해야 함', () async {
      when(
        mockDio.post(
          '/api/friends/requests/request-1/accept',
          options: anyNamed('options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'imhereResponseCode': 'SUCCESS',
            'message': 'OK',
            'data': {
              'id': 'uuid-new',
              'owner': {
                'id': 'receiver-id',
                'email': 'receiver@test.com',
                'nickname': '받는사람',
                'oAuth2Provider': 'KAKAO',
              },
              'friend': {
                'id': 'sender-id',
                'email': 'sender@test.com',
                'nickname': '보낸사람',
                'oAuth2Provider': 'KAKAO',
              },
              'friendAlias': '보낸사람',
              'createdAt': '2026-06-11T20:51:35.809056333',
              'updatedAt': '2026-06-11T20:51:35.809056333',
            },
          },
          statusCode: 200,
          requestOptions: RequestOptions(
            path: '/api/friends/requests/request-1/accept',
          ),
        ),
      );

      final result = await service.acceptRequest('request-1');

      expect(result, isNotNull);
      expect(result!.friendRelationshipId, 'uuid-new');
    });
  });

  group('rejectRequest', () {
    test('성공 시 true를 반환해야 함', () async {
      when(
        mockDio.post(
          '/api/friends/requests/request-1/reject',
          options: anyNamed('options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'imhereResponseCode': 'SUCCESS',
            'message': 'OK',
            'data': {
              'id': 'restriction-1',
              'restrictor': {
                'id': 'receiver-id',
                'email': 'receiver@test.com',
                'nickname': '받는사람',
                'oAuth2Provider': 'KAKAO',
              },
              'restricted': {
                'id': 'sender-id',
                'email': 'sender@test.com',
                'nickname': '보낸사람',
                'oAuth2Provider': 'KAKAO',
              },
              'type': 'REJECT',
              'createdAt': '2026-06-11T20:51:36.325685306',
              'updatedAt': '2026-06-11T20:51:36.325685306',
              'expiredAt': '2026-07-11T20:51:36.323990396',
            },
          },
          statusCode: 200,
          requestOptions: RequestOptions(
            path: '/api/friends/requests/request-1/reject',
          ),
        ),
      );

      final result = await service.rejectRequest('request-1');
      expect(result, isTrue);
    });
  });
}
