import 'contact_entity.dart';

abstract class ContactRepository {
  Future<ContactEntity> save(ContactEntity entity);

  Future<List<ContactEntity>> findAll();

  Future<void> delete(int id);
}
