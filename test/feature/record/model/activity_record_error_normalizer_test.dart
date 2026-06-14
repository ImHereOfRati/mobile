import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/record/model/activity_record_error_normalizer.dart';

void main() {
  test('timeout 오류를 사용자 친화 문구로 정규화한다', () {
    final result = ActivityRecordErrorNormalizer.normalize(
      'DioException [connectionTimeout]: timeout',
    );

    expect(result, '응답 시간이 초과되었습니다. 잠시 후 다시 시도합니다.');
  });

  test('알 수 없는 오류를 일반 안내 문구로 정규화한다', () {
    final result = ActivityRecordErrorNormalizer.normalize('weird failure');

    expect(result, '알림 전송 중 오류가 발생했습니다.');
  });
}
