import 'contact.dart';

abstract class ContactViewModelInterface {
  Future<Contact?> selectContact();
  Future<void> deleteContact(int id);
}
