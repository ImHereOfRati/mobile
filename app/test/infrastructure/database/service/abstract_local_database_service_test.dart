import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/infrastructure/database/local_database_exception.dart';
import 'package:iamhere/infrastructure/database/service/abstract_local_database_engine.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:sqflite/sqflite.dart';

import 'abstract_local_database_service_test.mocks.dart';

@GenerateNiceMocks([MockSpec<Database>()])
void main() {
  late MockDatabase database;
  late _TestDatabaseService sut;

  setUp(() {
    database = MockDatabase();
    sut = _TestDatabaseService(database);
  });

  test('executeUpdate 는 id가 없으면 LocalDatabaseException 을 던진다', () async {
    await expectLater(
      () => sut.updateWithoutId(),
      throwsA(
        isA<LocalDatabaseException>().having(
          (e) => e.message,
          'message',
          contains('Cannot update Contact without ID'),
        ),
      ),
    );

    verifyNever(database.update(any, any, where: anyNamed('where'), whereArgs: anyNamed('whereArgs')));
  });

  test('executeUpdate 는 영향받은 row가 없으면 LocalDatabaseException 을 던진다', () async {
    when(
      database.update(
        any,
        any,
        where: anyNamed('where'),
        whereArgs: anyNamed('whereArgs'),
      ),
    ).thenAnswer((_) async => 0);

    await expectLater(
      () => sut.updateExisting(3),
      throwsA(
        isA<LocalDatabaseException>().having(
          (e) => e.message,
          'message',
          contains('Contact not found'),
        ),
      ),
    );
  });

  test('executeDelete 는 where가 있으면 해당 조건으로 delete 한다', () async {
    when(
      database.delete(
        any,
        where: anyNamed('where'),
        whereArgs: anyNamed('whereArgs'),
      ),
    ).thenAnswer((_) async => 1);

    await sut.deleteByName('엄마');

    verify(
      database.delete('contacts', where: 'name = ?', whereArgs: ['엄마']),
    ).called(1);
  });

  test('executeQuery 는 mapper를 통해 결과를 변환한다', () async {
    when(database.query(any, orderBy: anyNamed('orderBy'))).thenAnswer(
      (_) async => [
        {'name': '엄마'},
        {'name': '아빠'},
      ],
    );

    final result = await sut.findNames();

    expect(result, ['엄마', '아빠']);
  });
}

class _TestDatabaseService extends AbstractLocalDatabaseService {
  _TestDatabaseService(super.database);

  Future<int> updateWithoutId() {
    return executeUpdate(
      entityName: 'Contact',
      entityId: null,
      table: 'contacts',
      values: {'name': '엄마'},
      entityDetails: 'Contact: 엄마',
    );
  }

  Future<int> updateExisting(int id) {
    return executeUpdate(
      entityName: 'Contact',
      entityId: id,
      table: 'contacts',
      values: {'name': '엄마'},
      entityDetails: 'Contact: 엄마',
    );
  }

  Future<void> deleteByName(String name) {
    return executeDelete(
      entityName: 'Contact',
      table: 'contacts',
      where: 'name = ?',
      whereArgs: [name],
    );
  }

  Future<List<String>> findNames() {
    return executeQuery(
      entityName: 'Contact',
      table: 'contacts',
      fromMap: (map) => map['name'] as String,
      orderBy: 'name ASC',
    );
  }
}
