import 'package:dio/dio.dart';
import 'package:iamhere/feature/terms/model/dto/agreement_history_entry.dart';
import 'package:iamhere/feature/terms/model/dto/term.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class TermsRepository {
  static const _termsPath = '/api/terms';
  static const _agreementPath = '/api/agreements';

  TermsRepository(this._dio);

  final Dio _dio;

  static final _authenticated = Options(
    extra: const {'requiresAuthentication': true},
  );

  Future<List<Term>> fetchActiveTerms() async {
    final response = await _dio.get(
      _termsPath,
      queryParameters: const {'isActive': true},
    );
    return _dataList(response.data, '약관').map(Term.fromJson).toList();
  }

  Future<List<AgreementHistoryEntry>> fetchAgreementHistory() async {
    final response = await _dio.get(_agreementPath, options: _authenticated);
    return _dataList(
      response.data,
      '동의 내역',
    ).map(AgreementHistoryEntry.fromJson).toList();
  }

  Future<void> consent(int termId) async {
    await _dio.post<void>(
      _agreementPath,
      data: {
        'consents': [
          {'id': termId, 'agreed': true},
        ],
      },
      options: _authenticated,
    );
  }

  Future<void> consentToRenewal(int termId) async {
    await _dio.post<void>(
      '$_agreementPath/renewals/$termId',
      options: _authenticated,
    );
  }

  Future<void> withdraw(int termId) async {
    await _dio.delete<void>('$_agreementPath/$termId', options: _authenticated);
  }

  static List<Map<String, dynamic>> _dataList(dynamic raw, String label) {
    if (raw is! Map<String, dynamic> || raw['data'] is! List) {
      throw StateError('$label 응답 형식이 올바르지 않습니다.');
    }
    return (raw['data'] as List).whereType<Map<String, dynamic>>().toList(
      growable: false,
    );
  }
}
