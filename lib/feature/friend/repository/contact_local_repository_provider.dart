import 'package:iamhere/infrastructure/di/di_setup.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'contact_local_repository.dart';

part 'contact_local_repository_provider.g.dart';

@riverpod
ContactLocalRepository contactLocalRepository(Ref ref) {
  return getIt<ContactLocalRepository>();
}
