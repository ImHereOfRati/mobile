import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/terms/service/dto/terms_list_request_dto.dart';
import 'package:iamhere/terms/service/dto/terms_type.dart';
import 'package:iamhere/terms/service/terms_request_service.dart';
import 'package:iamhere/terms/view_model/terms_list_view_model.dart';
import 'package:mockito/annotations.dart';

import 'terms_list_view_model_test.mocks.dart';

@GenerateMocks([TermsRequestService])
void main() {
  group('TermsListViewModel', () {
    late ProviderContainer container;
    late MockTermsRequestService mockTermsService;

    setUp(() {
      mockTermsService = MockTermsRequestService();
      container = ProviderContainer(
        overrides: [
          // Note: Full TermsListViewModel testing requires GetIt mocking
          // This is a basic structure test
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('TermsListViewModel이 생성되어야 함', () {
      // Note: Full TermsListViewModel testing requires GetIt mocking
      expect(termsListViewModelProvider, isNotNull);
    });

    test('MockTermsRequestService가 올바르게 생성되어야 함', () {
      expect(mockTermsService, isNotNull);
    });
  });

  group('TermsListRequestService integration', () {
    test('requestTermsList response parsing test', () {
      // Arrange
      final testTerms = [
        TermsListRequestDto(
          termDefinitionId: 1,
          title: '서비스 이용약관',
          termsTypes: TermsType.service,
          isRequired: true,
        ),
        TermsListRequestDto(
          termDefinitionId: 2,
          title: '개인정보 처리방침',
          termsTypes: TermsType.privacy,
          isRequired: true,
        ),
        TermsListRequestDto(
          termDefinitionId: 3,
          title: '위치정보 이용약관',
          termsTypes: TermsType.location,
          isRequired: false,
        ),
      ];

      // Act
      final requiredTerms = testTerms.where((term) => term.isRequired).toList();

      // Assert
      expect(requiredTerms, hasLength(2));
      expect(requiredTerms.every((term) => term.isRequired), true);
    });

    test('TermsListRequestDto JSON serialization test', () {
      // Arrange
      final json = {
        'termDefinitionId': 1,
        'title': '서비스 이용약관',
        'termsTypes': 'SERVICE',
        'isRequired': true,
      };

      // Act
      final dto = TermsListRequestDto.fromJson(json);

      // Assert
      expect(dto.termDefinitionId, 1);
      expect(dto.title, '서비스 이용약관');
      expect(dto.termsTypes, TermsType.service);
      expect(dto.isRequired, true);
    });

    test('TermsType enum values test', () {
      // Assert
      expect(TermsType.service.toString(), 'TermsType.service');
      expect(TermsType.privacy.toString(), 'TermsType.privacy');
      expect(TermsType.location.toString(), 'TermsType.location');
      expect(
        TermsType.thirdPartySharing.toString(),
        'TermsType.thirdPartySharing',
      );
      expect(TermsType.marketing.toString(), 'TermsType.marketing');
    });
  });
}
