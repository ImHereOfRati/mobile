import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:iamhere/terms/service/terms_list_request_service.dart';
import 'package:iamhere/terms/service/terms_version_response.dart';

class TermsDetailView extends ConsumerStatefulWidget {
  final int termDefinitionId;
  const TermsDetailView({super.key, required this.termDefinitionId});

  @override
  ConsumerState<TermsDetailView> createState() => _TermsDetailViewState();
}

class _TermsDetailViewState extends ConsumerState<TermsDetailView> {
  late final TermsListRequestService _service;
  late Future<TermsVersionResponse> _future;

  @override
  void initState() {
    super.initState();
    _service = GetIt.instance<TermsListRequestService>();
    _future = _service.requestTermsDetail(widget.termDefinitionId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F7),
        elevation: 0,
        centerTitle: true,
        title: Text(
          '약관 상세',
          style: TextStyle(
            fontFamily: 'GmarketSans',
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1D1D1F),
            letterSpacing: -0.374,
          ),
        ),
      ),
      body: FutureBuilder<TermsVersionResponse>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0071E3)),
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _buildError();
          }
          return _buildContent(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 56, color: Color(0xFF6E6E73)),
            SizedBox(height: 20.h),
            Text(
              '약관을 불러올 수 없습니다',
              style: TextStyle(
                fontFamily: 'GmarketSans',
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1D1D1F),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '네트워크 연결을 확인하고 다시 시도해주세요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'BMHANNAAir',
                fontSize: 14.sp,
                color: const Color(0xFF6E6E73),
              ),
            ),
            SizedBox(height: 28.h),
            TextButton(
              onPressed: () => setState(() {
                _future = _service.requestTermsDetail(widget.termDefinitionId);
              }),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF0071E3),
              ),
              child: Text('다시 시도 →', style: TextStyle(fontSize: 14.sp)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(TermsVersionResponse data) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 버전 카드
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Text(
                  'v${data.version}',
                  style: TextStyle(
                    fontFamily: 'BMHANNAAir',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0071E3),
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(width: 10.w),
                Text(
                  data.effectiveDate.toString(),
                  style: TextStyle(
                    fontFamily: 'BMHANNAAir',
                    fontSize: 12.sp,
                    color: const Color(0xFF6E6E73),
                    letterSpacing: -0.12,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          // 본문
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              data.content,
              style: TextStyle(
                fontFamily: 'BMHANNAAir',
                fontSize: 15.sp,
                color: const Color(0xFF1D1D1F),
                letterSpacing: -0.3,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
