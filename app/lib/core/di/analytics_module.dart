import 'package:iamhere/integration/firebase/analytics_reporter.dart';
import 'package:injectable/injectable.dart';

@module
abstract class AnalyticsModule {
  @lazySingleton
  AnalyticsReporter get analyticsReporter => FirebaseAnalyticsReporter();
}
