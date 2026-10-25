import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/shell/view/native_app_shell.dart';

void main() {
  test('treats /setting and its children as native paths', () {
    expect(NativeShellPage.isNativePath('/setting'), isTrue);
    expect(NativeShellPage.isNativePath('/setting/agreements'), isTrue);
    expect(NativeShellPage.isNativePath('/setting/permissions'), isTrue);
    expect(NativeShellPage.isNativePath('/settings'), isFalse);
    expect(NativeShellPage.isNativePath('/record/send-history'), isTrue);
    expect(NativeShellPage.isNativePath('/friend/requests'), isTrue);
    expect(NativeShellPage.isNativePath('/friends'), isFalse);
    expect(NativeShellPage.isNativePath('/geofence'), isFalse);
    expect(NativeShellPage.isNativePath('/auto-send-readiness'), isFalse);
  });

  test('finds the parent a native page goes back to', () {
    expect(NativeShellPage.parentOf('/friend'), isNull);
    expect(NativeShellPage.parentOf('/friend/requests'), '/friend');
    expect(
      NativeShellPage.parentOf('/friend/device-contact/7/edit'),
      '/friend',
    );
    expect(NativeShellPage.parentOf('/record/send-history'), '/record');
    expect(
      NativeShellPage.parentOf('/record/send-history/3'),
      '/record/send-history',
    );
    expect(
      NativeShellPage.parentOf('/record/notifications/9'),
      '/record/notifications',
    );
  });

  test('keeps the setting tab selected on nested setting pages', () {
    final main = NativeShellPage.fromLocation('/setting');
    expect(main.selectedTab, NativeShellTab.setting);
    expect(main.title, '설정');
    expect(main.showBackButton, isFalse);

    final agreements = NativeShellPage.fromLocation('/setting/agreements');
    expect(agreements.selectedTab, NativeShellTab.setting);
    expect(agreements.title, '약관 동의 관리');
    expect(agreements.showBackButton, isTrue);
  });
}
