import 'package:flutter/material.dart';
import 'package:iamhere/components/components.dart';
import 'package:iamhere/feature/friend/model/dto/friendship_dto.dart';
import 'package:iamhere/feature/friend/model/repository/contact_entity.dart';

enum FriendAction { notifyArrival, rename, delete, block }

enum ContactAction { rename, delete }

/// ImHere 친구 한 명에 대한 동작 시트. 고른 동작을 돌려주고, 실행은 호출한 쪽이 한다.
Future<FriendAction?> showFriendActionsSheet(
  BuildContext context, {
  required FriendshipDto friendship,
  required Future<FriendshipDto> fresh,
}) {
  return showImHereSheet<FriendAction>(
    context,
    title: friendship.displayName,
    builder: (_) => _FriendActions(friendship: friendship, fresh: fresh),
  );
}

/// 기기 연락처 한 건에 대한 동작 시트.
Future<ContactAction?> showContactActionsSheet(
  BuildContext context, {
  required ContactEntity contact,
}) {
  return showImHereSheet<ContactAction>(
    context,
    title: contact.name,
    builder: (sheetContext) {
      final metrics = ImHereMetrics.of(sheetContext);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ImHereButton(
            label: '닉네임 수정',
            tone: ImHereButtonTone.weak,
            expand: true,
            onPressed: () =>
                Navigator.of(sheetContext).pop(ContactAction.rename),
          ),
          SizedBox(height: metrics.resolve(ImHereSpace.xs)),
          ImHereButton(
            label: '삭제',
            tone: ImHereButtonTone.danger,
            expand: true,
            onPressed: () =>
                Navigator.of(sheetContext).pop(ContactAction.delete),
          ),
        ],
      );
    },
  );
}

class _FriendActions extends StatelessWidget {
  final FriendshipDto friendship;
  final Future<FriendshipDto> fresh;

  const _FriendActions({required this.friendship, required this.fresh});

  @override
  Widget build(BuildContext context) {
    final metrics = ImHereMetrics.of(context);
    final gap = SizedBox(height: metrics.resolve(ImHereSpace.xs));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FutureBuilder<FriendshipDto>(
          future: fresh,
          initialData: friendship,
          builder: (context, snapshot) {
            final detail = snapshot.data ?? friendship;
            final alias = detail.friendAlias.trim();
            return Padding(
              padding: EdgeInsets.only(bottom: metrics.resolve(ImHereSpace.md)),
              child: ImHereCallout(
                text: [
                  '${detail.friend.nickname} · ${detail.friend.email}',
                  '${detail.createdDay}부터 친구${alias.isEmpty ? '' : ' · 별명 $alias'}',
                ].join('\n'),
              ),
            );
          },
        ),
        ImHereButton(
          label: '도착 알림 보내기',
          expand: true,
          onPressed: () =>
              Navigator.of(context).pop(FriendAction.notifyArrival),
        ),
        gap,
        ImHereButton(
          label: '별명 수정',
          tone: ImHereButtonTone.weak,
          expand: true,
          onPressed: () => Navigator.of(context).pop(FriendAction.rename),
        ),
        gap,
        ImHereButton(
          label: '삭제',
          tone: ImHereButtonTone.danger,
          expand: true,
          onPressed: () => Navigator.of(context).pop(FriendAction.delete),
        ),
        gap,
        ImHereButton(
          label: '차단',
          tone: ImHereButtonTone.danger,
          expand: true,
          onPressed: () => Navigator.of(context).pop(FriendAction.block),
        ),
      ],
    );
  }
}
