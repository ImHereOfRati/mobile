import 'package:iamhere/core/database/local_database_properties.dart';
import 'package:iamhere/core/database/service/abstract_local_database_engine.dart';
import 'package:iamhere/feature/friend/repository/contact_entity.dart';
import 'package:injectable/injectable.dart';

@singleton
class ContactDatabaseService extends AbstractLocalDatabaseService {
  ContactDatabaseService(super.database);

  Future<ContactEntity> save(ContactEntity entity) => executeInsert(
    entityName: 'friend',
    table: LocalDatabaseProperties.CONTACT_TABLE_NAME,
    values: entity.toMap(),
    createEntity: (id) => entity.copyWith(id: id),
    entityDetails: 'Contact: ${entity.name}',
  );

  Future<int> update(ContactEntity entity) => executeUpdate(
    entityName: 'Contact',
    entityId: entity.id,
    table: LocalDatabaseProperties.CONTACT_TABLE_NAME,
    values: entity.toMap(),
    entityDetails: 'Contact: ${entity.name}',
  );

  Future<List<ContactEntity>> findAll() => executeQuery(
    entityName: 'friend',
    table: LocalDatabaseProperties.CONTACT_TABLE_NAME,
    fromMap: ContactEntity.fromMap,
    orderBy: 'name ASC',
  );

  Future<void> delete(int id) => executeDelete(
    entityName: 'friend',
    table: LocalDatabaseProperties.CONTACT_TABLE_NAME,
    id: id,
  );
}
