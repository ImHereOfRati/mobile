import 'package:iamhere/contact/repository/contact_entity.dart';
import 'package:iamhere/contact/repository/contact_repository.dart';
import 'package:iamhere/shared/infrastructure/database/local_database_service.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class ContactLocalRepository implements ContactRepository {
  final LocalDatabaseService _database;
  ContactLocalRepository(this._database);

  @override
  Future<List<ContactEntity>> findAll() async {
    return await _database.findAllContacts();
  }

  @override
  Future<ContactEntity> save(ContactEntity entity) async {
    return await _database.saveContact(entity);
  }

  @override
  Future<void> delete(int id) async {
    await _database.deleteContact(id);
  }
}
