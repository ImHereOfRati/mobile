import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/common/component/feedback/imhere_loading_indicator.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/infrastructure/di/di_setup.dart';
import 'package:iamhere/feature/friend/service/dto/user_search_response_dto.dart';
import 'package:iamhere/feature/friend/service/user_search_service_interface.dart';
import 'package:iamhere/feature/friend/view_model/contact_view_model.dart';
import 'package:iamhere/feature/friend/view_model/contact_view_model_provider.dart';
import 'package:iamhere/feature/friend/view_model/friend_request_view_model.dart';

class AddFriendView extends ConsumerStatefulWidget {
  const AddFriendView({super.key});

  @override
  ConsumerState<AddFriendView> createState() => _AddFriendViewState();
}

class _AddFriendViewState extends ConsumerState<AddFriendView> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  bool _isSearching = false;
  List<UserSearchResponseDto>? _searchResults;
  String? _errorMessage;
  final Set<String> _sentUserIds = {};

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    ref.watch(contactViewModelProvider);

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
            _buildSearchSection(context, cs),
            SizedBox(height: 16.h),
            if (_searchResults != null) ...[
              _buildSearchResults(context, cs),
              SizedBox(height: 24.h),
            ],
            _buildContactImportSection(context, cs),
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

  // ── 검색 섹션 (프리미엄 세련된 Search Bar) ─────────────────────────────
  Widget _buildSearchSection(BuildContext context, ColorScheme cs) {
    final hasFocus = _searchFocusNode.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4.w,
              height: 16.h,
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              'ImHere 사용자 검색',
              style: TextStyle(
                fontFamily: 'GmarketSans',
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52.h,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: hasFocus ? cs.primary : cs.onSurface.withValues(alpha: 0.1),
              width: hasFocus ? 1.8 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: hasFocus
                    ? cs.primary.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: hasFocus ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(width: 10.w),
              Container(
                width: 34.r,
                height: 34.r,
                decoration: BoxDecoration(
                  color: hasFocus
                      ? cs.primary.withValues(alpha: 0.12)
                      : cs.onSurface.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_rounded,
                  size: 20.r,
                  color: hasFocus ? cs.primary : cs.onSurface.withValues(alpha: 0.45),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  textInputAction: TextInputAction.search,
                  style: TextStyle(
                    fontFamily: 'BMHANNAAir',
                    fontSize: 16.sp,
                    color: cs.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: '닉네임 또는 이메일 검색',
                    hintStyle: TextStyle(
                      fontFamily: 'BMHANNAAir',
                      fontSize: 15.sp,
                      color: cs.onSurface.withValues(alpha: 0.35),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (val) {
                    setState(() {
                      if (val.isEmpty) {
                        _searchResults = null;
                        _errorMessage = null;
                      }
                    });
                  },
                  onSubmitted: (_) => _onSearch(),
                ),
              ),
              if (_isSearching)
                Padding(
                  padding: EdgeInsets.only(right: 14.w),
                  child: const ImHereLoadingIndicator(height: 16),
                )
              else if (_searchController.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() {
                      _searchResults = null;
                      _errorMessage = null;
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.only(right: 14.w),
                    child: Icon(
                      Icons.cancel,
                      size: 20.r,
                      color: cs.onSurface.withValues(alpha: 0.35),
                    ),
                  ),
                )
              else
                SizedBox(width: 14.w),
            ],
          ),
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
    final isSent = _sentUserIds.contains(user.userId);

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
            child: isSent
                ? OutlinedButton.icon(
                    onPressed: null,
                    icon: Icon(Icons.check, size: 14.r, color: cs.primary),
                    label: Text(
                      '요청됨',
                      style: TextStyle(
                        fontFamily: 'BMHANNAAir',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                      side: BorderSide(color: cs.primary.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  )
                : ElevatedButton(
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

  // ── 연락처 추가하기 섹션 카드 ───────────────────────────────────────────────
  Widget _buildContactImportSection(BuildContext context, ColorScheme cs) {
    final vmInterface = ref.read(contactViewModelInterfaceProvider);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: cs.onSurface.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.contacts_rounded,
              size: 24.r,
              color: cs.primary,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '연락처 추가하기',
                  style: TextStyle(
                    fontFamily: 'GmarketSans',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  '전화번호만으로도 친구에게 연락을 보낼 수 있어요',
                  style: TextStyle(
                    fontFamily: 'BMHANNAAir',
                    fontSize: 12.sp,
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          ElevatedButton(
            onPressed: () async {
              try {
                final result = await vmInterface.selectContact();
                if (!context.mounted) return;
                if (result != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${result.name}님이 친구로 추가되었습니다!'),
                      behavior: SnackBarBehavior.floating,
                      margin: EdgeInsets.all(16.w),
                    ),
                  );
                  context.pop();
                } else {
                  final contactVm = ref.read(contactViewModelProvider.notifier);
                  final errorMessage = contactVm.lastError ?? '연락처 선택에 실패했습니다';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorMessage),
                      behavior: SnackBarBehavior.floating,
                      margin: EdgeInsets.all(16.w),
                    ),
                  );
                }
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('오류: $e'),
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.all(16.w),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: Text(
              '가져오기',
              style: TextStyle(
                fontFamily: 'BMHANNAAir',
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
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
    final messageController = TextEditingController();
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isSending = false;
        int currentLength = 0;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isValid = currentLength >= 10;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              title: Text(
                '${user.userNickname}님에게 친구 요청',
                style: TextStyle(
                  fontFamily: 'GmarketSans',
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: messageController,
                    enabled: !isSending,
                    maxLength: 255,
                    maxLines: 3,
                    onChanged: (text) {
                      setDialogState(() {
                        currentLength = text.trim().length;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: '메시지를 입력하세요 (최소 10자 이상)',
                      hintStyle: TextStyle(
                        fontFamily: 'BMHANNAAir',
                        fontSize: 13.sp,
                        color: cs.onSurface.withValues(alpha: 0.4),
                      ),
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      contentPadding: EdgeInsets.all(12.w),
                    ),
                    style: TextStyle(fontFamily: 'BMHANNAAir', fontSize: 14.sp),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isValid ? '✓ 전송 가능한 상태입니다' : '최소 10자 이상 작성해주세요',
                        style: TextStyle(
                          fontFamily: 'BMHANNAAir',
                          fontSize: 12.sp,
                          color: isValid
                              ? Colors.green
                              : (currentLength > 0
                                  ? cs.error
                                  : cs.onSurface.withValues(alpha: 0.5)),
                        ),
                      ),
                      Text(
                        '$currentLength / 255자',
                        style: TextStyle(
                          fontFamily: 'BMHANNAAir',
                          fontSize: 12.sp,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSending ? null : () => Navigator.pop(dialogContext),
                  child: Text(
                    '취소',
                    style: TextStyle(
                      fontFamily: 'BMHANNAAir',
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: (!isValid || isSending)
                      ? null
                      : () async {
                          final message = messageController.text.trim();
                          setDialogState(() {
                            isSending = true;
                          });
                          final success = await _sendFriendRequest(
                            context,
                            user,
                            message,
                          );
                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext);
                          if (success) {
                            setState(() {
                              _sentUserIds.add(user.userId);
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: isSending
                      ? const ImHereLoadingIndicator(height: 14)
                      : Text(
                          '보내기',
                          style: TextStyle(
                            fontFamily: 'BMHANNAAir',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      messageController.dispose();
    });
  }

  Future<bool> _sendFriendRequest(
    BuildContext context,
    UserSearchResponseDto user,
    String message,
  ) async {
    final vm = ref.read(friendRequestViewModelProvider.notifier);
    final success = await vm.sendRequest(
      receiverId: user.userId,
      receiverEmail: user.userEmail,
      message: message,
    );
    if (!context.mounted) return success;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '${user.userNickname}님에게 친구 요청을 보냈습니다'
              : '친구 요청 전송에 실패했습니다',
        ),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16.w),
      ),
    );
    return success;
  }
}
