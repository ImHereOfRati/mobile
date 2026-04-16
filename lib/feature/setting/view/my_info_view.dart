import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/setting/view_model/my_info_view_model.dart';

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
                _InfoRow(label: '닉네임', value: userInfo.userNickname),
                _InfoRow(label: '이메일', value: userInfo.userEmail),
                _InfoRow(label: '사용자 ID', value: userInfo.userId),
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
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80.w,
                      child: Text(
                        rows[i].label,
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
                        rows[i].value,
                        style: TextStyle(
                          fontFamily: 'BMHANNAAir',
                          fontSize: 16.sp,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
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
}

class _InfoRow {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});
}
