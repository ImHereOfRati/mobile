import 'package:dio/dio.dart';
import 'package:iamhere/common/base/api_response/api_response_parser.dart';
import 'package:iamhere/feature/friend/service/dto/create_friend_request_dto.dart';
import 'package:iamhere/feature/friend/service/dto/create_friend_request_response_dto.dart';
import 'package:iamhere/feature/friend/service/dto/friend_relationship_response_dto.dart';
import 'package:iamhere/feature/friend/service/dto/received_friend_request_detail_dto.dart';
import 'package:iamhere/feature/friend/service/dto/received_friend_request_response_dto.dart';
import 'package:iamhere/feature/friend/service/friend_request_service_interface.dart';
import 'package:iamhere/common/util/app_logger.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: FriendRequestServiceInterface)
class FriendRequestService implements FriendRequestServiceInterface {
  static const String _friendRequestPath = '/api/friends/requests';
  static String _friendRequestDetailPath(String id) =>
      '/api/friends/requests/$id';
  static String _friendRequestAcceptPath(String id) =>
      '/api/friends/requests/$id/accept';
  static String _friendRequestRejectPath(String id) =>
      '/api/friends/requests/$id/reject';

  final Dio _dio;

  FriendRequestService({required Dio dio}) : _dio = dio;

  @override
  Future<CreateFriendRequestResponseDto?> sendRequest(
    CreateFriendRequestDto request,
  ) async {
    try {
      final response = await _dio.post(
        _friendRequestPath,
        data: request.toJson(),
        options: Options(extra: const {'requiresAuthentication': true}),
      );

      if (response.statusCode == 200) {
        return ApiResponseParser.parseObject<CreateFriendRequestResponseDto>(
          response.data,
          CreateFriendRequestResponseDto.fromJson,
        ).data;
      }
      return null;
    } on DioException catch (e) {
      AppLogger.error('친구 요청 전송 실패: ${e.message}');
      return null;
    }
  }

  @override
  Future<List<ReceivedFriendRequestResponseDto>> fetchReceivedRequests() async {
    try {
      final response = await _dio.get(
        _friendRequestPath,
        queryParameters: const {'type': 'RECEIVED'},
        options: Options(extra: const {'requiresAuthentication': true}),
      );

      if (response.statusCode == 200) {
        return ApiResponseParser.parseSlice<ReceivedFriendRequestResponseDto>(
              response.data,
              ReceivedFriendRequestResponseDto.fromJson,
            ).data?.content ??
            const [];
      }
      return [];
    } on DioException catch (e) {
      AppLogger.error('받은 친구 요청 조회 실패: ${e.message}');
      return [];
    }
  }

  @override
  Future<ReceivedFriendRequestDetailDto?> fetchRequestDetail(
    String requestId,
  ) async {
    try {
      final response = await _dio.get(
        _friendRequestDetailPath(requestId),
        options: Options(extra: const {'requiresAuthentication': true}),
      );

      if (response.statusCode == 200) {
        return ApiResponseParser.parseObject<ReceivedFriendRequestDetailDto>(
          response.data,
          ReceivedFriendRequestDetailDto.fromJson,
        ).data;
      }
      return null;
    } on DioException catch (e) {
      AppLogger.error('친구 요청 상세 조회 실패: ${e.message}');
      return null;
    }
  }

  @override
  Future<FriendRelationshipResponseDto?> acceptRequest(String requestId) async {
    try {
      final response = await _dio.post(
        _friendRequestAcceptPath(requestId),
        options: Options(extra: const {'requiresAuthentication': true}),
      );

      if (response.statusCode == 200) {
        return ApiResponseParser.parseObject<FriendRelationshipResponseDto>(
          response.data,
          FriendRelationshipResponseDto.fromJson,
        ).data;
      }
      return null;
    } on DioException catch (e) {
      AppLogger.error('친구 요청 수락 실패: ${e.message}');
      return null;
    }
  }

  @override
  Future<bool> rejectRequest(String requestId) async {
    try {
      final response = await _dio.post(
        _friendRequestRejectPath(requestId),
        options: Options(extra: const {'requiresAuthentication': true}),
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      AppLogger.error('친구 요청 거절 실패: ${e.message}');
      return false;
    }
  }
}
