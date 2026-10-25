import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/shell/view/native_app_shell.dart';

void main() {
  test('treats /setting and its children as native paths', () {
    expect(NativeShellPage.isNativePath('/setting'), isTrue);
    expect(NativeShellPage.isNativePath('/setting/agreements'), isTrue);
    expect(NativeShellPage.isNativePath('/setting/agreements/3'), isTrue);
    expect(NativeShellPage.isNativePath('/settings'), isFalse);
    expect(NativeShellPage.isNativePath('/record/send-history'), isFalse);
  });

  test('keeps the logo header on native pages and uses a title bar on web', () {
    expect(NativeShellPage.fromLocation('/setting').showAppHeader, isTrue);
    expect(
      NativeShellPage.fromLocation('/setting/agreements').showAppHeader,
      isTrue,
    );
    expect(NativeShellPage.fromLocation('/friend').showAppHeader, isTrue);
    expect(NativeShellPage.fromLocation('/friend/add').showAppHeader, isFalse);
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

    final detail = NativeShellPage.fromLocation('/setting/agreements/12');
    expect(detail.selectedTab, NativeShellTab.setting);
    expect(detail.title, '약관 상세');
    expect(detail.showBackButton, isTrue);
  });
}
