import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/terms/service/dto/terms_list_request_dto.dart';
import 'package:iamhere/terms/view_model/terms_agreement_notifier.dart';
import 'package:iamhere/terms/view_model/terms_agreement_provider.dart'
    hide termsAgreementProvider;
import 'package:iamhere/terms/view_model/terms_list_view_model.dart';

class TermsListView extends ConsumerWidget {
  const TermsListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final termsAsync = ref.watch(termsListViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('약관 동의'), centerTitle: true),
      body: termsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _buildErrorState(context, ref),
        data: (terms) => _buildSuccessState(context, ref, terms),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              '약관을 불러올 수 없습니다',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '네트워크 연결을 확인하고 다시 시도해주세요',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(termsListViewModelProvider);
              },
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessState(
    BuildContext context,
    WidgetRef ref,
    List<TermsListRequestDto> terms,
  ) {
    final requiredTermIds = terms
        .where((term) => term.isRequired)
        .map((term) => term.termDefinitionId)
        .toList();
    final allRequiredAgreed = ref.watch(
      allRequiredTermsAgreedProvider(requiredTermIds),
    );

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: terms.length,
            itemBuilder: (context, index) {
              final term = terms[index];
              return _buildTermItem(context, ref, term);
            },
          ),
        ),
        _buildActionArea(context, allRequiredAgreed),
      ],
    );
  }

  Widget _buildTermItem(
    BuildContext context,
    WidgetRef ref,
    TermsListRequestDto term,
  ) {
    final isAgreed = ref.watch(
      termsAgreementProvider.select(
        (agreements) => agreements[term.termDefinitionId] ?? false,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          leading: Checkbox(
            value: isAgreed,
            onChanged: (_) {
              ref
                  .read(termsAgreementProvider.notifier)
                  .toggleAgreement(term.termDefinitionId);
            },
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  term.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              if (term.isRequired)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '필수',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              context.push('/terms-detail/${term.termDefinitionId}');
            },
          ),
          onTap: () {
            ref
                .read(termsAgreementProvider.notifier)
                .toggleAgreement(term.termDefinitionId);
          },
        ),
      ),
    );
  }

  Widget _buildActionArea(BuildContext context, bool allRequiredAgreed) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!allRequiredAgreed)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                '모든 필수 약관에 동의해주세요',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 56.h,
            child: ElevatedButton(
              onPressed: allRequiredAgreed
                  ? () {
                      context.go('/geofence');
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                disabledBackgroundColor: Colors.grey[400],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.h),
                ),
              ),
              child: Text(
                '동의',
                style: TextStyle(
                  color: allRequiredAgreed ? Colors.white : Colors.grey[600],
                  fontSize: 16.h,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
