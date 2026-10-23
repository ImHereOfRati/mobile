enum ActivityRecordStatus {
  completed('전송 완료'),
  failed('전송 실패'),
  pending('전송 대기');

  final String label;

  const ActivityRecordStatus(this.label);
}
