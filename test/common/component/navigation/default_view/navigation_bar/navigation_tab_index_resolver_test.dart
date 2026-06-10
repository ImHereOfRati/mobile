import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/common/component/navigation/default_view/navigation_bar/navigation_tab_index_resolver.dart';
import 'package:iamhere/infrastructure/routing/app_routes.dart';

void main() {
  const resolver = NavigationTabIndexResolver(AppRoutes.mainTabs);

  group('NavigationTabIndexResolver', () {
    test('일치하는 메인 탭 prefix가 있으면 해당 index를 반환한다', () {
      expect(resolver.resolve('/friend/requests'), 1);
      expect(resolver.resolve('/record/send-history'), 2);
    });

    test('일치하는 탭이 없으면 기본 index 0을 반환한다', () {
      expect(resolver.resolve('/unknown/path'), 0);
    });
  });
}
