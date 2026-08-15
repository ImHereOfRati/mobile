import 'event_type.dart';

const int smsBodyMaxLength = 45;

String fallbackCoordinates(double latitude, double longitude) =>
    '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';

String composePlaceName({
  String? title,
  String? reverseGeocode,
  required double latitude,
  required double longitude,
}) {
  final cleanTitle = title?.trim() ?? '';
  if (cleanTitle.isNotEmpty) return cleanTitle;

  final cleanReverseGeocode = reverseGeocode?.trim() ?? '';
  if (cleanReverseGeocode.isNotEmpty) return cleanReverseGeocode;

  return fallbackCoordinates(latitude, longitude);
}

String composeFullLocation(String name, String address) {
  final cleanName = name.trim();
  final cleanAddress = address.trim();

  if (cleanName.isEmpty) return cleanAddress;
  if (cleanAddress.isEmpty || cleanAddress == cleanName) return cleanName;

  return '$cleanName ($cleanAddress)';
}

String composeSmsBody({
  required EventType eventType,
  required String message,
  required String location,
}) {
  final cleanLocation = location.trim();
  final cleanMessage = message.trim();
  final defaultMessage =
      '${cleanLocation.isEmpty ? '장소' : cleanLocation} ${eventType == EventType.departure ? '출발' : '도착'}';
  final bodyMessage = cleanMessage.isEmpty
      ? defaultMessage
      : cleanMessage.replaceAll('{location}', cleanLocation);

  return '[ImHere]\n$bodyMessage';
}

/// 서버는 개행을 포함해 [smsBodyMaxLength]자를 넘는 SMS 본문을 SMS-001로 거부한다.
/// 폼에서 이미 막지만, 발송 직전 마지막 방어선으로 초과분을 잘라낸다.
/// 서버도 UTF-16 길이로 세므로 같은 기준을 쓰되 서로게이트 쌍은 쪼개지 않는다.
String clampSmsBody(String body) {
  if (body.length <= smsBodyMaxLength) return body;

  var end = smsBodyMaxLength;
  final lastUnit = body.codeUnitAt(end - 1);
  final splitsSurrogatePair = lastUnit >= 0xD800 && lastUnit <= 0xDBFF;
  if (splitsSurrogatePair) end -= 1;

  return body.substring(0, end);
}

String composeSmsPreview({
  required EventType eventType,
  required String message,
  required String location,
}) {
  return '[WEB 발신]\n${composeSmsBody(eventType: eventType, message: message, location: location)}';
}
