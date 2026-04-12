import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/contact/view_model/contact.dart';
import 'package:iamhere/contact/view_model/contact_view_model.dart';
import 'package:iamhere/contact/view_model/contact_view_model_provider.dart';
import 'package:iamhere/geofence/view_model/recipient_select_view_model.dart';

import 'recipient_tile.dart';

class RecipientSelectView extends ConsumerStatefulWidget {
  final List<int>? initialSelectedIds; // 기존 선택된 수신자 ID 목록

  const RecipientSelectView({super.key, this.initialSelectedIds});

  @override
  ConsumerState<RecipientSelectView> createState() =>
      _RecipientSelectViewState();
}

class _RecipientSelectViewState extends ConsumerState<RecipientSelectView> {
  void _confirmSelection(List<Contact> allContacts) {
    final viewModel = ref.read(
      recipientSelectViewModelProvider(widget.initialSelectedIds).notifier,
    );
    final selectedContacts = viewModel.confirmSelection(allContacts);

    if (selectedContacts == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('최소 1명 이상 선택해주세요')));
      return;
    }

    debugPrint('선택된 수신자: ${selectedContacts.map((c) => c.name).join(", ")}');
    Navigator.of(context).pop(selectedContacts);
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsyncValue = ref.watch(contactViewModelProvider);
    final vmInterface = ref.read(contactViewModelInterfaceProvider);
    final recipientState = ref.watch(
      recipientSelectViewModelProvider(widget.initialSelectedIds),
    );

    return Scaffold(
      body: contactsAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
                SizedBox(height: 16.h),
                Text(
                  '연락처 로드 실패',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55), fontSize: 14.sp),
                ),
              ],
            ),
          ),
        ),
        data: (contacts) {
          if (contacts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.contacts_outlined,
                    size: 64.sp,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    '등록된 연락처가 없습니다',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '먼저 연락처 탭에서\n친구를 추가해주세요',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14.sp, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55)),
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
                    icon: Icon(Icons.person_add),
                    label: Text('연락처 추가하기'),
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

          return Column(
            children: [
              // 헤더 (제목 및 확인 버튼)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    bottom: BorderSide(color: Theme.of(context).dividerTheme.color ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2), width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '수신자 선택 (${recipientState.selectedCount}명)',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.check, size: 28.sp),
                      onPressed: () => _confirmSelection(contacts),
                    ),
                  ],
                ),
              ),
              // 전체 선택 버튼
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    bottom: BorderSide(color: Theme.of(context).dividerTheme.color ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value:
                          contacts.isNotEmpty &&
                          recipientState.selectedCount == contacts.length,
                      tristate: true,
                      onChanged: (_) {
                        ref
                            .read(
                              recipientSelectViewModelProvider(
                                widget.initialSelectedIds,
                              ).notifier,
                            )
                            .selectAll(contacts);
                      },
                    ),
                    Text(
                      '전체 선택',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    Text(
                      '${recipientState.selectedCount} / ${contacts.length}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),

              // 연락처 목록
              Expanded(
                child: ListView.builder(
                  itemCount: contacts.length,
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    final isSelected = recipientState.selectedIds.contains(
                      contact.id,
                    );

                    return RecipientTile(
                      contact: contact,
                      isSelected: isSelected,
                      onTap: () {
                        ref
                            .read(
                              recipientSelectViewModelProvider(
                                widget.initialSelectedIds,
                              ).notifier,
                            )
                            .toggleSelection(contact.id);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
