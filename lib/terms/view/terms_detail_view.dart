import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iamhere/terms/service/terms_list_request_service.dart';
import 'package:iamhere/terms/service/terms_version_response.dart';
import 'package:get_it/get_it.dart';

class TermsDetailView extends ConsumerWidget {
  final int termDefinitionId;

  const TermsDetailView({
    super.key,
    required this.termDefinitionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<TermsVersionResponse>(
      future: GetIt.I<TermsListRequestService>()
          .requestTermsDetail(termDefinitionId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('약관')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      '약관을 불러올 수 없습니다',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('뒤로 가기'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final terms = snapshot.data!;
        return _buildTermsContent(context, terms);
      },
    );
  }

  Widget _buildTermsContent(
    BuildContext context,
    TermsVersionResponse terms,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('약관'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Version and effective date info
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'v${terms.version}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '시행: ${terms.effectiveDate.year}.${terms.effectiveDate.month.toString().padLeft(2, '0')}.${terms.effectiveDate.day.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            // Divider
            Divider(color: Colors.grey[300]),
            const SizedBox(height: 16),
            // Terms content
            Text(
              terms.content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                    color: Colors.grey[800],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
