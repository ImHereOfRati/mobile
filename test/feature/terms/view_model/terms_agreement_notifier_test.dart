import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/terms/view_model/terms_agreement_notifier.dart';
import 'package:iamhere/terms/view_model/terms_agreement_provider.dart';

void main() {
  group('TermsAgreementNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('초기 상태는 빈 맵이어야 함', () {
      final state = container.read(termsAgreementProvider);
      expect(state, <int, bool>{});
    });

    test('toggleAgreement는 약관 동의 상태를 토글해야 함', () {
      // Act
      container.read(termsAgreementProvider.notifier).toggleAgreement(1);

      // Assert
      expect(container.read(termsAgreementProvider)[1], true);

      // Act - 다시 토글
      container.read(termsAgreementProvider.notifier).toggleAgreement(1);

      // Assert
      expect(container.read(termsAgreementProvider)[1], false);
    });

    test('isTermAgreed는 특정 약관의 동의 여부를 반환해야 함', () {
      // Arrange
      container.read(termsAgreementProvider.notifier).toggleAgreement(1);
      container.read(termsAgreementProvider.notifier).toggleAgreement(2);

      // Act & Assert
      final notifier = container.read(termsAgreementProvider.notifier);
      expect(notifier.isTermAgreed(1), true);
      expect(notifier.isTermAgreed(2), true);
      expect(notifier.isTermAgreed(3), false);
    });

    test('reset은 모든 동의 상태를 초기화해야 함', () {
      // Arrange
      container.read(termsAgreementProvider.notifier).toggleAgreement(1);
      container.read(termsAgreementProvider.notifier).toggleAgreement(2);
      expect(container.read(termsAgreementProvider), hasLength(2));

      // Act
      container.read(termsAgreementProvider.notifier).reset();

      // Assert
      expect(container.read(termsAgreementProvider), <int, bool>{});
    });

    test('setAgreedTerms는 지정된 약관들을 일괄 동의 처리해야 함', () {
      // Act
      container.read(termsAgreementProvider.notifier).setAgreedTerms([1, 2, 3]);

      // Assert
      final state = container.read(termsAgreementProvider);
      expect(state[1], true);
      expect(state[2], true);
      expect(state[3], true);
      expect(state.length, 3);
    });

    test('getAgreedTermIds는 동의한 약관의 ID 목록을 반환해야 함', () {
      // Arrange
      container.read(termsAgreementProvider.notifier).toggleAgreement(1);
      container.read(termsAgreementProvider.notifier).toggleAgreement(3);
      container.read(termsAgreementProvider.notifier).toggleAgreement(5);

      // Act
      final agreedIds = container
          .read(termsAgreementProvider.notifier)
          .getAgreedTermIds();

      // Assert
      expect(agreedIds, containsAll([1, 3, 5]));
      expect(agreedIds, hasLength(3));
    });
  });

  group('allRequiredTermsAgreed provider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('모든 필수 약관에 동의하면 true를 반환해야 함', () {
      // Arrange
      container.read(termsAgreementProvider.notifier).toggleAgreement(1);
      container.read(termsAgreementProvider.notifier).toggleAgreement(2);

      // Act
      final allAgreed = container.read(allRequiredTermsAgreedProvider([1, 2]));

      // Assert
      expect(allAgreed, true);
    });

    test('필수 약관 중 하나라도 미동의하면 false를 반환해야 함', () {
      // Arrange
      container.read(termsAgreementProvider.notifier).toggleAgreement(1);
      // 약관 2는 동의하지 않음

      // Act
      final allAgreed = container.read(allRequiredTermsAgreedProvider([1, 2]));

      // Assert
      expect(allAgreed, false);
    });

    test('필수 약관이 없으면 true를 반환해야 함', () {
      // Act
      final allAgreed = container.read(allRequiredTermsAgreedProvider([]));

      // Assert
      expect(allAgreed, true);
    });

    test('동의하지 않은 약관이 있으면 false를 반환해야 함', () {
      // Arrange
      container.read(termsAgreementProvider.notifier).toggleAgreement(1);

      // Act
      final allAgreed = container.read(
        allRequiredTermsAgreedProvider([1, 2, 3]),
      );

      // Assert
      expect(allAgreed, false);
    });
  });
}
