import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/core/dio/properties/api_config.dart';
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
        receiverId: 'uuid-receiver',
        receiverEmail: 'receiver@test.com',
        message: '안녕하세요! 친구 요청 드립니다.',
      );

      when(
        mockDio.post(
          ApiConfig.friendRequestPath,
          data: anyNamed('data'),
          options: anyNamed('options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'data': {'friendRequestId': 42},
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ApiConfig.friendRequestPath),
        ),
      );

      final result = await service.sendRequest(request);

      expect(result, isNotNull);
      expect(result!.friendRequestId, 42);
    });

    test('실패 시 null을 반환해야 함', () async {
      final request = CreateFriendRequestDto(
        receiverId: 'uuid-receiver',
        receiverEmail: 'receiver@test.com',
        message: '안녕하세요! 친구 요청 드립니다.',
      );

      when(
        mockDio.post(
          ApiConfig.friendRequestPath,
          data: anyNamed('data'),
          options: anyNamed('options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ApiConfig.friendRequestPath),
        ),
      );

      final result = await service.sendRequest(request);
      expect(result, isNull);
    });
  });

  group('fetchReceivedRequests', () {
    test('성공 시 받은 요청 목록을 반환해야 함', () async {
      when(
        mockDio.get(ApiConfig.friendRequestPath, options: anyNamed('options')),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'data': [
              {
                'friendRequestId': 1,
                'requesterEmail': 'sender@test.com',
                'requesterNickname': '보낸사람',
              },
            ],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ApiConfig.friendRequestPath),
        ),
      );

      final result = await service.fetchReceivedRequests();

      expect(result.length, 1);
      expect(result[0].friendRequestId, 1);
      expect(result[0].requesterNickname, '보낸사람');
    });
  });

  group('fetchRequestDetail', () {
    test('성공 시 상세 정보를 반환해야 함', () async {
      when(
        mockDio.get(
          ApiConfig.friendRequestDetailPath(1),
          options: anyNamed('options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'data': {
              'friendRequestId': 1,
              'requesterEmail': 'sender@test.com',
              'requesterNickname': '보낸사람',
              'message': '안녕하세요! 친구 해요!',
            },
          },
          statusCode: 200,
          requestOptions: RequestOptions(
            path: ApiConfig.friendRequestDetailPath(1),
          ),
        ),
      );

      final result = await service.fetchRequestDetail(1);

      expect(result, isNotNull);
      expect(result!.message, '안녕하세요! 친구 해요!');
    });
  });

  group('acceptRequest', () {
    test('성공 시 친구 관계 정보를 반환해야 함', () async {
      when(
        mockDio.post(
          ApiConfig.friendRequestAcceptPath(1),
          options: anyNamed('options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'data': {
              'friendRelationshipId': 'uuid-new',
              'friendEmail': 'sender@test.com',
              'friendAlias': '보낸사람',
            },
          },
          statusCode: 200,
          requestOptions: RequestOptions(
            path: ApiConfig.friendRequestAcceptPath(1),
          ),
        ),
      );

      final result = await service.acceptRequest(1);

      expect(result, isNotNull);
      expect(result!.friendRelationshipId, 'uuid-new');
    });
  });

  group('rejectRequest', () {
    test('성공 시 true를 반환해야 함', () async {
      when(
        mockDio.post(
          ApiConfig.friendRequestRejectPath(1),
          options: anyNamed('options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {'status': 200, 'message': 'success'},
          statusCode: 200,
          requestOptions: RequestOptions(
            path: ApiConfig.friendRequestRejectPath(1),
          ),
        ),
      );

      final result = await service.rejectRequest(1);
      expect(result, isTrue);
    });
  });
}
