/// 검색 결과 한 사람과 나의 관계. 서버는 상대 기준 참·거짓만 알려 준다.
enum FriendRelation {
  none(''),
  friend('이미 친구'),
  restricted('차단·거절함');

  final String label;

  const FriendRelation(this.label);

  bool get canRequest => this == FriendRelation.none;
}
