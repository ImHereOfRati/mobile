import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

class Term {
  final int id;
  final String title;
  final String content;
  final String type;
  final bool isRequired;

  const Term({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.isRequired,
  });

  factory Term.fromJson(Map<String, dynamic> json) => Term(
    id: (json['id'] as num).toInt(),
    title: json['title'] as String? ?? '',
    content: json['content'] as String? ?? '',
    type: json['type'] as String? ?? '',
    isRequired: json['isRequired'] as bool? ?? false,
  );
}

@lazySingleton
class TermsService {
  final Dio _dio;

  TermsService(this._dio);

  Future<List<Term>> loadActiveTerms() async {
    final response = await _dio.get('/api/terms?isActive=true');
    final data = response.data;
    if (data is! Map<String, dynamic> || data['data'] is! List) {
      throw StateError('약관 응답 형식이 올바르지 않습니다.');
    }
    return (data['data'] as List)
        .whereType<Map<String, dynamic>>()
        .map(Term.fromJson)
        .toList(growable: false);
  }
}
