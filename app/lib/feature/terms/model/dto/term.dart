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
