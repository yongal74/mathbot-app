/// 수학 표기를 위첨자(Unicode superscript)로 변환
/// x^3 → x³,  3^(2/3) → 3^(²/₃),  √24 → √24

const _supDigits = {
  '0': '⁰', '1': '¹', '2': '²', '3': '³', '4': '⁴',
  '5': '⁵', '6': '⁶', '7': '⁷', '8': '⁸', '9': '⁹',
  'n': 'ⁿ', 'm': 'ᵐ', 'k': 'ᵏ', 'i': 'ⁱ', 'a': 'ᵃ',
  '+': '⁺', '-': '⁻', '(': '⁽', ')': '⁾',
};

const _subDigits = {
  '0': '₀', '1': '₁', '2': '₂', '3': '₃', '4': '₄',
  '5': '₅', '6': '⁶', '7': '₇', '8': '₈', '9': '₉',
};

String _toSup(String s) =>
    s.split('').map((c) => _supDigits[c] ?? c).join();

String _toFrac(String expr) {
  // 분수 형태 2/3 → ²⁄₃
  final fracMatch = RegExp(r'^(\d+)/(\d+)$').firstMatch(expr);
  if (fracMatch != null) {
    final num = fracMatch[1]!.split('').map((c) => _supDigits[c] ?? c).join();
    final den = fracMatch[2]!.split('').map((c) => _subDigits[c] ?? c).join();
    return '$num⁄$den';
  }
  return _toSup(expr);
}

String mathToKorean(String text) {
  String s = text;

  // 1단계: word^(분수)  e.g. 3^(2/3) → 3^(²⁄₃)
  s = s.replaceAllMapped(
    RegExp(r'([A-Za-z0-9]+)\^\(([^)]+)\)'),
    (m) => '${m[1]}^(${_toFrac(m[2]!)})',
  );

  // 2단계: word^숫자/변수  e.g. x^3 → x³, a^n → aⁿ
  s = s.replaceAllMapped(
    RegExp(r'([A-Za-z0-9]+)\^([0-9A-Za-z]+)'),
    (m) => '${m[1]}${_toSup(m[2]!)}',
  );

  // 3단계: )^(분수)  e.g. (f(x))^(2/3) → (f(x))^(²⁄₃)
  s = s.replaceAllMapped(
    RegExp(r'\)\^\(([^)]+)\)'),
    (m) => ')^(${_toFrac(m[1]!)})',
  );

  // 4단계: )^n  e.g. (x³+3)^5 → (x³+3)⁵
  s = s.replaceAllMapped(
    RegExp(r'\)\^([0-9A-Za-z]+)'),
    (m) => ')${_toSup(m[1]!)}',
  );

  return s;
}
