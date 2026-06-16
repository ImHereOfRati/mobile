import 'package:flutter_test/flutter_test.dart';
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

  test('composeSmsBody inserts location into the template', () {
    expect(
        composeSmsBody(
          location: '우리집 (서울 강남구)',
          senderName: '홍길동',
        ),
      '[ImHere]\n우리집 (서울 강남구) 도착\n발신자: 홍길동',
    );
  });

  test('composeSmsPreview includes sender line', () {
    expect(
      composeSmsPreview(
        location: '우리집 (서울 강남구)',
        senderName: '홍길동',
      ),
      '[ImHere]\n우리집 (서울 강남구) 도착\n발신자: 홍길동',
    );
  });
}
