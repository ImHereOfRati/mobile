import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/common/base/result/result.dart';
import 'package:iamhere/feature/geofence/service/sms_service.dart';

class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter(this._responses);

  final Map<String, ResponseBody> _responses;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final response = _responses[options.path];
    if (response == null) {
      throw StateError('No fake response for ${options.path}');
    }
    return response;
  }

  @override
  void close({bool force = false}) {}
}

Dio _buildDio(Map<String, ResponseBody> responses) {
  final dio = Dio();
  dio.httpClientAdapter = _FakeHttpClientAdapter(responses);
  return dio;
}

ResponseBody _successBody(int statusCode) {
  return ResponseBody.fromString(
    jsonEncode({
      'imhereResponseCode': 'SUCCESS',
      'message': '알림이 발송 큐에 등록되었습니다.',
      'data': null,
    }),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  test('SMS 단건은 2xx 응답이면 성공으로 처리해야 함', () async {
    final service = SmsService(
      _buildDio({'/api/notifications': _successBody(200)}),
    );

    final result = await service.sendSms(
      phoneNumbers: ['010-1234-5678'],
      body: '안녕하세요! 집 (서울 강남구)에 도착했습니다.',
      location: '집 (서울 강남구)',
      type: 'ARRIVAL',
    );

    expect(result, isA<Success<void>>());
  });

  test('SMS 다건도 2xx 응답이면 성공으로 처리해야 함', () async {
    final service = SmsService(
      _buildDio({'/api/notifications/batch': _successBody(204)}),
    );

    final result = await service.sendSms(
      phoneNumbers: ['010-1234-5678', '010-8765-4321'],
      body: '안녕하세요! 집 (서울 강남구)에 도착했습니다.',
      location: '집 (서울 강남구)',
      type: 'ARRIVAL',
    );

    expect(result, isA<Success<void>>());
  });
}
