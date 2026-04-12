import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'dart:isolate';
import 'dart:ui';

class FirebaseCrashlyticsService {
  final FirebaseCrashlytics _firebaseCrashlytics = FirebaseCrashlytics.instance;

  Future<void> initialize() async {
    _enrollSynchronousErrorHandler(_firebaseCrashlytics);
    _enrollAsynchronousErrorHandler(_firebaseCrashlytics);
    _enrollIsolateErrorHandler(_firebaseCrashlytics);
  }

  void _enrollSynchronousErrorHandler(FirebaseCrashlytics firebaseCrashlytics) {
    FlutterError.onError = (errorDetails) {
      firebaseCrashlytics.recordFlutterFatalError(errorDetails);
    };
  }

  void _enrollAsynchronousErrorHandler(FirebaseCrashlytics firebaseCrashlytics) {
    PlatformDispatcher.instance.onError = (error, stack) {
      firebaseCrashlytics.recordError(error, stack, fatal: true);
      return true;
    };
  }

  void _enrollIsolateErrorHandler(FirebaseCrashlytics firebaseCrashlytics) {
    Isolate.current.addErrorListener(
      RawReceivePort((pair) async {
        final List<dynamic> errorAndStacktrace = pair;
        await firebaseCrashlytics.recordError(
          errorAndStacktrace.first,
          errorAndStacktrace.last,
          fatal: true,
        );
      }).sendPort,
    );
  }
}
