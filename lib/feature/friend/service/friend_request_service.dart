import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:iamhere/core/dio/api_config.dart';
import 'package:iamhere/feature/friend/service/dto/create_friend_request_dto.dart';
import 'package:iamhere/feature/friend/service/dto/create_friend_request_response_dto.dart';
import 'package:iamhere/feature/friend/service/dto/friend_relationship_response_dto.dart';
import 'package:iamhere/feature/friend/service/dto/received_friend_request_detail_dto.dart';
import 'package:iamhere/feature/friend/service/dto/received_friend_request_response_dto.dart';
import 'package:iamhere/feature/friend/service/friend_request_service_interface.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: FriendRequestServiceInterface)
class FriendRequestService implements FriendRequestServiceInterface {
  final Dio _dio;

  FriendRequestService({required Dio dio}) : _dio = dio;

  @override
  Future<CreateFriendRequestResponseDto?> sendRequest(
      CreateFriendRequestDto request) async {
    try {
      final response = await _dio.post(
        ApiConfig.friendRequestPath,
        data: request.toJson(),
        options: ApiConfig.authOptions,
      );

      if (response.statusCode == 200) {
        final body = response.data;
        final data = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
        if (data is Map<String, dynamic>) {
          return CreateFriendRequestResponseDto.fromJson(data);
        }
      }
      return null;
    } on DioException catch (e) {
      debugPrint('친구 요청 전송 실패: ${e.message}');
      return null;
    }
  }

  @override
  Future<List<ReceivedFriendRequestResponseDto>> fetchReceivedRequests() async {
    try {
      final response = await _dio.get(
        ApiConfig.friendRequestPath,
        options: ApiConfig.authOptions,
      );

      if (response.statusCode == 200) {
        final body = response.data;
        final data = body is Map<String, dynamic> ? body['data'] : body;

        if (data is List) {
          return data
              .map((e) => ReceivedFriendRequestResponseDto.fromJson(
                  e as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } on DioException catch (e) {
      debugPrint('받은 친구 요청 조회 실패: ${e.message}');
      return [];
    }
  }

  @override
  Future<ReceivedFriendRequestDetailDto?> fetchRequestDetail(
      int requestId) async {
    try {
      final response = await _dio.get(
        ApiConfig.friendRequestDetailPath(requestId),
        options: ApiConfig.authOptions,
      );

      if (response.statusCode == 200) {
        final body = response.data;
        final data = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
        if (data is Map<String, dynamic>) {
          return ReceivedFriendRequestDetailDto.fromJson(data);
        }
      }
      return null;
    } on DioException catch (e) {
      debugPrint('친구 요청 상세 조회 실패: ${e.message}');
      return null;
    }
  }

  @override
  Future<FriendRelationshipResponseDto?> acceptRequest(int requestId) async {
    try {
      final response = await _dio.post(
        ApiConfig.friendRequestAcceptPath(requestId),
        options: ApiConfig.authOptions,
      );

      if (response.statusCode == 200) {
        final body = response.data;
        final data = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
        if (data is Map<String, dynamic>) {
          return FriendRelationshipResponseDto.fromJson(data);
        }
      }
      return null;
    } on DioException catch (e) {
      debugPrint('친구 요청 수락 실패: ${e.message}');
      return null;
    }
  }

  @override
  Future<bool> rejectRequest(int requestId) async {
    try {
      final response = await _dio.post(
        ApiConfig.friendRequestRejectPath(requestId),
        options: ApiConfig.authOptions,
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      debugPrint('친구 요청 거절 실패: ${e.message}');
      return false;
    }
  }
}
