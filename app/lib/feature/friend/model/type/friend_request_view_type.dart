/// 서버 FriendRequestViewType. 받은 요청과 보낸 요청은 같은 목록 API를 공유한다.
enum FriendRequestViewType {
  received('RECEIVED', '받은 요청', '받은 요청이 없어요.'),
  sent('SENT', '보낸 요청', '보낸 요청이 없어요.');

  final String apiValue;
  final String label;
  final String emptyText;

  const FriendRequestViewType(this.apiValue, this.label, this.emptyText);
}
