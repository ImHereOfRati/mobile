import 'package:get_it/get_it.dart';
import 'package:iamhere/feature/auth/service/token_storage_service.dart';
import 'package:iamhere/feature/terms/service/dto/after_terms_agreement_auth_response_dto.dart';
import 'package:iamhere/feature/terms/service/dto/terms_consent_request_dto.dart';
import 'package:iamhere/feature/terms/service/dto/terms_list_request_dto.dart';
import 'package:iamhere/feature/terms/service/terms_response_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'terms_consent_view_model.g.dart';

@riverpod
class TermsConsentViewModel extends _$TermsConsentViewModel {
  @override
  AsyncValue<AfterTermsAgreementAuthResponseDto?> build() {
    return const AsyncValue.data(null);
  }

  /// [terms] 전체 약관 목록, [agreementsMap] 동의 여부 맵 (id -> agreed)
  Future<void> submitConsents(
    List<TermsListRequestDto> terms,
    Map<int, bool> agreementsMap,
  ) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final consents = terms
          .map(
            (term) => TermsConsentItemDto(
              id: term.id,
              agreed: agreementsMap[term.id] ?? false,
            ),
          )
          .toList();

      final responseService = GetIt.instance<TermsResponseService>();
      final response = await responseService
          .requestToAllAgreeAboutRequiredTerms(consents);

      final dto = response.data;
      if (dto == null) {
        throw StateError('terms consent response data is null');
      }
      final tokenStorage = GetIt.instance<TokenStorageService>();
      await tokenStorage.saveAccessToken(dto.accessToken);
      await tokenStorage.saveRefreshToken(dto.refreshToken);
      await tokenStorage.saveAuthSnapshot(
        userStatus: dto.userStatus ?? 'ACTIVE',
        isActive: dto.isActive ?? true,
      );

      return dto;
    });
  }
}
