import 'package:iamhere/friend/repository/contact_local_repository.dart';
import 'package:iamhere/shared/infrastructure/di/di_setup.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'contact_local_repository_provider.g.dart';

@riverpod
ContactLocalRepository contactLocalRepository(Ref ref) {
  return getIt<ContactLocalRepository>();
}
