import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/friend/repository/contact_entity.dart';
import 'package:iamhere/feature/friend/repository/contact_repository.dart';
import 'package:iamhere/shell/bridge/device_contact_reader.dart';
import 'package:iamhere/shell/bridge/device_contact_sync_service.dart';

void main() {
  test('returns local database ids for background SMS resolution', () async {
    final repository = _Contacts([
      ContactEntity(id: 7, name: '기존 연락처', number: '010-1234-5678'),
    ]);
    final service = DeviceContactSyncService(
      const _Reader([
        {
          'id': 'os-contact-1',
          'displayName': '기존 연락처',
          'phoneNumbers': ['01012345678'],
        },
        {
          'id': 'os-contact-2',
          'displayName': '새 연락처',
          'phoneNumbers': ['010-9999-0000'],
        },
      ]),
      repository,
    );

    final result = await service.load();

    expect(result, [
      {
        'id': '7',
        'displayName': '기존 연락처',
        'phoneNumbers': ['010-1234-5678'],
      },
    ]);
    expect((await repository.findAll()).map((item) => item.id), [7]);
  });

  test('keeps saved local contacts when native contact access fails', () async {
    final repository = _Contacts([
      ContactEntity(id: 11, name: '로컬 친구', number: '010-1111-2222'),
    ]);
    final service = DeviceContactSyncService(
      const _FailingReader(),
      repository,
    );

    expect(await service.load(), [
      {
        'id': '11',
        'displayName': '로컬 친구',
        'phoneNumbers': ['010-1111-2222'],
      },
    ]);
  });
}

class _Reader extends DeviceContactReader {
  final List<Map<String, Object?>> values;

  const _Reader(this.values);

  @override
  Future<List<Map<String, Object?>>> read() async => values;
}

class _FailingReader extends DeviceContactReader {
  const _FailingReader();

  @override
  Future<List<Map<String, Object?>>> read() async {
    throw StateError('contacts unavailable');
  }
}

class _Contacts implements ContactRepository {
  final List<ContactEntity> values;

  _Contacts(this.values);

  @override
  Future<List<ContactEntity>> findAll() async => List.of(values);

  @override
  Future<ContactEntity> save(ContactEntity entity) async {
    final saved = entity.copyWith(id: values.length + 7);
    values.add(saved);
    return saved;
  }

  @override
  Future<void> update(ContactEntity entity) async {
    final index = values.indexWhere((item) => item.id == entity.id);
    if (index >= 0) values[index] = entity;
  }

  @override
  Future<void> delete(int id) async {
    values.removeWhere((item) => item.id == id);
  }
}
