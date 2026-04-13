import 'package:get_it/get_it.dart';
import 'package:iamhere/terms/service/dto/terms_list_request_dto.dart';
import 'package:iamhere/terms/service/terms_request_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'terms_list_view_model.g.dart';

/// ViewModel for fetching terms list from server
@riverpod
class TermsListViewModel extends _$TermsListViewModel {
  late TermsRequestService _service;

  @override
  Future<List<TermsListRequestDto>> build() async {
    _service = GetIt.instance<TermsRequestService>();
    final apiResponse = await _service.requestTermsList();
    return apiResponse.data.content;
  }

  /// Refresh terms list
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final apiResponse = await _service.requestTermsList();
      return apiResponse.data.content;
    });
  }
}
