import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:iamhere/terms/service/terms_list_request_service.dart';

import '../service/terms_version_response.dart';

class TermsDetailView extends ConsumerStatefulWidget {
  final int termDefinitionId;

  const TermsDetailView({super.key, required this.termDefinitionId});

  @override
  ConsumerState<TermsDetailView> createState() => _TermsDetailViewState();
}

class _TermsDetailViewState extends ConsumerState<TermsDetailView> {
  late final TermsListRequestService _service;
  late Future<TermsVersionResponse> _termDetailFuture;

  @override
  void initState() {
    super.initState();
    _service = GetIt.instance<TermsListRequestService>();
    _termDetailFuture = _service.requestTermsDetail(widget.termDefinitionId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('약관 상세'), centerTitle: true),
      body: FutureBuilder<TermsVersionResponse>(
        future: _termDetailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorState(context);
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('약관 정보를 불러올 수 없습니다'));
          }

          final termsVersion = snapshot.data!;
          return _buildContent(context, termsVersion);
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
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
                setState(() {
                  _termDetailFuture = _service.requestTermsDetail(
                    widget.termDefinitionId,
                  );
                });
              },
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    TermsVersionResponse termsVersion,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Version info
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'v${termsVersion.version}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  termsVersion.effectiveDate.toString(),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          // Content
          Text(
            termsVersion.content,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }
}
