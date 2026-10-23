sealed class Result<T> {
  R when<R>({
    required R Function(T data) success,
    required R Function(String message) failure,
  }) {
    return switch (this) {
      Success(data: var d) => success(d),
      Failure(message: var m) => failure(m),
    };
  }
}

class Success<T> extends Result<T> {
  final T data;
  Success(this.data);
}

class Failure<T> extends Result<T> {
  final String message;
  final StackTrace? trace;
  Failure(this.message, {this.trace});
}
