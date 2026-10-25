import 'package:iamhere/feature/friend/model/repository/contact_entity.dart';
import 'package:iamhere/feature/friend/model/repository/contact_local_repository.dart';
import 'package:iamhere/feature/friend/model/repository/contact_repository.dart';
import 'package:iamhere/shell/bridge/device_contact_reader.dart';
import 'package:injectable/injectable.dart';

/// 친구 목록에 보이는 기기 연락처. 기기 주소록 전체가 아니라 사용자가 ImHere에서
/// 직접 고른 연락처만 다룬다.
@injectable
class DeviceContactService {
  final ContactRepository _contacts;
  final DeviceContactReader _reader;

  // DI에는 구현체(ContactLocalRepository)만 등록돼 있어 그 타입으로 받는다.
  DeviceContactService(ContactLocalRepository contacts, this._reader)
    : _contacts = contacts;

  Future<List<ContactEntity>> load() async {
    final saved = await _contacts.findAll();
    return saved
        .where(
          (contact) => !contact.hidden && _digits(contact.number).isNotEmpty,
        )
        .toList(growable: false);
  }

  Future<ContactEntity?> find(int id) async {
    final saved = await _contacts.findAll();
    for (final contact in saved) {
      if (contact.id == id && !contact.hidden) return contact;
    }
    return null;
  }

  /// 기기 연락처 선택기를 띄우고, 고른 연락처를 저장해 돌려준다. 취소했거나 전화번호가
  /// 없으면 null.
  Future<ContactEntity?> pick() async {
    final picked = await _reader.pick();
    if (picked == null) return null;
    final numbers = (picked['phoneNumbers'] as List? ?? const [])
        .map((value) => value.toString())
        .where((value) => _digits(value).isNotEmpty)
        .toList();
    if (numbers.isEmpty) return null;

    final number = numbers.first;
    final existing = (await _contacts.findAll())
        .where((item) => _digits(item.number) == _digits(number))
        .firstOrNull;
    if (existing == null) {
      return _contacts.save(
        ContactEntity(
          name: picked['displayName']?.toString() ?? '',
          number: number,
        ),
      );
    }
    if (existing.hidden) {
      final restored = existing.copyWith(hidden: false);
      await _contacts.update(restored);
      return restored;
    }
    return existing;
  }

  Future<ContactEntity> rename(int id, String name) async {
    final existing = await find(id);
    if (existing == null) throw StateError('연락처를 찾을 수 없습니다.');
    final updated = existing.copyWith(name: name);
    await _contacts.update(updated);
    return updated;
  }

  /// 연락처를 지우지 않고 숨긴다. 지오펜스가 연락처 id를 계속 참조하기 때문이다.
  Future<void> hide(int id) async {
    final existing = await find(id);
    if (existing == null) return;
    await _contacts.update(existing.copyWith(hidden: true));
  }

  static String _digits(String value) => value.replaceAll(RegExp(r'[^\d]'), '');
}
