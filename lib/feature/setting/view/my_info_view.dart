import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/setting/view_model/my_info_view_model.dart';
import 'package:iamhere/shared/base/result/app_snack_bar.dart';
import 'package:iamhere/shared/base/result/result_message.dart';

class MyInfoView extends ConsumerWidget {
  const MyInfoView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(myInfoViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '내 정보',
          style: TextStyle(
            fontFamily: 'BMHANNAAir',
            fontSize: 18.sp,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: stateAsync.when(
        data: (userInfo) {
          if (userInfo == null) {
            return Center(
              child: Text(
                '정보를 불러올 수 없습니다.',
                style: TextStyle(
                  fontFamily: 'BMHANNAAir',
                  fontSize: 16.sp,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.55),
                ),
              ),
            );
          }

          return ListView(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            children: [
              _buildInfoCard(context, [
                _InfoRow(
                  label: '닉네임',
                  value: userInfo.userNickname,
                  onEdit: () => _showEditNicknameDialog(
                    context,
                    ref,
                    currentNickname: userInfo.userNickname,
                  ),
                ),
                _InfoRow(label: '이메일', value: userInfo.userEmail),
              ]),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF0071E3)),
        ),
        error: (_, __) => Center(
          child: Text(
            '정보를 불러오는 중 오류가 발생했습니다.',
            style: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 16.sp,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, List<_InfoRow> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: List.generate(rows.length, (i) {
          final row = rows[i];
          return Column(
            children: [
              InkWell(
                onTap: row.onEdit,
                borderRadius: BorderRadius.vertical(
                  top: i == 0 ? Radius.circular(12.r) : Radius.zero,
                  bottom: i == rows.length - 1
                      ? Radius.circular(12.r)
                      : Radius.zero,
                ),
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80.w,
                        child: Text(
                          row.label,
                          style: TextStyle(
                            fontFamily: 'BMHANNAAir',
                            fontSize: 14.sp,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.55),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          row.value,
                          style: TextStyle(
                            fontFamily: 'BMHANNAAir',
                            fontSize: 16.sp,
                            color: Theme.of(context).colorScheme.onSurface,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      if (row.onEdit != null)
                        Icon(
                          Icons.edit_outlined,
                          size: 18.r,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.45),
                        ),
                    ],
                  ),
                ),
              ),
              if (i < rows.length - 1)
                Divider(
                  height: 0.5,
                  thickness: 0.5,
                  indent: 16.w,
                  color: Theme.of(context).dividerTheme.color,
                ),
            ],
          );
        }),
      ),
    );
  }

  Future<void> _showEditNicknameDialog(
    BuildContext context,
    WidgetRef ref, {
    required String currentNickname,
  }) async {
    final controller = TextEditingController(text: currentNickname);
    final cs = Theme.of(context).colorScheme;

    final newNickname = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          '닉네임 변경',
          style: TextStyle(fontFamily: 'GmarketSans', fontSize: 17.sp),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          style: TextStyle(fontFamily: 'BMHANNAAir', fontSize: 15.sp),
          decoration: InputDecoration(
            hintText: '새 닉네임 입력',
            hintStyle: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 14.sp,
              color: cs.onSurface.withValues(alpha: 0.4),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty || text == currentNickname) {
                Navigator.pop(dialogContext);
                return;
              }
              Navigator.pop(dialogContext, text);
            },
            child: const Text('변경'),
          ),
        ],
      ),
    );

    if (newNickname == null || !context.mounted) return;

    final ok = await ref
        .read(myInfoViewModelProvider.notifier)
        .changeNickname(newNickname);

    if (!context.mounted) return;
    if (ok) {
      AppSnackBar.showSuccess(
        context,
        ResultMessage.nicknameChangedSuccess.message,
      );
    } else {
      AppSnackBar.showError(
        context,
        ResultMessage.nicknameChangeFail.message,
      );
    }
  }
}

class _InfoRow {
  final String label;
  final String value;
  final VoidCallback? onEdit;

  const _InfoRow({required this.label, required this.value, this.onEdit});
}
