enum AgreementAction { consent, withdraw }

/// 서버가 남기는 동의 이력 한 줄. 같은 약관에 대해 여러 줄이 쌓이므로,
/// 현재 동의 상태는 termId별 가장 최근 줄의 action으로 판단한다.
class AgreementHistoryEntry {
  final int termId;
  final AgreementAction action;
  final String occurredAt;

  const AgreementHistoryEntry({
    required this.termId,
    required this.action,
    required this.occurredAt,
  });

  bool get isAgreed => action == AgreementAction.consent;

  factory AgreementHistoryEntry.fromJson(Map<String, dynamic> json) =>
      AgreementHistoryEntry(
        termId: (json['termId'] as num).toInt(),
        action: json['action'] == 'CONSENT'
            ? AgreementAction.consent
            : AgreementAction.withdraw,
        occurredAt: json['occurredAt'] as String? ?? '',
      );
}
