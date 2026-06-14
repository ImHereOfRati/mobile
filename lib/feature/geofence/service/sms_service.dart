import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:iamhere/common/base/api_response/api_response_parser.dart';
import 'package:iamhere/feature/friend/service/dto/batch_notification_request_dto.dart';
import 'package:iamhere/feature/friend/service/dto/fcm_notification_request_dto.dart';
import 'package:iamhere/common/base/result/result.dart';
import 'package:injectable/injectable.dart';

/// SMS sending service with proper dependency injection and error handling
@lazySingleton
class SmsService {
  static const String _smsNotificationPath = '/api/notifications';
  static const String _smsBatchNotificationPath = '/api/notifications/batch';

  final Dio _dio;

  SmsService(this._dio);

  /// Send SMS to one or more recipients
  /// Returns `Result<void>` indicating success or failure
  Future<Result<void>> sendSms({
    required List<String> phoneNumbers,
    required String body,
    required String location,
    required String type,
  }) async {
    try {
      if (phoneNumbers.isEmpty) {
        return Failure('No phone numbers provided');
      }

      final cleanPhoneNumbers = _extractOnlyNumberFromPhoneNumber(phoneNumbers);

      if (cleanPhoneNumbers.isEmpty) {
        return Failure('No valid phone numbers after cleaning');
      }

      if (cleanPhoneNumbers.length == 1) {
        return await _sendSingleSms(
          phoneNumber: cleanPhoneNumbers[0],
          body: body,
          location: location,
          type: type,
        );
      } else {
        return await _sendMultiSms(
          phoneNumbers: cleanPhoneNumbers,
          body: body,
          location: location,
          type: type,
        );
      }
    } catch (e) {
      log('Error sending SMS: $e');
      return Failure('Error sending SMS: $e');
    }
  }

  /// Extract and clean phone numbers (digits only)
  List<String> _extractOnlyNumberFromPhoneNumber(List<String> phoneNumbers) {
    return phoneNumbers
        .map((phone) => phone.replaceAll(RegExp(r'[^\d]'), ''))
        .where((phone) => phone.isNotEmpty)
        .toList();
  }

  /// Send SMS to a single recipient
  Future<Result<void>> _sendSingleSms({
    required String phoneNumber,
    required String body,
    required String location,
    required String type,
  }) async {
    try {
      final response = await _dio.post(
        _smsNotificationPath,
        data: FcmNotificationRequestDto(
          notificationMethod: 'SMS',
          targetId: phoneNumber,
          type: type,
          extraData: {'body': body, 'location': location},
        ).toJson(),
        options: Options(extra: const {'requiresAuthentication': true}),
      );

      final isSuccess = response.statusCode == 202;

      if (!isSuccess) {
        return Failure('SMS send failed with status ${response.statusCode}');
      }

      ApiResponseParser.parseVoid(response.data);

      return Success(null);
    } catch (e) {
      log('Error sending single SMS: $e');
      return Failure('Error sending SMS: $e');
    }
  }

  /// Send SMS to multiple recipients
  Future<Result<void>> _sendMultiSms({
    required List<String> phoneNumbers,
    required String body,
    required String location,
    required String type,
  }) async {
    try {
      final response = await _dio.post(
        _smsBatchNotificationPath,
        data: BatchNotificationRequestDto(
          notificationMethod: 'SMS',
          targetIds: phoneNumbers,
          type: type,
          extraData: {'body': body, 'location': location},
        ).toJson(),
        options: Options(extra: const {'requiresAuthentication': true}),
      );

      final isSuccess = response.statusCode == 202;

      if (!isSuccess) {
        return Failure('SMS send failed with status ${response.statusCode}');
      }

      ApiResponseParser.parseVoid(response.data);

      return Success(null);
    } catch (e) {
      log('Error sending multi SMS: $e');
      return Failure('Error sending SMS: $e');
    }
  }
}
