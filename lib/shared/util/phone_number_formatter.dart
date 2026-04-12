String convertToPhoneNumber(String raw) {
  String onlyNumber = raw.replaceAll(RegExp(r'[^0-9]'), '');

  if (onlyNumber.length != 11) {
    return onlyNumber;
  }

  return '${onlyNumber.substring(0, 3)}-${onlyNumber.substring(3, 7)}-${onlyNumber.substring(7)}';
}
