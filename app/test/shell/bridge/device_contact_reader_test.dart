import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/shell/bridge/device_contact_reader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.iamhere.app/contacts');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('maps the native contact channel payload to the bridge shape', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'getDeviceContacts');
          return [
            {
              'id': 3,
              'displayName': '친구',
              'phoneNumbers': ['010-1234-5678'],
            },
          ];
        });

    expect(await const DeviceContactReader().read(), [
      {
        'id': '3',
        'displayName': '친구',
        'phoneNumbers': ['010-1234-5678'],
      },
    ]);
  });
}
