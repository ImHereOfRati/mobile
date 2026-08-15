class HttpStatusCode {
  /// 2XX
  static const int ok = 200;
  static const int created = 201;
  static const int accepted = 202;
  static const int noContent = 204;

  /// 4XX
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int conflict = 409;

  /// 5XX
  static const int internalServerError = 500;

  static bool is2XXStatusCode(int stausCode) {
    return stausCode >= 200 && stausCode < 300;
  }
}
