import 'package:iamhere/feature/friend/service/dto/create_friend_request_dto.dart';
import 'package:iamhere/feature/friend/service/dto/create_friend_request_response_dto.dart';
import 'package:iamhere/feature/friend/service/dto/friend_relationship_response_dto.dart';
import 'package:iamhere/feature/friend/service/dto/received_friend_request_detail_dto.dart';
import 'package:iamhere/feature/friend/service/dto/received_friend_request_response_dto.dart';

abstract class FriendRequestServiceInterface {
  Future<CreateFriendRequestResponseDto?> sendRequest(
      CreateFriendRequestDto request);
  Future<List<ReceivedFriendRequestResponseDto>> fetchReceivedRequests();
  Future<ReceivedFriendRequestDetailDto?> fetchRequestDetail(int requestId);
  Future<FriendRelationshipResponseDto?> acceptRequest(int requestId);
  Future<bool> rejectRequest(int requestId);
}
