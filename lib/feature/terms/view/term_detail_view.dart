import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/terms/service/dto/terms_list_request_dto.dart';
import 'package:iamhere/feature/terms/view_model/terms_list_view_model.dart';

class TermDetailView extends ConsumerWidget {
  final int termId;

  const TermDetailView({super.key, required this.termId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final termsAsync = ref.watch(termsListViewModelProvider);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('약관 상세', style: tt.headlineSmall),
        centerTitle: true,
      ),
      body: termsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Text('약관을 불러오지 못했습니다', style: tt.bodyMedium),
        ),
        data: (terms) {
          TermsListRequestDto? term;
          for (final item in terms) {
            if (item.id == termId) {
              term = item;
              break;
            }
          }

          if (term == null) {
            return Center(
              child: Text('약관을 찾을 수 없습니다', style: tt.bodyMedium),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DetailCard(title: '제목', value: term.title, cs: cs),
                SizedBox(height: 12.h),
                _DetailCard(
                  title: '내용',
                  value: term.content,
                  cs: cs,
                  multiline: true,
                ),
                SizedBox(height: 12.h),
                _DetailCard(title: '버전', value: term.version.toString(), cs: cs),
                SizedBox(height: 12.h),
                _DetailCard(
                  title: '시행일',
                  value: _formatDate(term.effectiveDate),
                  cs: cs,
                ),
                SizedBox(height: 12.h),
                _DetailCard(
                  title: '필수 여부',
                  value: term.isRequired ? '필수' : '선택',
                  cs: cs,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year}.${local.month.toString().padLeft(2, '0')}.${local.day.toString().padLeft(2, '0')}';
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final String value;
  final ColorScheme cs;
  final bool multiline;

  const _DetailCard({
    required this.title,
    required this.value,
    required this.cs,
    this.multiline = false,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: tt.labelLarge?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: tt.bodyLarge,
            maxLines: multiline ? null : 3,
            overflow: multiline ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
