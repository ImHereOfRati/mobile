import 'package:iamhere/core/database/service/contact_database_service.dart';
import 'package:iamhere/feature/friend/repository/contact_repository.dart';
import 'package:injectable/injectable.dart';

import 'contact_entity.dart';

@lazySingleton
class ContactLocalRepository implements ContactRepository {
  final ContactDatabaseService _contactDatabaseService;
  ContactLocalRepository(this._contactDatabaseService);

  @override
  Future<List<ContactEntity>> findAll() async {
    return await _contactDatabaseService.findAll();
  }

  @override
  Future<ContactEntity> save(ContactEntity entity) async {
    return await _contactDatabaseService.save(entity);
  }

  @override
  Future<void> delete(int id) async {
    await _contactDatabaseService.delete(id);
  }
}
