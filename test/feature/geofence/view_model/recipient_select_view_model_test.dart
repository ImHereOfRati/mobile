import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/friend/view_model/contact.dart';
import 'package:iamhere/feature/geofence/model/recipient.dart';
import 'package:iamhere/feature/geofence/view_model/recipient_select_view_model.dart';

void main() {
  group('Recipient selectionKey', () {
    test('LocalRecipient 키는 로컬 prefix + 연락처 id 를 사용한다', () {
      final r = LocalRecipient(Contact(id: 42, name: '홍길동', number: '010'));
      expect(r.selectionKey, 'local:42');
    });

    test('ServerRecipient 키는 서버 prefix + friendRelationshipId 를 사용한다', () {
      const r = ServerRecipient(
        friendRelationshipId: 'uuid-123',
        friendEmail: 'a@b.com',
        friendAlias: '지인',
      );
      expect(r.selectionKey, 'server:uuid-123');
    });

    test('ServerRecipient 의 displayName 은 alias 우선, 없으면 email 을 반환한다', () {
      const withAlias = ServerRecipient(
        friendRelationshipId: 'x',
        friendEmail: 'a@b.com',
        friendAlias: '친구',
      );
      const withoutAlias = ServerRecipient(
        friendRelationshipId: 'x',
        friendEmail: 'a@b.com',
        friendAlias: '',
      );
      expect(withAlias.displayName, '친구');
      expect(withoutAlias.displayName, 'a@b.com');
    });
  });

  group('RecipientSelectViewModel', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() => container.dispose());

    final local = LocalRecipient(
      Contact(id: 1, name: '로컬', number: '010-1111-2222'),
    );
    const server = ServerRecipient(
      friendRelationshipId: 'uuid',
      friendEmail: 'me@a.com',
      friendAlias: '서버',
    );

    test('초기 선택키가 state 로 복원된다', () {
      final state = container.read(
        recipientSelectViewModelProvider(['local:1', 'server:uuid']),
      );
      expect(state.selectedKeys, {'local:1', 'server:uuid'});
      expect(state.selectedCount, 2);
    });

    test('toggleSelection 로 로컬/서버 각각 추가·해제가 된다', () {
      final notifier = container.read(
        recipientSelectViewModelProvider(null).notifier,
      );
      notifier.toggleSelection(local.selectionKey);
      notifier.toggleSelection(server.selectionKey);
      var state = container.read(recipientSelectViewModelProvider(null));
      expect(state.selectedKeys, {'local:1', 'server:uuid'});

      notifier.toggleSelection(local.selectionKey);
      state = container.read(recipientSelectViewModelProvider(null));
      expect(state.selectedKeys, {'server:uuid'});
    });

    test('selectAll 은 모두 선택되어 있을 때 전체 해제한다', () {
      final notifier = container.read(
        recipientSelectViewModelProvider(null).notifier,
      );
      notifier.selectAll([local, server]);
      var state = container.read(recipientSelectViewModelProvider(null));
      expect(state.selectedCount, 2);

      notifier.selectAll([local, server]);
      state = container.read(recipientSelectViewModelProvider(null));
      expect(state.selectedCount, 0);
    });

    test('confirmSelection 은 아무도 선택되지 않았을 때 null 을 반환한다', () {
      final notifier = container.read(
        recipientSelectViewModelProvider(null).notifier,
      );
      expect(notifier.confirmSelection([local, server]), isNull);
    });

    test('confirmSelection 은 선택된 수신자만 반환한다', () {
      final notifier = container.read(
        recipientSelectViewModelProvider(null).notifier,
      );
      notifier.toggleSelection(server.selectionKey);
      final result = notifier.confirmSelection([local, server]);
      expect(result, isNotNull);
      expect(result!.length, 1);
      expect(result.first.selectionKey, 'server:uuid');
    });
  });
}
