import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/geofence/background/geofence_delivery_queue_database_service.dart';
import 'package:iamhere/feature/geofence/background/geofence_delivery_queue_entity.dart';
import 'package:iamhere/feature/geofence/background/geofence_delivery_snapshot.dart';

import '../../../infrastructure/database/_helpers/test_database_factory.dart';

void main() {
  setUpAll(TestDatabaseFactory.ensureInitialized);

  late TestDatabaseHandle handle;
  late GeofenceDeliveryQueueDatabaseService sut;

  setUp(() async {
    handle = await TestDatabaseFactory.openCurrentSchema();
    sut = GeofenceDeliveryQueueDatabaseService(handle.database);
  });

  tearDown(() => handle.dispose());

  GeofenceDeliveryQueueEntity makeQueueEntity({
    String dedupeKey = 'g1:enter:0',
    String status = GeofenceDeliveryQueueEntity.pending,
    DateTime? nextAttemptAt,
    int retryCount = 0,
    String snapshotJson = '{"geofence":{"id":1,"name":"집","address":"","lat":37.0,"lng":127.0,"radius":250.0,"message":"도착","contactIds":"[]","isActive":true},"recipientNames":[],"smsPhoneNumbers":[],"serverEmails":[],"eventName":"enter"}',
  }) =>
      GeofenceDeliveryQueueEntity(
        dedupeKey: dedupeKey,
        snapshotJson: snapshotJson,
        status: status,
        retryCount: retryCount,
        nextAttemptAt: nextAttemptAt ?? DateTime.now().toUtc().subtract(const Duration(seconds: 1)),
        lastError: '',
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );

  group('enqueue', () {
    test('saves item and assigns id', () async {
      final entity = makeQueueEntity();
      final saved = await sut.enqueue(entity);

      expect(saved, isNotNull);
      expect(saved!.id, isNotNull);
      expect(saved.dedupeKey, entity.dedupeKey);
      expect(saved.status, GeofenceDeliveryQueueEntity.pending);
    });

    test('duplicate dedupeKey returns null (unique constraint)', () async {
      final entity = makeQueueEntity(dedupeKey: 'unique:1');
      final first = await sut.enqueue(entity);
      expect(first, isNotNull);

      final duplicate = makeQueueEntity(dedupeKey: 'unique:1');
      final second = await sut.enqueue(duplicate);
      expect(second, isNull);
    });

    test('multiple different dedupeKeys saves successfully', () async {
      final e1 = await sut.enqueue(makeQueueEntity(dedupeKey: 'g1:enter:1'));
      final e2 = await sut.enqueue(makeQueueEntity(dedupeKey: 'g2:enter:2'));

      expect(e1!.id, isNotNull);
      expect(e2!.id, isNotNull);
      expect(e1.id, isNot(e2.id));
    });
  });

  group('takeDue', () {
    test('returns pending items where next_attempt_at <= now', () async {
      final now = DateTime.now().toUtc();
      final dueSoon = makeQueueEntity(
        dedupeKey: 'g1:due',
        nextAttemptAt: now.subtract(const Duration(seconds: 5)),
      );
      final notYet = makeQueueEntity(
        dedupeKey: 'g2:future',
        nextAttemptAt: now.add(const Duration(minutes: 5)),
      );

      final saved1 = await sut.enqueue(dueSoon);
      final saved2 = await sut.enqueue(notYet);

      final dueItems = await sut.takeDue(limit: 10);

      expect(dueItems, hasLength(1));
      expect(dueItems.first.id, saved1!.id);
    });

    test('does not return processing items unless stale (15+ min)', () async {
      final now = DateTime.now().toUtc();
      final entity = makeQueueEntity(
        dedupeKey: 'g1:proc',
        status: GeofenceDeliveryQueueEntity.processing,
        nextAttemptAt: now,
      );
      final saved = await sut.enqueue(entity);

      final dueItems = await sut.takeDue(limit: 10);
      expect(dueItems, isEmpty);
    });

    test('reclaims stale processing rows (updated_at > 15 min ago)', () async {
      final now = DateTime.now().toUtc();
      final staleTime = now.subtract(const Duration(minutes: 20));

      // Manually insert a stale processing row
      await handle.database.insert(
        'geofence_delivery_queue',
        {
          'dedupe_key': 'g1:stale',
          'snapshot_json': '{}',
          'status': GeofenceDeliveryQueueEntity.processing,
          'retry_count': 1,
          'next_attempt_at': now.toIso8601String(),
          'last_error': 'network timeout',
          'created_at': staleTime.toIso8601String(),
          'updated_at': staleTime.toIso8601String(),
        },
      );

      final dueItems = await sut.takeDue(limit: 10);
      expect(dueItems, hasLength(1));
      expect(dueItems.first.dedupeKey, 'g1:stale');
      expect(dueItems.first.status, GeofenceDeliveryQueueEntity.processing);
    });

    test('respects limit parameter', () async {
      for (int i = 0; i < 15; i++) {
        await sut.enqueue(makeQueueEntity(dedupeKey: 'g$i:many'));
      }

      final result = await sut.takeDue(limit: 5);
      expect(result, hasLength(5));
    });
  });

  group('claim', () {
    test('transitions pending to processing and returns true', () async {
      final entity = makeQueueEntity(
        dedupeKey: 'g1:claim',
        status: GeofenceDeliveryQueueEntity.pending,
      );
      final saved = await sut.enqueue(entity);

      final claimed = await sut.claim(saved!.id!);
      expect(claimed, isTrue);

      final dueItems = await sut.takeDue(limit: 10);
      expect(dueItems, isEmpty);
    });

    test('returns false if already claimed by another process', () async {
      final entity = makeQueueEntity(
        dedupeKey: 'g1:already',
        status: GeofenceDeliveryQueueEntity.pending,
      );
      final saved = await sut.enqueue(entity);
      final id = saved!.id!;

      final first = await sut.claim(id);
      expect(first, isTrue);

      final second = await sut.claim(id);
      expect(second, isFalse);
    });

    test('returns false if item does not exist', () async {
      final claimed = await sut.claim(999);
      expect(claimed, isFalse);
    });
  });

  group('complete', () {
    test('deletes completed item', () async {
      final entity = makeQueueEntity(dedupeKey: 'g1:complete');
      final saved = await sut.enqueue(entity);
      final id = saved!.id!;

      await sut.complete(id);

      final remaining = await sut.takeDue(limit: 10);
      expect(remaining, isEmpty);
    });
  });

  group('reschedule', () {
    test('updates status to pending and calculates next_attempt_at', () async {
      final entity = makeQueueEntity(
        dedupeKey: 'g1:reschedule',
        status: GeofenceDeliveryQueueEntity.processing,
      );
      final saved = await sut.enqueue(entity);
      final id = saved!.id!;

      final now = DateTime.now().toUtc();
      await sut.reschedule(id: id, retryCount: 1, lastError: 'network error');

      final all = await handle.database.query('geofence_delivery_queue', where: 'id = ?', whereArgs: [id]);
      expect(all, hasLength(1));
      final updated = all.first;
      expect(updated['status'], GeofenceDeliveryQueueEntity.pending);
      expect(updated['retry_count'], 1);
      expect(updated['last_error'], 'network error');

      final nextAttemptAt = DateTime.parse(updated['next_attempt_at'] as String);
      final delayMinutes = nextAttemptAt.difference(now).inMinutes;
      expect(delayMinutes, 5); // retry 1 → 5 min backoff
    });

    test('exponential backoff: 0→1, 1→5, 2→15, 3→30, 4→60, 5+→60', () async {
      final testCases = [
        (0, 1),   // 0th retry → 1 min
        (1, 5),   // 1st retry → 5 min
        (2, 15),  // 2nd retry → 15 min
        (3, 30),  // 3rd retry → 30 min
        (4, 60),  // 4th retry → 60 min
        (5, 60),  // 5th+ retry → 60 min (capped)
      ];

      for (final (retryCount, expectedMinutes) in testCases) {
        final entity = makeQueueEntity(dedupeKey: 'g$retryCount:backoff');
        final saved = await sut.enqueue(entity);
        final id = saved!.id!;

        final now = DateTime.now().toUtc();
        await sut.reschedule(id: id, retryCount: retryCount, lastError: '');

        final all = await handle.database.query('geofence_delivery_queue', where: 'id = ?', whereArgs: [id]);
        final updated = all.first;
        final nextAttemptAt = DateTime.parse(updated['next_attempt_at'] as String);
        final delayMinutes = nextAttemptAt.difference(now).inMinutes;
        expect(delayMinutes, expectedMinutes, reason: 'retry $retryCount should backoff $expectedMinutes min');
      }
    });

    test('increments retry_count on successive reschedules', () async {
      final entity = makeQueueEntity(dedupeKey: 'g1:multi_retry');
      var saved = await sut.enqueue(entity);
      var id = saved!.id!;

      for (int i = 0; i < 3; i++) {
        await sut.reschedule(id: id, retryCount: i, lastError: 'attempt $i');
        final all = await handle.database.query('geofence_delivery_queue', where: 'id = ?', whereArgs: [id]);
        final updated = all.first;
        expect(updated['retry_count'], i);
      }
    });
  });
}
