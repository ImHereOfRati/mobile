import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/common/base/result/result.dart';

void main() {
  group('Result.when', () {
    test('Success는 success branch만 실행한다', () {
      final result = Success<int>(7);

      final value = result.when(
        success: (data) => data * 2,
        failure: (_) => -1,
      );

      expect(value, 14);
    });

    test('Failure는 failure branch만 실행한다', () {
      final result = Failure<int>('boom');

      final value = result.when(
        success: (_) => -1,
        failure: (message) => message,
      );

      expect(value, 'boom');
    });
  });
}
