/// 수학 표기를 Unicode 위/아래첨자로 변환

const _supDigits = {
  '0': '⁰', '1': '¹', '2': '²', '3': '³', '4': '⁴',
  '5': '⁵', '6': '⁶', '7': '⁷', '8': '⁸', '9': '⁹',
  'n': 'ⁿ', 'm': 'ᵐ', 'k': 'ᵏ', 'i': 'ⁱ', 'a': 'ᵃ',
  '+': '⁺', '-': '⁻',
};

const _subDigits = {
  '0': '₀', '1': '₁', '2': '₂', '3': '₃', '4': '₄',
  '5': '₅', '6': '₆', '7': '₇', '8': '₈', '9': '₉',
  'n': 'ₙ', 'm': 'ₘ', 'k': 'ₖ', 'i': 'ᵢ',
  'a': 'ₐ', 'e': 'ₑ', 'r': 'ᵣ',
};

String _toSup(String s) =>
    s.split('').map((c) => _supDigits[c] ?? c).join();

String _toSub(String s) =>
    s.split('').map((c) => _subDigits[c] ?? c).join();

String _toFrac(String expr) {
  // 2/3 → ²⁄₃
  final m = RegExp(r'^(\d+)/(\d+)$').firstMatch(expr);
  if (m != null) {
    final n = m[1]!.split('').map((c) => _supDigits[c] ?? c).join();
    final d = m[2]!.split('').map((c) => _subDigits[c] ?? c).join();
    return '$n⁄$d';
  }
  return _toSup(expr);
}

String mathToKorean(String text) {
  String s = text;

  // ① LaTeX 중괄호 위첨자: a^{expr} → aᵉˣᵖʳ
  s = s.replaceAllMapped(
    RegExp(r'([A-Za-z0-9)\]]+)\^\{([^}]+)\}'),
    (m) => '${m[1]}^(${m[2]})',  // 괄호로 정규화 후 아래서 재처리
  );

  // ② LaTeX 중괄호 아래첨자: a_{expr} → aₑₓₚᵣ
  s = s.replaceAllMapped(
    RegExp(r'([A-Za-z0-9)\]]+)_\{([^}]+)\}'),
    (m) => '${m[1]}_(${m[2]})',  // 괄호로 정규화
  );

  // ③ lim_{...} / lim_{x→a} → lim(x→a)
  s = s.replaceAllMapped(
    RegExp(r'lim_\(([^)]+)\)'),
    (m) => 'lim(${m[1]})',
  );

  // ④ )^(expr): (x+1)^(n+1) → (x+1)ⁿ⁺¹, (2x)^(1/2) → (2x)^½
  s = s.replaceAllMapped(
    RegExp(r'\)\^\(([^)]+)\)'),
    (m) => ')${_toFrac(m[1]!)}',
  );

  // ⑤ )^n: (x³+3)^5 → (x³+3)⁵
  s = s.replaceAllMapped(
    RegExp(r'\)\^([0-9A-Za-z]+)'),
    (m) => ')${_toSup(m[1]!)}',
  );

  // ⑥ word^(분수/식): 3^(2/3) → 3^(²⁄₃)
  s = s.replaceAllMapped(
    RegExp(r'([A-Za-z0-9]+)\^\(([^)]+)\)'),
    (m) => '${m[1]}${_toFrac(m[2]!)}',
  );

  // ⑦ word^숫자/변수: x^3 → x³, a^n → aⁿ
  s = s.replaceAllMapped(
    RegExp(r'([A-Za-z0-9]+)\^([0-9A-Za-z]+)'),
    (m) => '${m[1]}${_toSup(m[2]!)}',
  );

  // ⑧ 아래첨자 단순: S_4→S₄, a_n→aₙ, b_k→bₖ
  s = s.replaceAllMapped(
    RegExp(r'([A-Za-z])_([0-9A-Za-z]+)'),
    (m) => '${m[1]}${_toSub(m[2]!)}',
  );

  // ⑨ 아래첨자 괄호형: a_(n+1) → a(n+1) 그대로 표기
  s = s.replaceAllMapped(
    RegExp(r'([A-Za-z])_\(([^)]+)\)'),
    (m) => '${m[1]}(${m[2]})',
  );

  // ⑩ √숫자 앞에 숫자: 6√24 → ⁶√24 (n제곱근)
  s = s.replaceAllMapped(
    RegExp(r'(?<![A-Za-z0-9⁰-⁹])(\d)√'),
    (m) => '${_toSup(m[1]!)}√',
  );

  // ⑪ π/n 분수: π/2 → π/2 (유지하되 앞뒤 공백 정리)
  // ⑫ ∞ 기호 이미 OK

  return s;
}
