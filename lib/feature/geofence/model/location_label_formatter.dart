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
  required String location,
  required String senderName,
}) {
  final sender = senderName.trim().isEmpty ? '사용자 닉네임' : senderName.trim();
  return '[ImHere]\n$location 도착\n발신자: $sender';
}

String composeSmsPreview({
  required String location,
  required String senderName,
}) {
  return composeSmsBody(location: location, senderName: senderName);
}
