import 'package:iamhere/feature/friend/model/repository/contact_entity.dart';
import 'package:iamhere/feature/friend/model/service/device_contact_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'device_contact_provider.g.dart';

@riverpod
Future<ContactEntity?> deviceContact(
  Ref ref,
  DeviceContactService service,
  int id,
) {
  return service.find(id);
}
