import 'package:iamhere/core/di/di_setup.dart';
import 'package:iamhere/feature/friend/service/dto/create_friend_request_dto.dart';
import 'package:iamhere/feature/friend/service/dto/received_friend_request_response_dto.dart';
import 'package:iamhere/feature/friend/service/friend_request_service_interface.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'friend_request_view_model.g.dart';

@riverpod
class FriendRequestViewModel extends _$FriendRequestViewModel {
  late final FriendRequestServiceInterface _service;

  @override
  Future<List<ReceivedFriendRequestResponseDto>> build() async {
    _service = getIt<FriendRequestServiceInterface>();
    return _service.fetchReceivedRequests();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.fetchReceivedRequests());
  }

  Future<bool> sendRequest({
    required String receiverId,
    required String receiverEmail,
    required String message,
  }) async {
    final result = await _service.sendRequest(CreateFriendRequestDto(
      receiverId: receiverId,
      receiverEmail: receiverEmail,
      message: message,
    ));
    return result != null;
  }

  Future<bool> acceptRequest(int requestId) async {
    final result = await _service.acceptRequest(requestId);
    if (result != null) {
      await refresh();
      return true;
    }
    return false;
  }

  Future<bool> rejectRequest(int requestId) async {
    final result = await _service.rejectRequest(requestId);
    if (result) await refresh();
    return result;
  }
}
