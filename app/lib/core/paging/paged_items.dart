/// 이어서 불러오는 목록의 현재 상태.
class PagedItems<T> {
  final List<T> items;
  final bool hasNext;

  /// 마지막으로 읽은 쪽 번호(0부터).
  final int page;

  /// 다음 쪽을 읽는 중이면 true. 같은 쪽을 두 번 요청하지 않게 막는 데 쓴다.
  final bool loadingMore;

  const PagedItems({
    required this.items,
    required this.hasNext,
    this.page = 0,
    this.loadingMore = false,
  });

  const PagedItems.empty() : this(items: const [], hasNext: false);

  PagedItems<T> copyWith({
    List<T>? items,
    bool? hasNext,
    int? page,
    bool? loadingMore,
  }) {
    return PagedItems<T>(
      items: items ?? this.items,
      hasNext: hasNext ?? this.hasNext,
      page: page ?? this.page,
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }

  /// 다음 쪽을 이어 붙인다.
  PagedItems<T> append(PagedItems<T> next, int nextPage) => PagedItems<T>(
    items: [...items, ...next.items],
    hasNext: next.hasNext,
    page: nextPage,
  );

  PagedItems<T> removeWhere(bool Function(T item) test) =>
      copyWith(items: items.where((item) => !test(item)).toList());

  PagedItems<T> replaceWhere(bool Function(T item) test, T replacement) =>
      copyWith(
        items: [for (final item in items) test(item) ? replacement : item],
      );
}
