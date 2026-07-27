import 'package:flutter/services.dart';

class DeviceContactReader {
  static const _channel = MethodChannel('com.iamhere.app/contacts');

  const DeviceContactReader();

  Future<List<Map<String, Object?>>> read() async {
    final raw = await _channel.invokeListMethod<Object?>('getDeviceContacts');
    if (raw == null) return const [];
    return raw.map((item) {
      if (item is! Map) {
        throw const FormatException('Invalid native contact payload.');
      }
      final map = item.map((key, value) => MapEntry(key.toString(), value));
      return <String, Object?>{
        'id': map['id']?.toString() ?? '',
        'displayName': map['displayName']?.toString() ?? '',
        'phoneNumbers': (map['phoneNumbers'] as List? ?? const [])
            .map((value) => value.toString())
            .toList(),
      };
    }).toList();
  }
}
