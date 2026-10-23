import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/infrastructure/database/service/abstract_local_database_engine.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:sqflite/sqflite.dart';

import 'entity_database_service_patterns_test.mocks.dart';

@GenerateNiceMocks([MockSpec<Database>()])
void main() {
  late MockDatabase database;
  late _PatternDatabaseService sut;

  setUp(() {
    database = MockDatabase();
    sut = _PatternDatabaseService(database);
  });

  test('saveEntity 는 executeInsert 를 통해 저장 후 생성 함수를 호출한다', () async {
    when(
      database.insert(any, any, conflictAlgorithm: anyNamed('conflictAlgorithm')),
    ).thenAnswer((_) async => 9);

    final result = await sut.saveName('엄마');

    expect(result, 'saved:9');
    verify(
      database.insert('contacts', {'name': '엄마'}, conflictAlgorithm: ConflictAlgorithm.abort),
    ).called(1);
  });

  test('findAllEntities 는 정렬 조건과 mapper를 그대로 위임한다', () async {
    when(database.query(any, orderBy: anyNamed('orderBy'))).thenAnswer(
      (_) async => [
        {'name': '가'},
        {'name': '나'},
      ],
    );

    final result = await sut.findAllNames();

    expect(result, ['가', '나']);
    verify(database.query('contacts', orderBy: 'name ASC')).called(1);
  });

  test('deleteAllEntities 는 where 없이 전체 삭제를 위임한다', () async {
    when(database.delete(any)).thenAnswer((_) async => 2);

    await sut.deleteAllNames();

    verify(database.delete('contacts')).called(1);
  });
}

class _PatternDatabaseService extends AbstractLocalDatabaseService {
  _PatternDatabaseService(super.database);

  Future<String> saveName(String name) {
    return saveEntity(
      entityName: 'contact',
      table: 'contacts',
      values: {'name': name},
      createEntity: (id) => 'saved:$id',
      entityDetails: 'Contact: $name',
    );
  }

  Future<List<String>> findAllNames() {
    return findAllEntities(
      entityName: 'contact',
      table: 'contacts',
      fromMap: (map) => map['name'] as String,
      orderBy: 'name ASC',
    );
  }

  Future<void> deleteAllNames() {
    return deleteAllEntities(
      entityName: 'contacts',
      table: 'contacts',
      additionalDetails: 'delete all',
    );
  }
}
