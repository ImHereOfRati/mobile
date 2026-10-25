/// 한글을 음절 단위가 아니라 단어 단위로 줄바꿈하게 만든다.
///
/// Flutter의 줄바꿈은 한글 음절 사이에서도 끊을 수 있어, 단어 중간에서 줄이
/// 바뀌곤 한다. 같은 단어 안의 글자 사이에 폭이 없는 ZWJ(U+200D)를 넣어 단어가
/// 한 덩어리로 다뤄지게 하고, 줄은 공백에서만 바뀌게 한다.
abstract final class KoreanText {
  static const _joiner = '‍';

  static String keepWords(String text) {
    if (text.length < 2) return text;
    return text
        .split(RegExp(r'(?<=\s)|(?=\s)'))
        .map((token) => token.trim().isEmpty ? token : _join(token))
        .join();
  }

  static String _join(String word) =>
      word.runes.map(String.fromCharCode).join(_joiner);

  /// 화면 글자에서 줄바꿈용 문자를 걷어 낸다. 테스트와 접근성 문구에 쓴다.
  static String plain(String text) => text.replaceAll(_joiner, '');
}
