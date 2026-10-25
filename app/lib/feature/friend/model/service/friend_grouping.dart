import 'package:iamhere/feature/friend/model/dto/friendship_dto.dart';
import 'package:iamhere/feature/friend/model/repository/contact_entity.dart';
import 'package:iamhere/feature/friend/model/type/friend_entry.dart';

abstract final class FriendGrouping {
  static const _initials = [
    'ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', 'ㅅ', //
    'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ',
  ];

  /// 목록을 묶는 머리글자. 한글은 초성, 영문은 대문자, 숫자는 `0-9`, 나머지는 `#`.
  static String nameGroup(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '#';
    final first = trimmed.substring(0, 1);
    final code = first.codeUnitAt(0);
    if (code >= 0xac00 && code <= 0xd7a3) {
      return _initials[(code - 0xac00) ~/ 588];
    }
    if (RegExp(r'[a-zA-Z]').hasMatch(first)) return first.toUpperCase();
    if (RegExp(r'\d').hasMatch(first)) return '0-9';
    return '#';
  }

  /// ImHere 친구와 기기 연락처를 이름순 한 목록으로 합친다.
  static List<FriendEntry> merge(
    List<FriendshipDto> friendships,
    List<ContactEntity> contacts,
  ) {
    final entries = <FriendEntry>[
      for (final item in friendships) ServerFriendEntry(item),
      for (final item in contacts) DeviceFriendEntry(item),
    ];
    entries.sort(
      (left, right) => left.displayName.toLowerCase().compareTo(
        right.displayName.toLowerCase(),
      ),
    );
    return entries;
  }

  /// 정렬된 순서를 유지한 채 머리글자별로 묶는다.
  static Map<String, List<FriendEntry>> group(List<FriendEntry> entries) {
    final groups = <String, List<FriendEntry>>{};
    for (final entry in entries) {
      groups.putIfAbsent(nameGroup(entry.displayName), () => []).add(entry);
    }
    return groups;
  }
}
