import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iamhere/components/components.dart';
import 'package:iamhere/feature/setting/model/user_me_response_dto.dart';

class SettingAccountRow extends StatelessWidget {
  final AsyncValue<UserMeResponseDto> account;
  final ValueChanged<String> onEditNickname;
  final VoidCallback onRetry;

  const SettingAccountRow({
    super.key,
    required this.account,
    required this.onEditNickname,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = ImHereColors.of(context);
    return account.when(
      loading: () =>
          const ImHereListRow(title: '내 정보', description: '계정 정보를 확인하는 중'),
      error: (_, __) => ImHereListRow(
        title: '내 정보',
        description: '계정 정보를 불러오지 못했어요. 눌러서 다시 시도해 주세요.',
        onTap: onRetry,
      ),
      data: (me) => ImHereListRow(
        title: me.nickname,
        description: me.email,
        trailing: Text(
          '닉네임 수정',
          style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
        ),
        onTap: () => onEditNickname(me.nickname),
      ),
    );
  }
}
