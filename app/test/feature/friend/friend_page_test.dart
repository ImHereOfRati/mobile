import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/components/components.dart';
import 'package:iamhere/core/paging/paged_items.dart';
import 'package:iamhere/feature/friend/model/dto/friendship_dto.dart';
import 'package:iamhere/feature/friend/model/repository/contact_entity.dart';
import 'package:iamhere/feature/friend/model/service/device_contact_service.dart';
import 'package:iamhere/feature/friend/model/service/friend_service.dart';
import 'package:iamhere/feature/friend/view/page/friend_page.dart';
import 'package:iamhere/theme/imhere_theme.dart';

class _FriendServiceFake extends Fake implements FriendService {
  @override
  Future<PagedItems<FriendshipDto>> loadFriendships(int page) async =>
      const PagedItems.empty();
}

class _ContactServiceFake extends Fake implements DeviceContactService {
  final saved = <ContactEntity>[];
  ContactEntity? next;
  int picks = 0;

  @override
  Future<List<ContactEntity>> load() async => List.of(saved);

  @override
  Future<ContactEntity?> pick() async {
    picks++;
    final contact = next;
    if (contact != null) saved.add(contact);
    return contact;
  }
}

void main() {
  late _ContactServiceFake contacts;

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ImHereAppTheme.light,
          home: FriendPage(
            friendService: _FriendServiceFake(),
            contactService: contacts,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() => contacts = _ContactServiceFake());

  testWidgets('has no page title or description', (tester) async {
    await pump(tester);

    expect(find.text('ImHere 친구와 기기 연락처를 한곳에서 확인하세요'), findsNothing);
    expect(find.text('친구 찾기'), findsOneWidget);
    expect(find.text('연락처 추가'), findsOneWidget);
  });

  testWidgets('adds a device contact with a single tap and no sheet', (
    tester,
  ) async {
    contacts.next = ContactEntity(id: 1, name: '김철수', number: '01012345678');
    await pump(tester);

    await tester.tap(find.text('연락처 추가'));
    await tester.pumpAndSettle();

    expect(contacts.picks, 1);
    expect(find.text('김철수 연락처를 추가했어요'), findsOneWidget);
    expect(find.text('김철수'), findsOneWidget);
    expect(find.text('연락처'), findsOneWidget);
    expect(find.text('친구 1명'), findsOneWidget);
  });

  testWidgets('says so when no contact was picked', (tester) async {
    await pump(tester);

    await tester.tap(find.text('연락처 추가'));
    await tester.pumpAndSettle();

    expect(find.text('연락처를 추가하지 않았어요'), findsOneWidget);
  });

  testWidgets('the finder sheet only searches by nickname or email', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.text('친구 찾기').first);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ImHereButton, '검색'), findsOneWidget);
    expect(find.text('연락처로 추가'), findsNothing);
  });
}
