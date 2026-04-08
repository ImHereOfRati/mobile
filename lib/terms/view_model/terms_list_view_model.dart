import 'package:get_it/get_it.dart';
import 'package:iamhere/terms/service/dto/terms_list_request_dto.dart';
import 'package:iamhere/terms/service/terms_list_request_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'terms_list_view_model.g.dart';

@riverpod
class TermsListViewModel extends _$TermsListViewModel {
  final _termsService = GetIt.I<TermsListRequestService>();

  @override
  Future<List<TermsListRequestDto>> build() async {
    final response = await _termsService.requestTermsList();
    return response.data.content;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final response = await _termsService.requestTermsList();
      return response.data.content;
    });
  }
}
