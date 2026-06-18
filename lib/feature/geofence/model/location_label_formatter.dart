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

String composeSmsPreview({
  required EventType eventType,
  required String message,
  required String location,
}) {
  return '[WEB 발신]\n${composeSmsBody(
    eventType: eventType,
    message: message,
    location: location,
  )}';
}
