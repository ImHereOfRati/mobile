import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/common/base/result/result.dart';
import 'package:iamhere/feature/geofence/background/geofence_delivery_pipeline.dart';
import 'package:iamhere/feature/geofence/background/geofence_delivery_queue_database_service.dart';
import 'package:iamhere/feature/geofence/background/geofence_delivery_queue_entity.dart';
import 'package:iamhere/feature/geofence/background/geofence_delivery_snapshot.dart';
import 'package:iamhere/feature/geofence/background/geofence_retry_scheduler.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';
import 'package:iamhere/feature/geofence/repository/geofence_local_repository.dart';
import 'package:iamhere/feature/geofence/service/contact_resolution_service.dart';
import 'package:iamhere/feature/geofence/service/fcm_arrival_service.dart';
import 'package:iamhere/feature/geofence/service/native_geofence_registrar_interface.dart';
import 'package:iamhere/feature/geofence/service/record_service.dart';
import 'package:iamhere/feature/geofence/service/sms_notification_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'geofence_delivery_pipeline_test.mocks.dart';

@GenerateMocks([
  GeofenceDeliveryQueueDatabaseService,
  ContactResolutionService,
  GeofenceLocalRepository,
  NativeGeofenceRegistrarInterface,
  SmsNotificationService,
  FcmArrivalService,
  RecordService,
  GeofenceRetryScheduler,
])
void main() {
  provideDummy<Result<void>>(Failure('default'));
  late MockGeofenceDeliveryQueueDatabaseService mockQueue;
  late MockContactResolutionService mockContactResolution;
  late MockGeofenceLocalRepository mockGeofenceRepo;
  late MockNativeGeofenceRegistrarInterface mockRegistrar;
  late MockSmsNotificationService mockSms;
  late MockFcmArrivalService mockFcm;
  late MockRecordService mockRecord;
  late MockGeofenceRetryScheduler mockScheduler;
  late GeofenceDeliveryPipeline pipeline;

  setUp(() {
    mockQueue = MockGeofenceDeliveryQueueDatabaseService();
    mockContactResolution = MockContactResolutionService();
    mockGeofenceRepo = MockGeofenceLocalRepository();
    mockRegistrar = MockNativeGeofenceRegistrarInterface();
    mockSms = MockSmsNotificationService();
    mockFcm = MockFcmArrivalService();
    mockRecord = MockRecordService();
    mockScheduler = MockGeofenceRetryScheduler();

    pipeline = GeofenceDeliveryPipeline(
      mockQueue,
      mockContactResolution,
      mockGeofenceRepo,
      mockRegistrar,
      mockSms,
      mockFcm,
      mockRecord,
      mockScheduler,
    );

    when(mockRecord.markGeofenceRecordPending(
      geofence: anyNamed('geofence'),
      recipientNames: anyNamed('recipientNames'),
      deliveryKey: anyNamed('deliveryKey'),
      message: anyNamed('message'),
      deliveryEventType: anyNamed('deliveryEventType'),
      retryCount: anyNamed('retryCount'),
      lastError: anyNamed('lastError'),
    )).thenAnswer((_) async {});

    when(mockRecord.markGeofenceRecordCompleted(
      geofence: anyNamed('geofence'),
      recipientNames: anyNamed('recipientNames'),
      deliveryKey: anyNamed('deliveryKey'),
      message: anyNamed('message'),
      deliveryEventType: anyNamed('deliveryEventType'),
      retryCount: anyNamed('retryCount'),
    )).thenAnswer((_) async {});

    when(mockRecord.markGeofenceRecordFailed(
      geofence: anyNamed('geofence'),
      recipientNames: anyNamed('recipientNames'),
      deliveryKey: anyNamed('deliveryKey'),
      message: anyNamed('message'),
      deliveryEventType: anyNamed('deliveryEventType'),
      retryCount: anyNamed('retryCount'),
      lastError: anyNamed('lastError'),
    )).thenAnswer((_) async {});

    when(mockGeofenceRepo.updateActiveStatus(any, any))
        .thenAnswer((_) async {});
    when(mockGeofenceRepo.updateAwaitingDeparture(any, any))
        .thenAnswer((_) async {});
    when(mockRegistrar.unregister(any)).thenAnswer((_) async {});
    when(mockRegistrar.register(any)).thenAnswer((_) async {});
    when(mockQueue.complete(any)).thenAnswer((_) async {});
    when(
      mockQueue.reschedule(
        id: anyNamed('id'),
        retryCount: anyNamed('retryCount'),
        lastError: anyNamed('lastError'),
      ),
    ).thenAnswer((_) async {});
    when(mockFcm.notifyDeliveryResultToMe(
      location: anyNamed('location'),
      type: anyNamed('type'),
    )).thenAnswer((_) async {});
    when(mockScheduler.scheduleNextIfNeeded()).thenAnswer((_) async {});

    when(mockSms.sendSmsToRecipients(
      phoneNumbers: anyNamed('phoneNumbers'),
      body: anyNamed('body'),
      location: anyNamed('location'),
      type: anyNamed('type'),
    )).thenAnswer((_) async => Failure('not configured'));

    when(mockFcm.sendGeofenceNotifications(
      receiverEmails: anyNamed('receiverEmails'),
      body: anyNamed('body'),
      location: anyNamed('location'),
      type: anyNamed('type'),
    )).thenAnswer((_) async => Failure('not configured'));
  });

  GeofenceEntity _geofence({
    int id = 42,
    String eventType = 'arrival',
    bool awaitingDeparture = false,
  }) =>
      GeofenceEntity(
        id: id,
        name: '집',
        address: '서울 강남구',
        lat: 37.0,
        lng: 127.0,
        radius: 100.0,
        message: '',
        contactIds: '[]',
        eventType: eventType,
        awaitingDeparture: awaitingDeparture,
      );

  GeofenceDeliveryQueueEntity _queueItem({
    int id = 1,
    int retryCount = 0,
    String deliveryEventType = 'arrival',
    List<String> smsPhoneNumbers = const [],
    List<String> serverEmails = const [],
    String geofenceEventType = 'arrival',
  }) {
    final snapshot = GeofenceDeliverySnapshot(
      geofence: _geofence(eventType: geofenceEventType),
      recipientNames: [],
      smsPhoneNumbers: smsPhoneNumbers,
      serverEmails: serverEmails,
      deliveryEventType: deliveryEventType,
    );
    return GeofenceDeliveryQueueEntity(
      id: id,
      dedupeKey: '42:$deliveryEventType:12345',
      snapshotJson: snapshot.toJson(),
      status: GeofenceDeliveryQueueEntity.pending,
      retryCount: retryCount,
      nextAttemptAt: DateTime.now().toUtc(),
      lastError: '',
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );
  }

  void _stubTakeDue(List<GeofenceDeliveryQueueEntity> items) {
    var called = false;
    when(mockQueue.takeDue(limit: anyNamed('limit'))).thenAnswer((_) async {
      if (!called) {
        called = true;
        return items;
      }
      return [];
    });
  }

  group('GeofenceDeliveryPipeline.processPending — 수신자 없음', () {
    test('SMS/FCM 없을 때 success 로 처리 → record completed + queue completed', () async {
      final item = _queueItem();
      _stubTakeDue([item]);
      when(mockQueue.claim(item.id!)).thenAnswer((_) async => true);

      await pipeline.processPending();

      verify(mockRecord.markGeofenceRecordCompleted(
        geofence: anyNamed('geofence'),
        recipientNames: anyNamed('recipientNames'),
        deliveryKey: anyNamed('deliveryKey'),
        message: anyNamed('message'),
        deliveryEventType: anyNamed('deliveryEventType'),
        retryCount: anyNamed('retryCount'),
      )).called(1);
      verify(mockQueue.complete(item.id!)).called(1);
      verify(mockGeofenceRepo.updateActiveStatus(42, false)).called(1);
    });
  });

  group('GeofenceDeliveryPipeline.processPending — SMS 성공', () {
    test('SMS 성공 → record completed + queue completed + geofence deactivated', () async {
      final item = _queueItem(smsPhoneNumbers: ['01012345678']);
      _stubTakeDue([item]);
      when(mockQueue.claim(item.id!)).thenAnswer((_) async => true);
      when(mockSms.sendSmsToRecipients(
        phoneNumbers: anyNamed('phoneNumbers'),
        body: anyNamed('body'),
        location: anyNamed('location'),
        type: anyNamed('type'),
      )).thenAnswer((_) async => Success<void>(null));

      await pipeline.processPending();

      verify(mockRecord.markGeofenceRecordCompleted(
        geofence: anyNamed('geofence'),
        recipientNames: anyNamed('recipientNames'),
        deliveryKey: anyNamed('deliveryKey'),
        message: anyNamed('message'),
        deliveryEventType: anyNamed('deliveryEventType'),
        retryCount: anyNamed('retryCount'),
      )).called(1);
      verify(mockQueue.complete(item.id!)).called(1);
      verify(mockGeofenceRepo.updateActiveStatus(42, false)).called(1);
      verify(mockRegistrar.unregister(42)).called(1);
    });

    test('SMS 성공 → notifyDeliveryResultToMe 호출', () async {
      final item = _queueItem(smsPhoneNumbers: ['01012345678']);
      _stubTakeDue([item]);
      when(mockQueue.claim(item.id!)).thenAnswer((_) async => true);
      when(mockSms.sendSmsToRecipients(
        phoneNumbers: anyNamed('phoneNumbers'),
        body: anyNamed('body'),
        location: anyNamed('location'),
        type: anyNamed('type'),
      )).thenAnswer((_) async => Success<void>(null));

      await pipeline.processPending();

      verify(mockFcm.notifyDeliveryResultToMe(
        location: anyNamed('location'),
        type: anyNamed('type'),
      )).called(1);
    });
  });

  group('GeofenceDeliveryPipeline.processPending — FCM 성공', () {
    test('FCM 성공 → record completed + queue completed', () async {
      final item = _queueItem(serverEmails: ['user@example.com']);
      _stubTakeDue([item]);
      when(mockQueue.claim(item.id!)).thenAnswer((_) async => true);
      when(mockFcm.sendGeofenceNotifications(
        receiverEmails: anyNamed('receiverEmails'),
        body: anyNamed('body'),
        location: anyNamed('location'),
        type: anyNamed('type'),
      )).thenAnswer((_) async => Success<void>(null));

      await pipeline.processPending();

      verify(mockQueue.complete(item.id!)).called(1);
      verify(mockGeofenceRepo.updateActiveStatus(42, false)).called(1);
    });
  });

  group('GeofenceDeliveryPipeline.processPending — 전송 실패', () {
    test('SMS 실패 → reschedule + record pending 업데이트 (retryCount<max)', () async {
      final item = _queueItem(smsPhoneNumbers: ['01012345678'], retryCount: 0);
      _stubTakeDue([item]);
      when(mockQueue.claim(item.id!)).thenAnswer((_) async => true);
      // setUp default: SMS returns Failure('not configured') — already covers this

      await pipeline.processPending();

      verify(mockQueue.reschedule(
        id: item.id!,
        retryCount: 1,
        lastError: anyNamed('lastError'),
      )).called(1);
      verifyNever(mockQueue.complete(any));
    });

    test('retryCount > maxRetry → record failed + geofence 복원', () async {
      final item = _queueItem(
        smsPhoneNumbers: ['01012345678'],
        retryCount: 4, // maxRetryCount == 4, so next = 5 > 4
      );
      _stubTakeDue([item]);
      when(mockQueue.claim(item.id!)).thenAnswer((_) async => true);
      // setUp default: SMS returns Failure — triggers retry path
      await pipeline.processPending();

      verify(mockRecord.markGeofenceRecordFailed(
        geofence: anyNamed('geofence'),
        recipientNames: anyNamed('recipientNames'),
        deliveryKey: anyNamed('deliveryKey'),
        message: anyNamed('message'),
        deliveryEventType: anyNamed('deliveryEventType'),
        retryCount: 5,
        lastError: anyNamed('lastError'),
      )).called(1);
      verify(mockQueue.complete(item.id!)).called(1);
      verify(mockGeofenceRepo.updateActiveStatus(42, true)).called(1);
      verify(mockRegistrar.register(any)).called(1);
    });
  });

  group('GeofenceDeliveryPipeline.processPending — both 이벤트', () {
    test('both + arrival 성공 → awaitingDeparture=true, geofence deactivate 안 함', () async {
      final item = _queueItem(
        deliveryEventType: 'arrival',
        geofenceEventType: 'both',
      );
      _stubTakeDue([item]);
      when(mockQueue.claim(item.id!)).thenAnswer((_) async => true);

      await pipeline.processPending();

      verify(mockGeofenceRepo.updateAwaitingDeparture(42, true)).called(1);
      verifyNever(mockGeofenceRepo.updateActiveStatus(any, any));
      verifyNever(mockRegistrar.unregister(any));
    });

    test('both + departure 성공 → geofence deactivated', () async {
      final item = _queueItem(
        deliveryEventType: 'departure',
        geofenceEventType: 'both',
      );
      _stubTakeDue([item]);
      when(mockQueue.claim(item.id!)).thenAnswer((_) async => true);

      await pipeline.processPending();

      verify(mockGeofenceRepo.updateActiveStatus(42, false)).called(1);
      verifyNever(mockGeofenceRepo.updateAwaitingDeparture(any, any));
    });

    test('both + arrival 실패(terminal) → awaitingDeparture=false 복원', () async {
      final item = _queueItem(
        deliveryEventType: 'arrival',
        geofenceEventType: 'both',
        smsPhoneNumbers: ['01012345678'],
        retryCount: 4,
      );
      _stubTakeDue([item]);
      when(mockQueue.claim(item.id!)).thenAnswer((_) async => true);
      // setUp default: SMS returns Failure — triggers terminal failure path
      await pipeline.processPending();

      verify(mockGeofenceRepo.updateAwaitingDeparture(42, false)).called(1);
      verifyNever(mockGeofenceRepo.updateActiveStatus(any, any));
    });
  });

  group('GeofenceDeliveryPipeline.processPending — single-flight', () {
    test('동시 processPending 호출 시 두 번째는 첫 번째 Future 를 공유', () async {
      _stubTakeDue([]);

      final f1 = pipeline.processPending();
      final f2 = pipeline.processPending();

      await Future.wait([f1, f2]);

      // takeDue 는 한 번만 호출되어야 함 (single-flight)
      verify(mockQueue.takeDue(limit: anyNamed('limit'))).called(1);
    });
  });
}
