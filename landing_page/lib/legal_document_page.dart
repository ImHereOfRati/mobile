import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:iamhere/components/components.dart';

enum LegalDocumentType {
  privacy('PRIVACY', '개인정보처리방침'),
  terms('SERVICE', '서비스 약관');

  const LegalDocumentType(this.apiType, this.defaultTitle);
  final String apiType;
  final String defaultTitle;

  static LegalDocumentType? fromQuery(String? query) => switch (query) {
    'privacy' => LegalDocumentType.privacy,
    'terms' => LegalDocumentType.terms,
    _ => null,
  };
}

class LegalTermDocument {
  const LegalTermDocument({
    required this.type,
    required this.title,
    required this.content,
    required this.effectiveDate,
    required this.version,
  });

  final String type;
  final String title;
  final String content;
  final String effectiveDate;
  final int version;

  factory LegalTermDocument.fromJson(Map<String, dynamic> json) =>
      LegalTermDocument(
        type: (json['type'] as String?) ?? '',
        title: (json['title'] as String?) ?? '문서',
        content: (json['content'] as String?) ?? '',
        effectiveDate: (json['effectiveDate'] as String?) ?? '',
        version: (json['version'] as num?)?.toInt() ?? 1,
      );
}

typedef LegalTermFetcher =
    Future<LegalTermDocument> Function(LegalDocumentType type);

const kDefaultApiOrigin = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://imhere.ratiko.co.kr',
);

Future<LegalTermDocument> fetchActiveLegalTerm(
  LegalDocumentType documentType, {
  Dio? dio,
  String apiOrigin = kDefaultApiOrigin,
}) async {
  final client = dio ?? Dio();
  final uri = Uri.parse(apiOrigin).replace(
    path: '/api/terms',
    queryParameters: const {'isActive': 'true', 'v': '1'},
  );
  final response = await client.getUri<Map<String, dynamic>>(uri);
  final list = response.data?['data'];
  if (list is! List) {
    throw StateError('약관 목록 응답 형식이 올바르지 않습니다.');
  }
  for (final item in list) {
    if (item is Map<String, dynamic> && item['type'] == documentType.apiType) {
      return LegalTermDocument.fromJson(item);
    }
  }
  throw StateError('해당 약관을 찾을 수 없습니다.');
}

class LegalDocumentSection extends StatefulWidget {
  const LegalDocumentSection({
    super.key,
    required this.documentType,
    required this.onBackToHome,
    this.termFetcher,
  });

  final LegalDocumentType documentType;
  final VoidCallback onBackToHome;
  final LegalTermFetcher? termFetcher;

  @override
  State<LegalDocumentSection> createState() => _LegalDocumentSectionState();
}

class _LegalDocumentSectionState extends State<LegalDocumentSection> {
  LegalTermDocument? _document;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(LegalDocumentSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.documentType != widget.documentType ||
        oldWidget.termFetcher != widget.termFetcher) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final fetcher = widget.termFetcher ?? fetchActiveLegalTerm;
      final doc = await fetcher(widget.documentType);
      if (!mounted) return;
      setState(() {
        _document = doc;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  List<({String heading, String body})> _splitSections(String content) {
    final blocks = content
        .split(RegExp(r'\n(?=\d+\.\s)'))
        .map((section) => section.trim())
        .where((section) => section.isNotEmpty)
        .toList();
    if (blocks.isEmpty && content.trim().isNotEmpty) {
      return [(heading: '본문', body: content.trim())];
    }
    return blocks.map((section) {
      final newlineIndex = section.indexOf('\n');
      if (newlineIndex < 0) {
        return (heading: section, body: '');
      }
      return (
        heading: section.substring(0, newlineIndex).trim(),
        body: section.substring(newlineIndex + 1).trim(),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    final compact = MediaQuery.sizeOf(context).width < 720;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 20 : 32,
            vertical: compact ? 40 : 64,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _document?.title ?? widget.documentType.defaultTitle,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 24),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 64),
                  child: Center(child: ImHereProgress(label: '문서를 불러오는 중입니다.')),
                )
              else if (_error || _document == null)
                ImHereStatePanel(
                  glyph: ImHereGlyph.bell,
                  title: '문서를 불러오지 못했습니다.',
                  description: '네트워크 상태를 확인한 뒤 다시 시도해 주세요.',
                  actionLabel: '다시 시도',
                  onAction: _load,
                  secondaryLabel: '홈으로 돌아가기',
                  onSecondary: widget.onBackToHome,
                )
              else ...[
                Text(
                  '시행일 ${_document!.effectiveDate} · v${_document!.version}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: colors.textMuted),
                ),
                const SizedBox(height: 24),
                for (final section in _splitSections(_document!.content)) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.heading,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (section.body.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            section.body,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: colors.textMuted,
                                  height: 1.6,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                ImHereButton(
                  key: const Key('legal-back-home-button'),
                  label: '홈으로 돌아가기',
                  tone: ImHereButtonTone.weak,
                  onPressed: widget.onBackToHome,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
