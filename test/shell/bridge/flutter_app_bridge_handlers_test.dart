import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/integration/firebase/analytics_reporter.dart';
import 'package:iamhere/shell/bridge/flutter_app_bridge_handlers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'analytics consent is delegated to Firebase before collection',
    () async {
      final analytics = _FakeAnalyticsReporter();
      final handlers = FlutterAppBridgeHandlers(analytics: analytics).build();

      await handlers['setAnalyticsConsent']!({'granted': true});

      expect(analytics.consents, [true]);
    },
  );

  test(
    'analytics events are delegated without adding sensitive data',
    () async {
      final analytics = _FakeAnalyticsReporter();
      final handlers = FlutterAppBridgeHandlers(analytics: analytics).build();

      await handlers['logEvent']!({
        'name': 'geofence_saved',
        'parameters': {'event_type': 'arrival', 'mode': 'create'},
      });

      expect(analytics.events.single.name, 'geofence_saved');
      expect(analytics.events.single.parameters, {
        'event_type': 'arrival',
        'mode': 'create',
      });
    },
  );

  test(
    'theme changes update the shell and persist the selected mode',
    () async {
      final themeMode = ValueNotifier(ThemeMode.light);
      final savedThemes = <ThemeMode>[];
      final handlers = FlutterAppBridgeHandlers(
        analytics: _FakeAnalyticsReporter(),
        themeMode: themeMode,
        saveTheme: (theme) async => savedThemes.add(theme),
      ).build();

      await handlers['setTheme']!({'theme': 'dark'});

      expect(themeMode.value, ThemeMode.dark);
      expect(savedThemes, [ThemeMode.dark]);
      themeMode.dispose();
    },
  );
}

final class _FakeAnalyticsReporter implements AnalyticsReporter {
  final consents = <bool>[];
  final events = <({String name, Map<String, Object>? parameters})>[];

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    events.add((name: name, parameters: parameters));
  }

  @override
  Future<void> setConsent(bool granted) async {
    consents.add(granted);
  }
}
