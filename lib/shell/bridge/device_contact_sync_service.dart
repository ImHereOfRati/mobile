import 'package:iamhere/feature/friend/repository/contact_entity.dart';
import 'package:iamhere/feature/friend/repository/contact_repository.dart';
import 'package:iamhere/shell/bridge/device_contact_reader.dart';

class DeviceContactSyncService {
  final DeviceContactReader _reader;
  final ContactRepository _contacts;

  const DeviceContactSyncService(this._reader, this._contacts);

  Future<List<Map<String, Object?>>> load() async {
    final savedContacts = await _contacts.findAll();
    final result = <Map<String, Object?>>[];

    // Only contacts explicitly selected through the native picker are shown.
    // Do not bulk-import the device address book here: getDeviceContacts is
    // used by the friend list and must represent ImHere-selected contacts.
    for (final contact in savedContacts.where((contact) => !contact.hidden)) {
      final number = _normalise(contact.number);
      if (number.isEmpty) continue;
      result.add({
        'id': contact.id?.toString() ?? '',
        'displayName': contact.name,
        'phoneNumbers': [contact.number],
      });
    }
    return result;
  }

  Future<Map<String, Object?>?> pick() async {
    final contact = await _reader.pick();
    if (contact == null) return null;
    final numbers = (contact['phoneNumbers'] as List? ?? const [])
        .map((value) => value.toString())
        .where((value) => _normalise(value).isNotEmpty)
        .toList();
    if (numbers.isEmpty) return null;

    final primaryNumber = numbers.first;
    final saved = (await _contacts.findAll()).firstWhere(
      (item) => _normalise(item.number) == _normalise(primaryNumber),
      orElse: () => ContactEntity(
        name: contact['displayName']?.toString() ?? '',
        number: primaryNumber,
      ),
    );
    late final ContactEntity persisted;
    if (saved.hidden) {
      persisted = saved.copyWith(hidden: false);
      await _contacts.update(persisted);
    } else if (saved.id == null) {
      persisted = await _contacts.save(saved);
    } else {
      persisted = saved;
    }
    return {
      'id': persisted.id.toString(),
      'displayName': persisted.name,
      'phoneNumbers': numbers,
    };
  }

  static String _normalise(String value) =>
      value.replaceAll(RegExp(r'[^\d]'), '');
}
