import 'contact.dart';
import '../repository/contact_entity.dart';

class ContactAdapter {
  static ContactEntity toEntity(Contact contact) {
    return ContactEntity(
      id: contact.id,
      name: contact.name,
      number: contact.number,
    );
  }

  static Contact toClass(ContactEntity entity) {
    return Contact(id: entity.id, name: entity.name, number: entity.number);
  }
}
