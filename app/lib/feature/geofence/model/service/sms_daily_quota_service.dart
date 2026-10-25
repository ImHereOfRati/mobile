import 'package:iamhere/integration/firebase/firebase_remote_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SmsDailyQuota {
  final int? maximum;
  final int used;

  const SmsDailyQuota({required this.maximum, required this.used});

  int? get remaining =>
      maximum == null ? null : (maximum! - used).clamp(0, maximum!).toInt();

  bool allows(int count) => remaining == null || count <= remaining!;
}

/// Tracks accepted device-contact SMS requests for the current local day.
class SmsDailyQuotaService {
  static const _usageKeyPrefix = 'device_sms_usage_';

  final SharedPreferencesAsync _preferences;

  SmsDailyQuotaService({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  Future<SmsDailyQuota> load() async {
    final today = _todayKey();
    final used = await _preferences.getInt('$_usageKeyPrefix$today') ?? 0;
    int? maximum;
    try {
      maximum = FirebaseRemoteService().maxSmsPerDaysOrNull;
    } catch (_) {
      // Firebase may be unavailable in the local-only startup fallback.
    }
    return SmsDailyQuota(maximum: maximum, used: used);
  }

  Future<void> recordAccepted(int smsCount) async {
    if (smsCount <= 0) return;
    final key = '$_usageKeyPrefix${_todayKey()}';
    final used = await _preferences.getInt(key) ?? 0;
    await _preferences.setInt(key, used + smsCount);
  }

  static String _todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }
}
