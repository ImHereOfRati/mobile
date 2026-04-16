import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/core/router/app_routes.dart';
import 'package:iamhere/feature/friend/view_model/contact.dart';
import 'package:iamhere/feature/friend/view_model/contact_view_model.dart';

import 'component/contact_tile.dart';

class ContactView extends ConsumerStatefulWidget {
  const ContactView({super.key});

  @override
  ConsumerState<ContactView> createState() => _ContactViewState();
}

class _ContactViewState extends ConsumerState<ContactView> {
  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(contactViewModelProvider);
    final vm = ref.read(contactViewModelProvider.notifier);
    final contacts = contactsAsync.value ?? [];

    return contactsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Text(
          '친구 목록 로드 실패',
          style: TextStyle(
            fontFamily: 'BMHANNAAir',
            fontSize: 15.sp,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      data: (_) => _buildBody(context, vm, contacts),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ContactViewModel vm,
    List<Contact> contacts,
  ) {
    final cs = Theme.of(context).colorScheme;
    final grouped = _groupByConsonant(contacts);
    final consonants = grouped.keys.toList()..sort();

    return CustomScrollView(
      slivers: [
        // 팁 카드
        SliverToBoxAdapter(child: _buildTipCard(context)),

        // 내 친구 헤더
        SliverToBoxAdapter(child: _buildFriendHeader(context, contacts.length)),

        // 받은 친구 요청
        SliverToBoxAdapter(child: _buildFriendRequestRow(context)),

        // 새로운 친구 추가하기
        SliverToBoxAdapter(child: _buildAddFriendButton(context)),

        if (contacts.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Text(
                '등록된 친구가 없습니다.\n위 버튼을 눌러 친구를 추가하세요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'BMHANNAAir',
                  fontSize: 15.sp,
                  color: cs.onSurface.withValues(alpha: 0.45),
                  height: 1.5,
                ),
              ),
            ),
          )
        else ...[
          // 초성별 그룹 리스트
          for (final consonant in consonants) ...[
            SliverToBoxAdapter(
              child: _buildConsonantHeader(context, consonant),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final contact = grouped[consonant]![index];
                return Column(
                  children: [
                    ContactTile(
                      key: ValueKey(contact.number),
                      contactName: contact.name,
                      phoneNumber: contact.number,
                      status: '내 기기',
                      onDelete: () => _confirmDelete(
                        context,
                        vm,
                        contact.id!,
                        contact.name,
                      ),
                    ),
                    Divider(
                      height: 0.5,
                      thickness: 0.5,
                      color: cs.onSurface.withValues(alpha: 0.1),
                      indent: 20.w,
                      endIndent: 20.w,
                    ),
                  ],
                );
              }, childCount: grouped[consonant]!.length),
            ),
          ],

          // 차단/거절한 친구 보기
          SliverToBoxAdapter(child: _buildBlockedFriendsButton(context)),
        ],

        SliverToBoxAdapter(child: SizedBox(height: 32.h)),
      ],
    );
  }

  // ── 팁 카드 ─────────────────────────────────────────────────────────
  Widget _buildTipCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFFFE082), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('💡', style: TextStyle(fontSize: 18.sp)),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '알아두면 좋아요!',
                  style: TextStyle(
                    fontFamily: 'BMHANNAAir',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFE65100),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '친구가 앱을 삭제하면 위치 알람 전송이 실패할 수 있어요',
                  style: TextStyle(
                    fontFamily: 'BMHANNAAir',
                    fontSize: 13.sp,
                    color: cs.onSurface.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 내 친구 헤더 ─────────────────────────────────────────────────────
  Widget _buildFriendHeader(BuildContext context, int count) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '내 친구',
            style: TextStyle(
              fontFamily: 'GmarketSans',
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '메시지 보는 알람을 받을 수 있는 친구들을 관리하세요',
            style: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 13.sp,
              color: cs.onSurface.withValues(alpha: 0.55),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '$count명 등록됨',
            style: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: cs.primary,
            ),
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  // ── 받은 친구 요청 ───────────────────────────────────────────────────
  Widget _buildFriendRequestRow(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => AppRoutes.goToFriendRequests(context),
      behavior: HitTestBehavior.opaque,
      child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
      child: Row(
        children: [
          Text(
            '받은 친구 요청',
            style: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              '0건',
              style: TextStyle(
                fontFamily: 'BMHANNAAir',
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: cs.onPrimary,
              ),
            ),
          ),
          const Spacer(),
          Icon(Icons.play_arrow_rounded, size: 20.r, color: cs.primary),
        ],
      ),
    ),
    );
  }

  // ── 새로운 친구 추가하기 ──────────────────────────────────────────────
  Widget _buildAddFriendButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
      child: SizedBox(
        width: double.infinity,
        height: 52.h,
        child: ElevatedButton(
          onPressed: () => AppRoutes.goToContactAdd(context),
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          child: Text(
            '새로운 친구 추가하기',
            style: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }

  // ── 초성 섹션 헤더 ───────────────────────────────────────────────────
  Widget _buildConsonantHeader(BuildContext context, String consonant) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            consonant,
            style: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withValues(alpha: 0.45),
            ),
          ),
          SizedBox(height: 6.h),
          Divider(
            height: 0.5,
            thickness: 0.5,
            color: cs.onSurface.withValues(alpha: 0.12),
          ),
        ],
      ),
    );
  }

  // ── 차단/거절한 친구 보기 ─────────────────────────────────────────────
  Widget _buildBlockedFriendsButton(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Center(
        child: GestureDetector(
          onTap: () => AppRoutes.goToFriendRestrictions(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.shield_outlined,
                size: 16.r,
                color: cs.onSurface.withValues(alpha: 0.38),
              ),
              SizedBox(width: 6.w),
              Text(
                '차단/거절한 친구 보기',
                style: TextStyle(
                  fontFamily: 'BMHANNAAir',
                  fontSize: 13.sp,
                  color: cs.onSurface.withValues(alpha: 0.38),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 삭제 확인 다이얼로그 ─────────────────────────────────────────────
  void _confirmDelete(
    BuildContext context,
    ContactViewModel vm,
    int id,
    String name,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          '친구 삭제',
          style: TextStyle(fontFamily: 'GmarketSans', fontSize: 17.sp),
        ),
        content: Text(
          '$name님을 친구 목록에서 삭제할까요?',
          style: TextStyle(fontFamily: 'BMHANNAAir', fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              vm
                  .deleteContact(id)
                  .then((_) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('$name님이 삭제되었습니다.')));
                  })
                  .catchError((e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('삭제 실패: ${e.toString()}')),
                    );
                  });
            },
            child: Text(
              '삭제',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  // ── 초성 그룹핑 유틸 ─────────────────────────────────────────────────
  static const _consonants = [
    'ㄱ',
    'ㄲ',
    'ㄴ',
    'ㄷ',
    'ㄸ',
    'ㄹ',
    'ㅁ',
    'ㅂ',
    'ㅃ',
    'ㅅ',
    'ㅆ',
    'ㅇ',
    'ㅈ',
    'ㅉ',
    'ㅊ',
    'ㅋ',
    'ㅌ',
    'ㅍ',
    'ㅎ',
  ];

  String _getConsonant(String name) {
    if (name.isEmpty) return '#';
    final code = name.codeUnitAt(0);
    if (code >= 0xAC00 && code <= 0xD7A3) {
      return _consonants[(code - 0xAC00) ~/ 588];
    }
    return name[0].toUpperCase();
  }

  Map<String, List<Contact>> _groupByConsonant(List<Contact> contacts) {
    final sorted = [...contacts]..sort((a, b) => a.name.compareTo(b.name));
    final Map<String, List<Contact>> grouped = {};
    for (final c in sorted) {
      final key = _getConsonant(c.name);
      grouped.putIfAbsent(key, () => []).add(c);
    }
    return grouped;
  }
}
