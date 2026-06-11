import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/friend/service/dto/friend_relationship_response_dto.dart';
import 'package:iamhere/feature/friend/view_model/contact.dart';
import 'package:iamhere/feature/friend/view_model/contact_view_model.dart';
import 'package:iamhere/feature/friend/view_model/friend_list_view_model.dart';

import 'component/contact_tile.dart';
import 'component/friend_request_row.dart';
import 'component/friend_header.dart';
import 'component/friend_empty_state.dart';
import 'component/add_friend_button.dart';
import 'component/consonant_header.dart';
import 'component/blocked_friends_button.dart';
import 'component/friend_list_footer_tip.dart';

class ContactView extends ConsumerStatefulWidget {
  const ContactView({super.key});

  @override
  ConsumerState<ContactView> createState() => _ContactViewState();
}

enum _FriendAction { delete, block }

class _ContactViewState extends ConsumerState<ContactView> {
  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(contactViewModelProvider);
    final serverFriendsAsync = ref.watch(friendListViewModelProvider);
    final vm = ref.read(contactViewModelProvider.notifier);
    final contacts = contactsAsync.value ?? [];
    final serverFriends = serverFriendsAsync.value ?? [];

    final isLoading = contactsAsync.isLoading || serverFriendsAsync.isLoading;
    final hasError = contactsAsync.hasError && serverFriendsAsync.hasError;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (hasError) {
      return Center(
        child: Text(
          '친구 목록 로드 실패',
          style: TextStyle(
            fontFamily: 'BMHANNAAir',
            fontSize: 15.sp,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      );
    }
    return _buildBody(context, vm, contacts, serverFriends);
  }

  Widget _buildBody(
    BuildContext context,
    ContactViewModel vm,
    List<Contact> contacts,
    List<FriendRelationshipResponseDto> serverFriends,
  ) {
    final cs = Theme.of(context).colorScheme;
    final grouped = _groupByConsonant(contacts);
    final consonants = grouped.keys.toList()..sort();
    final totalCount = contacts.length + serverFriends.length;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: FriendHeader(count: totalCount)),
        SliverToBoxAdapter(child: FriendRequestRow()),
        SliverToBoxAdapter(child: AddFriendButton()),
        if (totalCount == 0)
          SliverFillRemaining(child: FriendEmptyState())
        else
          ..._buildContactLists(context, cs, vm, serverFriends, grouped, consonants),
        SliverToBoxAdapter(child: FriendListFooterTip()),
        SliverToBoxAdapter(child: SizedBox(height: 32.h)),
      ],
    );
  }


  List<Widget> _buildContactLists(
    BuildContext context,
    ColorScheme cs,
    ContactViewModel vm,
    List<FriendRelationshipResponseDto> serverFriends,
    Map<String, List<Contact>> grouped,
    List<String> consonants,
  ) {
    return [
      if (serverFriends.isNotEmpty) ...[
        SliverToBoxAdapter(child: ConsonantHeader(consonant: 'imhere')),
        _buildServerFriendList(context, cs, serverFriends),
      ],
      for (final consonant in consonants) ...[
        SliverToBoxAdapter(child: ConsonantHeader(consonant: consonant)),
        _buildLocalContactList(context, cs, vm, grouped[consonant]!),
      ],
      SliverToBoxAdapter(child: BlockedFriendsButton()),
    ];
  }

  Widget _buildServerFriendList(
    BuildContext context,
    ColorScheme cs,
    List<FriendRelationshipResponseDto> serverFriends,
  ) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final friend = serverFriends[index];
          final name = friend.friendAlias.isNotEmpty
              ? friend.friendAlias
              : friend.friendEmail;
          return _buildFriendTile(
            context,
            cs,
            name: name,
            number: friend.friendEmail,
            status: 'Imhere',
            onDelete: () => _deleteServerFriend(context, friend.friendRelationshipId, name),
            onTap: () => _showServerFriendActions(context, friend.friendRelationshipId, name),
          );
        },
        childCount: serverFriends.length,
      ),
    );
  }

  Widget _buildLocalContactList(
    BuildContext context,
    ColorScheme cs,
    ContactViewModel vm,
    List<Contact> contacts,
  ) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final contact = contacts[index];
          return _buildFriendTile(
            context,
            cs,
            name: contact.name,
            number: contact.number,
            status: '내 기기',
            onDelete: () => _deleteLocalContact(context, vm, contact.id!, contact.name),
            onTap: () => _showLocalContactActions(context, vm, contact.id!, contact.name),
          );
        },
        childCount: contacts.length,
      ),
    );
  }

  Widget _buildFriendTile(
    BuildContext context,
    ColorScheme cs, {
    required String name,
    required String number,
    required String status,
    required Future<bool> Function() onDelete,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        ContactTile(
          key: ValueKey(number),
          contactName: name,
          phoneNumber: number,
          status: status,
          onDelete: onDelete,
          onTap: onTap,
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
  }







  // ── 로컬 연락처 삭제 (밀어서 삭제) ───────────────────────────────────
  Future<bool> _deleteLocalContact(
    BuildContext context,
    ContactViewModel vm,
    int id,
    String name,
  ) async {
    try {
      await vm.deleteContact(id);
      if (!context.mounted) return true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name님이 삭제되었습니다.')),
      );
      return true;
    } catch (e) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: ${e.toString()}')),
      );
      return false;
    }
  }

  // ── 서버 친구 삭제 (밀어서 삭제) ─────────────────────────────────────
  Future<bool> _deleteServerFriend(
    BuildContext context,
    String friendRelationshipId,
    String name,
  ) async {
    final vm = ref.read(friendListViewModelProvider.notifier);
    final success = await vm.deleteFriend(friendRelationshipId);
    if (!context.mounted) return success;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? '$name님이 삭제되었습니다.' : '삭제에 실패했습니다.',
        ),
      ),
    );
    return success;
  }

  // ── 서버 친구 액션 시트 (삭제/차단) ─────────────────────────────────
  Future<void> _showServerFriendActions(
    BuildContext context,
    String friendRelationshipId,
    String name,
  ) async {
    final cs = Theme.of(context).colorScheme;
    final action = await showModalBottomSheet<_FriendAction>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
              child: Text(
                name,
                style: TextStyle(
                  fontFamily: 'BMHANNAAir',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.block, color: cs.onSurface),
              title: Text(
                '차단',
                style: TextStyle(
                  fontFamily: 'BMHANNAAir',
                  fontSize: 15.sp,
                ),
              ),
              onTap: () => Navigator.pop(ctx, _FriendAction.block),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: cs.error),
              title: Text(
                '삭제',
                style: TextStyle(
                  fontFamily: 'BMHANNAAir',
                  fontSize: 15.sp,
                  color: cs.error,
                ),
              ),
              onTap: () => Navigator.pop(ctx, _FriendAction.delete),
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );

    if (!context.mounted || action == null) return;
    if (action == _FriendAction.delete) {
      final ok = await _confirm(context, '$name님을 삭제하시겠어요?');
      if (ok && context.mounted) {
        await _deleteServerFriend(context, friendRelationshipId, name);
      }
    } else {
      final ok = await _confirm(
        context,
        '$name님을 차단하시겠어요?\n차단된 친구는 알림을 받을 수 없습니다.',
      );
      if (ok && context.mounted) {
        final vm = ref.read(friendListViewModelProvider.notifier);
        final success = await vm.blockFriend(friendRelationshipId);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? '$name님을 차단했습니다.' : '차단에 실패했습니다.',
            ),
          ),
        );
      }
    }
  }

  // ── 로컬 연락처 액션 시트 (삭제) ──────────────────────────────────────
  Future<void> _showLocalContactActions(
    BuildContext context,
    ContactViewModel vm,
    int id,
    String name,
  ) async {
    final cs = Theme.of(context).colorScheme;
    final action = await showModalBottomSheet<_FriendAction>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
              child: Text(
                name,
                style: TextStyle(
                  fontFamily: 'BMHANNAAir',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: cs.error),
              title: Text(
                '삭제',
                style: TextStyle(
                  fontFamily: 'BMHANNAAir',
                  fontSize: 15.sp,
                  color: cs.error,
                ),
              ),
              onTap: () => Navigator.pop(ctx, _FriendAction.delete),
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );

    if (!context.mounted || action != _FriendAction.delete) return;
    final ok = await _confirm(context, '$name님을 삭제하시겠어요?');
    if (ok && context.mounted) {
      await _deleteLocalContact(context, vm, id, name);
    }
  }

  Future<bool> _confirm(BuildContext context, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(
          message,
          style: TextStyle(fontFamily: 'BMHANNAAir', fontSize: 15.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    return result ?? false;
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
