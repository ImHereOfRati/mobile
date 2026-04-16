import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/feature/friend/view_model/contact_view_model_provider.dart';

class AddFriendView extends ConsumerStatefulWidget {
  const AddFriendView({super.key});

  @override
  ConsumerState<AddFriendView> createState() => _AddFriendViewState();
}

class _AddFriendViewState extends ConsumerState<AddFriendView> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16.h),
            _buildPageHeader(context, cs),
            SizedBox(height: 24.h),
            _buildImportFromContactsButton(context),
            SizedBox(height: 20.h),
            _buildOrDivider(context, cs),
            SizedBox(height: 20.h),
            _buildSearchSection(context, cs),
            SizedBox(height: 16.h),
            _buildTipCard(context, cs),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  // ── 페이지 헤더 (뒤로가기 + 제목) ───────────────────────────────────
  Widget _buildPageHeader(BuildContext context, ColorScheme cs) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => context.pop(),
          child: Icon(Icons.chevron_left, size: 28.r, color: cs.onSurface),
        ),
        SizedBox(width: 4.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '친구 추가',
              style: TextStyle(
                fontFamily: 'GmarketSans',
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              '새로운 친구를 추가해보세요',
              style: TextStyle(
                fontFamily: 'BMHANNAAir',
                fontSize: 13.sp,
                color: cs.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── 연락처에서 가져오기 ──────────────────────────────────────────────
  Widget _buildImportFromContactsButton(BuildContext context) {
    final vmInterface = ref.read(contactViewModelInterfaceProvider);
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: ElevatedButton.icon(
        onPressed: () async {
          final result = await vmInterface.selectContact();
          if (!context.mounted) return;
          if (result != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${result.name}님이 친구로 추가되었습니다!')),
            );
            context.pop();
          }
        },
        icon: Icon(Icons.contacts_outlined, size: 20.r),
        label: Text(
          '연락처에서 가져오기',
          style: TextStyle(
            fontFamily: 'BMHANNAAir',
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }

  // ── 또는 구분선 ──────────────────────────────────────────────────────
  Widget _buildOrDivider(BuildContext context, ColorScheme cs) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: cs.onSurface.withValues(alpha: 0.15),
            thickness: 0.8,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Text(
            '또는',
            style: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 13.sp,
              color: cs.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: cs.onSurface.withValues(alpha: 0.15),
            thickness: 0.8,
          ),
        ),
      ],
    );
  }

  // ── 친구 검색 섹션 ───────────────────────────────────────────────────
  Widget _buildSearchSection(BuildContext context, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '친구 검색',
          style: TextStyle(
            fontFamily: 'GmarketSans',
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          '이메일 또는 닉네임으로 검색하세요',
          style: TextStyle(
            fontFamily: 'BMHANNAAir',
            fontSize: 13.sp,
            color: cs.onSurface.withValues(alpha: 0.55),
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 48.h,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    SizedBox(width: 12.w),
                    Icon(
                      Icons.search,
                      size: 20.r,
                      color: cs.onSurface.withValues(alpha: 0.4),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(
                          fontFamily: 'BMHANNAAir',
                          fontSize: 18.sp,
                          color: cs.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: '이메일 또는 닉네임 입력',
                          hintStyle: TextStyle(
                            fontFamily: 'BMHANNAAir',
                            fontSize: 20.sp,
                            color: cs.onSurface.withValues(alpha: 0.35),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onSubmitted: (_) => _onSearch(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 8.w),
            SizedBox(
              height: 48.h,
              child: ElevatedButton(
                onPressed: _isSearching ? null : _onSearch,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: _isSearching
                    ? SizedBox(
                        width: 16.r,
                        height: 16.r,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        '검색',
                        style: TextStyle(
                          fontFamily: 'BMHANNAAir',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── 팁 카드 ─────────────────────────────────────────────────────────
  Widget _buildTipCard(BuildContext context, ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('💡', style: TextStyle(fontSize: 14.sp)),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'Tip: 연락처에서 가져오면 전화번호로 친구를 빠르게 추가할 수 있어요!',
              style: TextStyle(
                fontFamily: 'BMHANNAAir',
                fontSize: 13.sp,
                color: cs.onSurface.withValues(alpha: 0.65),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 검색 실행 ────────────────────────────────────────────────────────
  void _onSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSearching = true);

    // TODO: 서버 친구 검색 API 연동
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _isSearching = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('"$query" 검색 결과가 없습니다.')));
    });
  }
}
