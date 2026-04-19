import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/friend/view_model/contact_view_model.dart';
import 'package:iamhere/feature/friend/view_model/contact_view_model_interface.dart';
import 'package:iamhere/feature/friend/view_model/contact_view_model_provider.dart';
import 'package:iamhere/feature/friend/view_model/friend_list_view_model.dart';
import 'package:iamhere/feature/geofence/model/recipient.dart';
import 'package:iamhere/feature/geofence/view_model/recipient_select_view_model.dart';

import 'recipient_tile.dart';

class RecipientSelectView extends ConsumerStatefulWidget {
  final List<String>? initialSelectedKeys;

  const RecipientSelectView({super.key, this.initialSelectedKeys});

  @override
  ConsumerState<RecipientSelectView> createState() =>
      _RecipientSelectViewState();
}

class _RecipientSelectViewState extends ConsumerState<RecipientSelectView> {
  void _confirmSelection(List<Recipient> allRecipients) {
    final viewModel = ref.read(
      recipientSelectViewModelProvider(widget.initialSelectedKeys).notifier,
    );
    final selected = viewModel.confirmSelection(allRecipients);

    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최소 1명 이상 선택해주세요')),
      );
      return;
    }

    debugPrint('선택된 수신자: ${selected.map((r) => r.displayName).join(", ")}');
    Navigator.of(context).pop(selected);
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(contactViewModelProvider);
    final serverFriendsAsync = ref.watch(friendListViewModelProvider);
    final vmInterface = ref.read(contactViewModelInterfaceProvider);
    final recipientState = ref.watch(
      recipientSelectViewModelProvider(widget.initialSelectedKeys),
    );

    final isLoading =
        contactsAsync.isLoading || serverFriendsAsync.isLoading;
    final hasError = contactsAsync.hasError && serverFriendsAsync.hasError;

    return Scaffold(
      body: _buildContent(
        context,
        isLoading: isLoading,
        hasError: hasError,
        contactsError: contactsAsync.error,
        serverError: serverFriendsAsync.error,
        localRecipients: (contactsAsync.value ?? [])
            .map((c) => LocalRecipient(c))
            .toList(),
        serverRecipients: (serverFriendsAsync.value ?? [])
            .map(ServerRecipient.fromDto)
            .toList(),
        recipientState: recipientState,
        vmInterface: vmInterface,
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required bool isLoading,
    required bool hasError,
    required Object? contactsError,
    required Object? serverError,
    required List<LocalRecipient> localRecipients,
    required List<ServerRecipient> serverRecipients,
    required RecipientSelectState recipientState,
    required ContactViewModelInterface vmInterface,
  }) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (hasError) {
      return _buildErrorPage(context, contactsError ?? serverError);
    }

    final allRecipients = <Recipient>[...serverRecipients, ...localRecipients];

    if (allRecipients.isEmpty) {
      return _buildEmptyPage(context, vmInterface);
    }

    return Column(
      children: [
        _buildHeader(context, recipientState, allRecipients),
        _buildSelectAllRow(context, recipientState, allRecipients),
        Expanded(
          child: CustomScrollView(
            slivers: [
              if (serverRecipients.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _sectionHeader(context, 'ImHere 친구'),
                ),
                _buildRecipientSliver(serverRecipients, recipientState),
              ],
              if (localRecipients.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _sectionHeader(context, '내 기기 연락처'),
                ),
                _buildRecipientSliver(localRecipients, recipientState),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    RecipientSelectState recipientState,
    List<Recipient> allRecipients,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color:
                Theme.of(context).dividerTheme.color ??
                Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '수신자 선택 (${recipientState.selectedCount}명)',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: Icon(Icons.check, size: 28.sp),
            onPressed: () => _confirmSelection(allRecipients),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectAllRow(
    BuildContext context,
    RecipientSelectState recipientState,
    List<Recipient> allRecipients,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color:
                Theme.of(context).dividerTheme.color ??
                Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value:
                allRecipients.isNotEmpty &&
                recipientState.selectedCount == allRecipients.length,
            tristate: true,
            onChanged: (_) {
              ref
                  .read(
                    recipientSelectViewModelProvider(
                      widget.initialSelectedKeys,
                    ).notifier,
                  )
                  .selectAll(allRecipients);
            },
          ),
          Text(
            '전체 선택',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Text(
            '${recipientState.selectedCount} / ${allRecipients.length}',
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      color: cs.onSurface.withValues(alpha: 0.04),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w700,
          color: cs.onSurface.withValues(alpha: 0.6),
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  SliverList _buildRecipientSliver(
    List<Recipient> recipients,
    RecipientSelectState recipientState,
  ) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final recipient = recipients[index];
        final isSelected = recipientState.selectedKeys.contains(
          recipient.selectionKey,
        );
        return RecipientTile(
          key: ValueKey(recipient.selectionKey),
          recipient: recipient,
          isSelected: isSelected,
          onTap: () {
            ref
                .read(
                  recipientSelectViewModelProvider(
                    widget.initialSelectedKeys,
                  ).notifier,
                )
                .toggleSelection(recipient.selectionKey);
          },
        );
      }, childCount: recipients.length),
    );
  }

  Widget _buildErrorPage(BuildContext context, Object? err) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
            SizedBox(height: 16.h),
            Text(
              '연락처 로드 실패',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.h),
            Text(
              err?.toString() ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.55),
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPage(
    BuildContext context,
    ContactViewModelInterface vmInterface,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.contacts_outlined, size: 64.sp, color: Colors.grey),
          SizedBox(height: 16.h),
          Text(
            '등록된 친구가 없습니다',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '먼저 연락처 탭에서\n친구를 추가해주세요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await vmInterface.selectContact();
              if (result != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${result.name}님이 추가되었습니다')),
                );
              }
            },
            icon: const Icon(Icons.person_add),
            label: const Text('연락처 추가하기'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: 24.w,
                vertical: 12.h,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
