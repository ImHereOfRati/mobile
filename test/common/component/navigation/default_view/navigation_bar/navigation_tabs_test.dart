import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/common/component/navigation/default_view/navigation_bar/navigation_tabs.dart';

void main() {
  test('milestone 1 tab labels use user-facing terminology', () {
    final tabs = NavigationTabs.navTabs;

    expect(tabs[0].label, '알림');
    expect(tabs[1].label, '친구');
    expect(tabs[2].label, '활동');
    expect(tabs[3].label, '설정');
  });
}
