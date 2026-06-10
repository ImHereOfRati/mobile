enum EventType {
  arrival('도착'),
  departure('출발'),
  both('도착/출발 모두');

  final String displayName;

  const EventType(this.displayName);

  String get messageTemplate {
    switch (this) {
      case EventType.arrival:
        return '안녕하세요! {location}에 도착했습니다.';
      case EventType.departure:
        return '안녕하세요! {location}에서 출발했습니다.';
      case EventType.both:
        return '안녕하세요! {location}에 도착/출발했습니다.';
    }
  }
}
