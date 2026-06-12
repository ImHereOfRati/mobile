import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/common/base/api_response/api_response_parser.dart';

void main() {
  group('ApiResponseParser', () {
    test('parseObject는 단건 객체 응답을 파싱한다', () {
      final response = ApiResponseParser.parseObject<String>({
        'imhereResponseCode': 'SUCCESS',
        'message': 'OK',
        'data': {'value': 'hello'},
      }, (json) => json['value'] as String);

      expect(response.imhereResponseCode, 'SUCCESS');
      expect(response.message, 'OK');
      expect(response.data, 'hello');
    });

    test('parseList는 raw list 응답을 파싱한다', () {
      final response = ApiResponseParser.parseList<String>({
        'imhereResponseCode': 'SUCCESS',
        'message': 'OK',
        'data': [
          {'value': 'a'},
          {'value': 'b'},
        ],
      }, (json) => json['value'] as String);

      expect(response.data, ['a', 'b']);
    });

    test('parseSlice는 slice 응답을 파싱한다', () {
      final response = ApiResponseParser.parseSlice<String>({
        'imhereResponseCode': 'SUCCESS',
        'message': 'OK',
        'data': {
          'content': [
            {'value': 'a'},
            {'value': 'b'},
          ],
          'hasNext': true,
        },
      }, (json) => json['value'] as String);

      expect(response.data?.content, ['a', 'b']);
      expect(response.data?.hasNext, isTrue);
    });

    test('parseVoid는 data null 응답을 파싱한다', () {
      final dynamic response = ApiResponseParser.parseVoid({
        'imhereResponseCode': 'SUCCESS',
        'message': 'OK',
        'data': null,
      });

      expect(response.imhereResponseCode, 'SUCCESS');
      expect(response.data, isNull);
    });

    test('parseList는 data가 리스트가 아니면 예외를 던진다', () {
      expect(
        () => ApiResponseParser.parseList<String>({
          'imhereResponseCode': 'SUCCESS',
          'message': 'OK',
          'data': {'value': 'a'},
        }, (json) => json['value'] as String),
        throwsFormatException,
      );
    });
  });
}
