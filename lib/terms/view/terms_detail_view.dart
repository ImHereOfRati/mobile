import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:iamhere/shared/base/api_response/api_response.dart';
import 'package:iamhere/terms/service/dto/terms_version_response_dto.dart';
import 'package:iamhere/terms/service/terms_request_service.dart';

class TermsDetailView extends ConsumerStatefulWidget {
  final int termDefinitionId;
  const TermsDetailView({super.key, required this.termDefinitionId});

  @override
  ConsumerState<TermsDetailView> createState() => _TermsDetailViewState();
}

class _TermsDetailViewState extends ConsumerState<TermsDetailView> {
  late final TermsRequestService _service;
  late Future<APIResponse<TermsVersionResponseDto>> _future;

  ColorScheme get _cs => Theme.of(context).colorScheme;

  @override
  void initState() {
    super.initState();
    _service = GetIt.instance<TermsRequestService>();
    _future = _service.requestTermsDetail(widget.termDefinitionId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          '약관 상세',
          style: TextStyle(
            fontFamily: 'GmarketSans',
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
            color: _cs.onSurface,
            letterSpacing: -0.374,
          ),
        ),
      ),
      body: FutureBuilder<APIResponse<TermsVersionResponseDto>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: _cs.primary),
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _buildError();
          }
          return _buildContent(snapshot.data!.data);
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
            Icon(
              Icons.wifi_off_rounded,
              size: 56,
              color: _cs.onSurface.withValues(alpha: 0.4),
            ),
            SizedBox(height: 20.h),
            Text(
              '약관을 불러올 수 없습니다',
              style: TextStyle(
                fontFamily: 'GmarketSans',
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: _cs.onSurface,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '네트워크 연결을 확인하고 다시 시도해주세요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'BMHANNAAir',
                fontSize: 14.sp,
                color: _cs.onSurface.withValues(alpha: 0.55),
              ),
            ),
            SizedBox(height: 28.h),
            TextButton(
              onPressed: () => setState(() {
                _future = _service.requestTermsDetail(widget.termDefinitionId);
              }),
              child: Text('다시 시도 →', style: TextStyle(fontSize: 14.sp)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(TermsVersionResponseDto data) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 버전 카드
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: _cs.surface,
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
                    color: _cs.primary,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(width: 10.w),
                Text(
                  data.effectiveDate.toString(),
                  style: TextStyle(
                    fontFamily: 'BMHANNAAir',
                    fontSize: 12.sp,
                    color: _cs.onSurface.withValues(alpha: 0.55),
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
              color: _cs.surface,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: _cs.onSurface.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              data.content,
              style: TextStyle(
                fontFamily: 'BMHANNAAir',
                fontSize: 15.sp,
                color: _cs.onSurface,
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
