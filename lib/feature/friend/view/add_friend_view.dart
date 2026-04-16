import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/core/di/di_setup.dart';
import 'package:iamhere/feature/friend/service/dto/user_search_response_dto.dart';
import 'package:iamhere/feature/friend/service/user_search_service_interface.dart';
import 'package:iamhere/feature/friend/view_model/contact_view_model_provider.dart';

class AddFriendView extends ConsumerStatefulWidget {
  const AddFriendView({super.key});

  @override
  ConsumerState<AddFriendView> createState() => _AddFriendViewState();
}

class _AddFriendViewState extends ConsumerState<AddFriendView> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  List<UserSearchResponseDto>? _searchResults;
  String? _errorMessage;

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
            if (_searchResults != null) _buildSearchResults(context, cs),
            if (_searchResults == null) _buildTipCard(context, cs),
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
          '닉네임으로 검색하세요',
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
                          hintText: '닉네임 입력',
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
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = null;
                            _errorMessage = null;
                          });
                        },
                        child: Padding(
                          padding: EdgeInsets.only(right: 12.w),
                          child: Icon(
                            Icons.close,
                            size: 18.r,
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
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

  // ── 검색 결과 리스트 ─────────────────────────────────────────────────
  Widget _buildSearchResults(BuildContext context, ColorScheme cs) {
    final results = _searchResults!;

    if (_errorMessage != null) {
      return _buildResultMessage(
        cs,
        icon: Icons.error_outline,
        message: _errorMessage!,
        color: cs.error,
      );
    }

    if (results.isEmpty) {
      return _buildResultMessage(
        cs,
        icon: Icons.search_off,
        message: '검색 결과가 없습니다',
        color: cs.onSurface.withValues(alpha: 0.45),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: Text(
            '검색 결과 (${results.length}명)',
            style: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 13.sp,
              color: cs.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ),
        ...results.map((user) => _buildUserResultTile(context, cs, user)),
      ],
    );
  }

  Widget _buildResultMessage(
    ColorScheme cs, {
    required IconData icon,
    required String message,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 32.h),
      child: Column(
        children: [
          Icon(icon, size: 40.r, color: color),
          SizedBox(height: 12.h),
          Text(
            message,
            style: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 15.sp,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ── 유저 검색 결과 타일 ───────────────────────────────────────────────
  Widget _buildUserResultTile(
    BuildContext context,
    ColorScheme cs,
    UserSearchResponseDto user,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: cs.onSurface.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 프로필 아바타
          CircleAvatar(
            radius: 22.r,
            backgroundColor: cs.primary.withValues(alpha: 0.12),
            child: Text(
              user.userNickname.isNotEmpty ? user.userNickname[0] : '?',
              style: TextStyle(
                fontFamily: 'GmarketSans',
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: cs.primary,
              ),
            ),
          ),
          SizedBox(width: 14.w),
          // 유저 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.userNickname,
                  style: TextStyle(
                    fontFamily: 'BMHANNAAir',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  user.userEmail,
                  style: TextStyle(
                    fontFamily: 'BMHANNAAir',
                    fontSize: 12.sp,
                    color: cs.onSurface.withValues(alpha: 0.5),
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
          // 친구 추가 버튼
          SizedBox(
            height: 36.h,
            child: ElevatedButton(
              onPressed: () => _onAddFriend(context, user),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                '추가',
                style: TextStyle(
                  fontFamily: 'BMHANNAAir',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
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
  Future<void> _onSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final service = getIt<UserSearchServiceInterface>();
      final results = await service.searchByNickname(query);

      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _searchResults = results;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _searchResults = [];
        _errorMessage = '검색 중 오류가 발생했습니다';
      });
    }
  }

  // ── 친구 추가 ────────────────────────────────────────────────────────
  void _onAddFriend(BuildContext context, UserSearchResponseDto user) {
    // TODO: 친구 추가 API 연동
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${user.userNickname}님에게 친구 요청을 보냈습니다')),
    );
  }
}
