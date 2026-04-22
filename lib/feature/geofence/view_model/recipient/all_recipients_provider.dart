import 'package:iamhere/feature/friend/view_model/contact_view_model.dart';
import 'package:iamhere/feature/friend/view_model/friend_list_view_model.dart';
import 'package:iamhere/feature/geofence/model/recipient.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'all_recipients_provider.g.dart';

@riverpod
Future<List<Recipient>> allRecipients(Ref ref) async {
  final contactsAsync = ref.watch(contactViewModelProvider);
  final friendsAsync = ref.watch(friendListViewModelProvider);

  if (contactsAsync.isLoading || friendsAsync.isLoading) {
    return [];
  }

  final contacts = contactsAsync.value ?? [];
  final friends = friendsAsync.value ?? [];

  final local = contacts.map((c) => LocalRecipient(c)).toList();
  final server = friends.map(ServerRecipient.fromDto).toList();

  return <Recipient>[...server, ...local];
}
