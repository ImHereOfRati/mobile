class HttpStatusCode {
  /// 2XX
  static const int ok = 200;
  static const int created = 201;

  /// 4XX
  static const int unauthorized = 401;

  /// 5XX
  static const int internalServerError = 500;

  static bool is2XXStatusCode(int stausCode) {
    if (stausCode == ok || stausCode == created) {
      return true;
    }

    return false;
  }
}
