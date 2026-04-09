import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:iamhere/contact/repository/contact_local_repository.dart';

final contactLocalRepositoryProvider = Provider<ContactLocalRepository>((ref) {
  return getIt<ContactLocalRepository>();
});
