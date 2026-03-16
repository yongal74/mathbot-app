/// 수학 표기를 일반인이 읽기 쉬운 한국어로 변환
String mathToKorean(String text) {
  String s = text;

  // a^(expr)승 — 괄호 있는 지수 먼저 처리 (e.g. 3^(2/3) → 3의 (2/3)승)
  s = s.replaceAllMapped(
    RegExp(r'([A-Za-z0-9]+)\^\(([^)]+)\)'),
    (m) => '${m[1]}의 (${m[2]})승',
  );

  // a^n — 단순 정수 지수 (e.g. x^3 → x의 3승)
  s = s.replaceAllMapped(
    RegExp(r'([A-Za-z0-9]+)\^([0-9]+)'),
    (m) => '${m[1]}의 ${m[2]}승',
  );

  // a^b — 변수 지수 (e.g. a^n → a의 n승)
  s = s.replaceAllMapped(
    RegExp(r'([A-Za-z0-9]+)\^([A-Za-z]+)'),
    (m) => '${m[1]}의 ${m[2]}승',
  );

  // √숫자 → 루트(숫자)
  s = s.replaceAllMapped(
    RegExp(r'√([0-9]+)'),
    (m) => '루트 ${m[1]}',
  );

  // ⁿ√ — n제곱근 기호
  s = s.replaceAllMapped(
    RegExp(r'(\d)√'),
    (m) => '${m[1]}제곱근',
  );

  return s;
}
