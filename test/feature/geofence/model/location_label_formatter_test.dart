import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/geofence/model/event_type.dart';
import 'package:iamhere/feature/geofence/model/location_label_formatter.dart';

void main() {
  test(
    'composePlaceName uses title first, then reverse geocode, then coords',
    () {
      expect(
        composePlaceName(
          title: '우리집',
          reverseGeocode: '서울 강남구',
          latitude: 37.5,
          longitude: 127.0,
        ),
        '우리집',
      );

      expect(
        composePlaceName(
          title: '',
          reverseGeocode: '서울 강남구',
          latitude: 37.5,
          longitude: 127.0,
        ),
        '서울 강남구',
      );

      expect(
        composePlaceName(
          title: '',
          reverseGeocode: '',
          latitude: 37.5,
          longitude: 127.0,
        ),
        '37.5000, 127.0000',
      );
    },
  );

  test('composeFullLocation avoids duplicate address text', () {
    expect(composeFullLocation('우리집', '서울 강남구'), '우리집 (서울 강남구)');
    expect(composeFullLocation('서울 강남구', '서울 강남구'), '서울 강남구');
  });

  test('composeSmsBody matches the server SMS format', () {
    expect(
      composeSmsBody(
        eventType: EventType.arrival,
        message: '',
        location: '우리집 (서울 강남구)',
      ),
      '[ImHere]\n우리집 (서울 강남구) 도착',
    );
  });

  test('composeSmsPreview supports WEB sender preview', () {
    expect(
      composeSmsPreview(
        eventType: EventType.departure,
        message: '',
        location: '우리집 (서울 강남구)',
      ),
      '[WEB 발신]\n[ImHere]\n우리집 (서울 강남구) 출발',
    );
  });
}
