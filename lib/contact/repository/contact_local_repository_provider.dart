import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iamhere/contact/repository/contact_local_repository.dart';
import 'package:iamhere/shared/infrastructure/di/di_setup.dart';

final contactLocalRepositoryProvider = Provider<ContactLocalRepository>((ref) {
  return getIt<ContactLocalRepository>();
});
