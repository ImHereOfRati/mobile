import 'package:iamhere/feature/friend/repository/contact_entity.dart';
import 'package:iamhere/feature/friend/repository/contact_repository.dart';
import 'package:iamhere/shell/bridge/device_contact_reader.dart';

class DeviceContactSyncService {
  final DeviceContactReader _reader;
  final ContactRepository _contacts;

  const DeviceContactSyncService(this._reader, this._contacts);

  Future<List<Map<String, Object?>>> load() async {
    final deviceContacts = await _reader.read();
    final savedContacts = await _contacts.findAll();
    final byNumber = <String, ContactEntity>{
      for (final contact in savedContacts) _normalise(contact.number): contact,
    };
    final result = <Map<String, Object?>>[];

    for (final deviceContact in deviceContacts) {
      final phoneNumbers = (deviceContact['phoneNumbers'] as List? ?? const [])
          .map((value) => value.toString())
          .where((value) => _normalise(value).isNotEmpty)
          .toList();
      if (phoneNumbers.isEmpty) continue;

      final primaryNumber = phoneNumbers.first;
      final key = _normalise(primaryNumber);
      var saved = byNumber[key];
      if (saved == null) {
        saved = await _contacts.save(
          ContactEntity(
            name: deviceContact['displayName']?.toString() ?? '',
            number: primaryNumber,
          ),
        );
        byNumber[key] = saved;
      }

      result.add({
        'id': saved.id.toString(),
        'displayName': deviceContact['displayName']?.toString() ?? saved.name,
        'phoneNumbers': phoneNumbers,
      });
    }
    return result;
  }

  static String _normalise(String value) =>
      value.replaceAll(RegExp(r'[^\d]'), '');
}
