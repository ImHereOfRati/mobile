import 'package:iamhere/core/paging/paged_items.dart';
import 'package:iamhere/feature/record/model/dto/server_notification_dto.dart';
import 'package:iamhere/feature/record/model/repository/server_notification_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class ServerNotificationService {
  final ServerNotificationRepository _repository;

  ServerNotificationService(this._repository);

  /// 한 쪽을 가득 채워 받았으면 더 있을 수 있다고 본다.
  Future<PagedItems<ServerNotificationDto>> load(int page) async {
    final items = await _repository.fetch(page);
    return PagedItems(
      items: items,
      hasNext: items.length == ServerNotificationRepository.pageSize,
    );
  }

  Future<void> markAsRead(int id) => _repository.markAsRead(id);

  /// 지금 바로 알리고 싶을 때 쓰는 수동 도착 알림. 서버가 클라이언트에게
  /// 허용하는 발송 타입은 위치 관련 세 가지뿐이다.
  Future<void> sendArrival(String targetUserId) =>
      _repository.send(type: 'ARRIVAL', targetIds: [targetUserId]);
}
