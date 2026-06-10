import 'package:iamhere/feature/geofence/background/geofence_delivery_snapshot.dart';

class GeofenceDeliveryQueueEntity {
  final int? id;
  final String dedupeKey;
  final String snapshotJson;
  final String status;
  final int retryCount;
  final DateTime nextAttemptAt;
  final String lastError;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GeofenceDeliveryQueueEntity({
    this.id,
    required this.dedupeKey,
    required this.snapshotJson,
    required this.status,
    required this.retryCount,
    required this.nextAttemptAt,
    required this.lastError,
    required this.createdAt,
    required this.updatedAt,
  });

  static const pending = 'pending';
  static const processing = 'processing';

  GeofenceDeliverySnapshot get snapshot =>
      GeofenceDeliverySnapshot.fromJson(snapshotJson);

  bool get isPending => status == pending;

  bool isDue(DateTime nowUtc) =>
      isPending && !nextAttemptAt.toUtc().isAfter(nowUtc.toUtc());

  GeofenceDeliveryQueueEntity copyWith({
    int? id,
    String? dedupeKey,
    String? snapshotJson,
    String? status,
    int? retryCount,
    DateTime? nextAttemptAt,
    String? lastError,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GeofenceDeliveryQueueEntity(
      id: id ?? this.id,
      dedupeKey: dedupeKey ?? this.dedupeKey,
      snapshotJson: snapshotJson ?? this.snapshotJson,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dedupe_key': dedupeKey,
      'snapshot_json': snapshotJson,
      'status': status,
      'retry_count': retryCount,
      'next_attempt_at': nextAttemptAt.toUtc().toIso8601String(),
      'last_error': lastError,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory GeofenceDeliveryQueueEntity.fromMap(Map<String, dynamic> map) {
    return GeofenceDeliveryQueueEntity(
      id: map['id'] as int?,
      dedupeKey: map['dedupe_key'] as String,
      snapshotJson: map['snapshot_json'] as String,
      status: map['status'] as String? ?? pending,
      retryCount: map['retry_count'] as int? ?? 0,
      nextAttemptAt: DateTime.parse(map['next_attempt_at'] as String),
      lastError: map['last_error'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
