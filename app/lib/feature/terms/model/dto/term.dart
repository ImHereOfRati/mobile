class Term {
  final int id;
  final String title;
  final String content;
  final String type;
  final bool isRequired;
  final int version;
  final String effectiveDate;

  const Term({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.isRequired,
    required this.version,
    required this.effectiveDate,
  });

  bool get isMarketing => type == 'MARKETING';

  /// 시행일을 일 단위(yyyy-MM-dd)까지만 보여 준다. 비교에는 [effectiveDate] 원본을 쓴다.
  String get effectiveDay => effectiveDate.length >= 10
      ? effectiveDate.substring(0, 10)
      : effectiveDate;

  factory Term.fromJson(Map<String, dynamic> json) => Term(
    id: (json['id'] as num).toInt(),
    title: json['title'] as String? ?? '',
    content: json['content'] as String? ?? '',
    type: json['type'] as String? ?? '',
    isRequired: json['isRequired'] as bool? ?? false,
    version: (json['version'] as num?)?.toInt() ?? 1,
    effectiveDate: json['effectiveDate'] as String? ?? '',
  );
}
