import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:iamhere/friend/repository/contact_local_repository_provider.dart';
import 'package:iamhere/friend/view_model/contact.dart';
import 'package:iamhere/friend/view_model/contact_adapter.dart';
import 'package:iamhere/friend/view_model/contact_view_model_interface.dart';
import 'package:iamhere/shared/infrastructure/di/di_setup.dart';
import 'package:iamhere/user_permission/service/permission_service_interface.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../repository/contact_repository.dart';

part 'contact_view_model.g.dart';

@riverpod
class ContactViewModel extends _$ContactViewModel
    implements ContactViewModelInterface {
  late ContactRepository _repository;

  /// AsyncNotifierProvider 초기화
  @override
  Future<List<Contact>> build() async {
    _repository = ref.watch(contactLocalRepositoryProvider);

    final foundEntities = await _repository.findAll();
    return foundEntities.map((entity) {
      return ContactAdapter.toClass(entity);
    }).toList();
  }

  static const channelName = 'com.iamhere.app/contacts';
  static const methodChannel = MethodChannel(channelName);

  ///methodChannel (Native Linking Code)
  @override
  Future<Contact?> selectContact() async {
    final contactPermissionService = getIt<PermissionServiceInterface>(
      instanceName: 'friend',
    );
    await contactPermissionService.checkPermissionStatus();

    try {
      final Map<dynamic, dynamic>? result = await methodChannel.invokeMethod(
        'selectContact',
      );

      if (result != null) {
        final contact = Contact.fromJson(Map<String, dynamic>.from(result));

        final savedEntity = await _repository.save(
          ContactAdapter.toEntity(contact),
        );
        final savedContact = ContactAdapter.toClass(savedEntity);

        state = AsyncValue.data([...state.value!, savedContact]);

        return savedContact;
      }
    } on PlatformException catch (e) {
      log("네이티브에서 연락처 선택 실패 : [이유] -> $e");
      throw Exception("연락처 선택에 실패하였습니다");
    }
    return null;
  }

  @override
  Future<void> deleteContact(int id) async {
    if (!state.hasValue) {
      return;
    }

    final previousState = state;
    final originalList = state.value!;

    try {
      final updatedList = originalList.where((c) => c.id != id).toList();
      state = AsyncValue.data(updatedList);

      await _repository.delete(id);
    } catch (e) {
      state = previousState;
      log('연락처 삭제 실패 및 롤백: $e');
    }
  }
}
