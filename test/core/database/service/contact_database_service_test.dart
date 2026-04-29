import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/core/database/local_database_exception.dart';
import 'package:iamhere/core/database/service/contact_database_service.dart';
import 'package:iamhere/feature/friend/repository/contact_entity.dart';

import '../_helpers/test_database_factory.dart';

void main() {
  setUpAll(TestDatabaseFactory.ensureInitialized);

  late TestDatabaseHandle handle;
  late ContactDatabaseService sut;

  setUp(() async {
    handle = await TestDatabaseFactory.openCurrentSchema();
    sut = ContactDatabaseService(handle.database);
  });

  tearDown(() => handle.dispose());

  test('save → findAll round-trip', () async {
    final saved = await sut.save(
      ContactEntity(name: '엄마', number: '01012345678'),
    );

    expect(saved.id, isNotNull);
    final all = await sut.findAll();
    expect(all, hasLength(1));
    expect(all.single.name, '엄마');
    expect(all.single.number, '01012345678');
  });

  test('findAll 은 이름 오름차순으로 반환한다', () async {
    await sut.save(ContactEntity(name: '회사', number: '02'));
    await sut.save(ContactEntity(name: '집', number: '031'));
    await sut.save(ContactEntity(name: '학교', number: '02'));

    final names = (await sut.findAll()).map((e) => e.name).toList();
    expect(names, ['집', '학교', '회사']);
  });

  test('update 는 같은 id 의 행을 갱신한다', () async {
    final saved = await sut.save(
      ContactEntity(name: '엄마', number: '01012345678'),
    );

    await sut.update(saved.copyWith(number: '01099998888'));

    final all = await sut.findAll();
    expect(all.single.number, '01099998888');
  });

  test('id 없는 update 는 LocalDatabaseException 을 던진다', () async {
    expect(
      () => sut.update(ContactEntity(name: '엄마', number: '010')),
      throwsA(isA<LocalDatabaseException>()),
    );
  });

  test('delete 는 해당 id 의 행만 제거한다', () async {
    final a = await sut.save(ContactEntity(name: '엄마', number: '010'));
    await sut.save(ContactEntity(name: '아빠', number: '010'));

    await sut.delete(a.id!);

    final names = (await sut.findAll()).map((e) => e.name).toList();
    expect(names, ['아빠']);
  });
}
