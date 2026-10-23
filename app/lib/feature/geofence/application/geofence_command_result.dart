class GeofenceCommandResult {
  final bool isSuccess;
  final Object? error;

  const GeofenceCommandResult._({required this.isSuccess, this.error});

  const GeofenceCommandResult.success() : this._(isSuccess: true);

  const GeofenceCommandResult.failure(Object error)
    : this._(isSuccess: false, error: error);
}
