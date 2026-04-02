/// 수학 표기를 Unicode 위/아래첨자로 변환

const _supDigits = {
  '0': '⁰', '1': '¹', '2': '²', '3': '³', '4': '⁴',
  '5': '⁵', '6': '⁶', '7': '⁷', '8': '⁸', '9': '⁹',
  // 소문자 변수
  'a': 'ᵃ', 'b': 'ᵇ', 'c': 'ᶜ', 'd': 'ᵈ', 'e': 'ᵉ',
  'f': 'ᶠ', 'g': 'ᵍ', 'h': 'ʰ', 'i': 'ⁱ', 'j': 'ʲ',
  'k': 'ᵏ', 'l': 'ˡ', 'm': 'ᵐ', 'n': 'ⁿ', 'o': 'ᵒ',
  'p': 'ᵖ', 'r': 'ʳ', 's': 'ˢ', 't': 'ᵗ', 'u': 'ᵘ',
  'v': 'ᵛ', 'w': 'ʷ', 'x': 'ˣ', 'y': 'ʸ', 'z': 'ᶻ',
  // 대문자 (여사건 A^C 등)
  'A': 'ᴬ', 'B': 'ᴮ', 'C': 'ᶜ', 'D': 'ᴰ', 'E': 'ᴱ',
  'G': 'ᴳ', 'H': 'ᴴ', 'I': 'ᴵ', 'J': 'ᴶ', 'K': 'ᴷ',
  'L': 'ᴸ', 'M': 'ᴹ', 'N': 'ᴺ', 'O': 'ᴼ', 'P': 'ᴾ',
  'R': 'ᴿ', 'T': 'ᵀ', 'U': 'ᵁ', 'V': 'ⱽ', 'W': 'ᵂ',
  '+': '⁺', '-': '⁻',
};

const _subDigits = {
  '0': '₀', '1': '₁', '2': '₂', '3': '₃', '4': '₄',
  '5': '₅', '6': '₆', '7': '₇', '8': '₈', '9': '₉',
  'n': 'ₙ', 'm': 'ₘ', 'k': 'ₖ', 'i': 'ᵢ',
  'a': 'ₐ', 'e': 'ₑ', 'r': 'ᵣ',
};

// 교과서 표준 표기: nCr, nPr, nHr 변환
// C(n,r) → ₙCᵣ, P(n,r) → ₙPᵣ, H(n,r) → ₙHᵣ
String _subChar(String c) => _subDigits[c] ?? c;

String _convertComboNotation(String s) {
  // C(n,r) 또는 C(10,3) 등 → ₙCᵣ 형태
  s = s.replaceAllMapped(
    RegExp(r'\bC\((\d+|[a-z]),\s*(\d+|[a-z])\)'),
    (m) {
      final sub1 = m[1]!.split('').map(_subChar).join();
      final sub2 = m[2]!.split('').map(_subChar).join();
      return '${sub1}C$sub2';
    },
  );
  // P(n,r) → ₙPᵣ (확률 P(A) 와 구분: 숫자 or 단일 변수)
  s = s.replaceAllMapped(
    RegExp(r'\bP\((\d+|[a-z]),\s*(\d+|[a-z])\)'),
    (m) {
      final sub1 = m[1]!.split('').map(_subChar).join();
      final sub2 = m[2]!.split('').map(_subChar).join();
      return '${sub1}P$sub2';
    },
  );
  // H(n,r) → ₙHᵣ (중복조합)
  s = s.replaceAllMapped(
    RegExp(r'\bH\((\d+|[a-z]),\s*(\d+|[a-z])\)'),
    (m) {
      final sub1 = m[1]!.split('').map(_subChar).join();
      final sub2 = m[2]!.split('').map(_subChar).join();
      return '${sub1}H$sub2';
    },
  );
  // nCr 이미 표준 형태 (숫자+C+숫자) → 아래첨자 변환
  s = s.replaceAllMapped(
    RegExp(r'\b(\d+)C(\d+)\b'),
    (m) {
      final sub1 = m[1]!.split('').map(_subChar).join();
      final sub2 = m[2]!.split('').map(_subChar).join();
      return '${sub1}C$sub2';
    },
  );
  s = s.replaceAllMapped(
    RegExp(r'\b(\d+)P(\d+)\b'),
    (m) {
      final sub1 = m[1]!.split('').map(_subChar).join();
      final sub2 = m[2]!.split('').map(_subChar).join();
      return '${sub1}P$sub2';
    },
  );
  return s;
}

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
  // 복잡한 지수식 (subscript, 슬래시 포함) → 그대로 괄호로 표기
  if (expr.contains('_') || expr.contains('/') || expr.contains('(')) {
    return '^($expr)';
  }
  return _toSup(expr);
}

/// 지수를 위첨자로 변환할 수 없는 문자가 포함됐는지 확인
bool _canFullySup(String expr) {
  return expr.split('').every((c) => _supDigits.containsKey(c));
}

String mathToKorean(String text) {
  String s = text;

  // ⓪ 조합·순열·중복조합 표기 먼저 변환 (C(n,r), P(n,r), H(n,r), nCr, nPr)
  s = _convertComboNotation(s);

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
