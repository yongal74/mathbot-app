# -*- coding: utf-8 -*-
"""
practice_problems.json의 LaTeX 수식 → 일반 텍스트 변환
"""
import json, re, io, sys
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

SUP_MAP = {'0':'⁰','1':'¹','2':'²','3':'³','4':'⁴','5':'⁵',
           '6':'⁶','7':'⁷','8':'⁸','9':'⁹','+':'⁺','-':'⁻','n':'ⁿ','m':'ᵐ'}

def to_sup(s):
    return ''.join(SUP_MAP.get(c, c) for c in s)

def clean_math(text):
    if not isinstance(text, str):
        return text

    # \frac{a}{b} → a/b
    text = re.sub(r'\\frac\{([^}]+)\}\{([^}]+)\}', r'\1/\2', text)

    # \sqrt{a} → √(a)
    text = re.sub(r'\\sqrt\{([^}]+)\}', r'√(\1)', text)
    text = re.sub(r'\\sqrt', '√', text)

    # \left( \right) 등 제거
    text = re.sub(r'\\left\s*[\(\[\{]', '(', text)
    text = re.sub(r'\\right\s*[\)\]\}]', ')', text)
    text = re.sub(r'\\left\.', '', text)
    text = re.sub(r'\\right\.', '', text)

    # 연산자
    replacements = [
        (r'\\cdot', '·'),
        (r'\\times', '×'),
        (r'\\div', '÷'),
        (r'\\pm', '±'),
        (r'\\mp', '∓'),
        (r'\\leq', '≤'),
        (r'\\geq', '≥'),
        (r'\\le\b', '≤'),
        (r'\\ge\b', '≥'),
        (r'\\neq', '≠'),
        (r'\\infty', '∞'),
        (r'\\ldots', '...'),
        (r'\\cdots', '...'),
        (r'\\because', '∵'),
        (r'\\therefore', '∴'),
        (r'\\in\b', '∈'),
        (r'\\notin', '∉'),
        (r'\\subset', '⊂'),
        (r'\\cup', '∪'),
        (r'\\cap', '∩'),
        (r'\\emptyset', '∅'),
        (r'\\forall', '∀'),
        (r'\\exists', '∃'),
        (r'\\log', 'log'),
        (r'\\ln', 'ln'),
        (r'\\sin', 'sin'),
        (r'\\cos', 'cos'),
        (r'\\tan', 'tan'),
        (r'\\lim', 'lim'),
        (r'\\sum', 'Σ'),
        (r'\\prod', 'Π'),
        (r'\\int', '∫'),
        (r'\\to\b', '→'),
        (r'\\rightarrow', '→'),
        (r'\\leftarrow', '←'),
        (r'\\Rightarrow', '⇒'),
        (r'\\Leftrightarrow', '⟺'),
        (r'\\quad', ' '),
        (r'\\qquad', '  '),
        (r'\\,', ''),
        (r'\\;', ' '),
        (r'\\!', ''),
        (r'\\text\{([^}]+)\}', r'\1'),
        (r'\\mathrm\{([^}]+)\}', r'\1'),
        (r'\\mathbf\{([^}]+)\}', r'\1'),
        (r'\\overline\{([^}]+)\}', r'\1̄'),
        (r'\\vec\{([^}]+)\}', r'\1→'),
        (r'\\hat\{([^}]+)\}', r'\1'),
        (r'\\tilde\{([^}]+)\}', r'\1'),
    ]
    for pat, repl in replacements:
        text = re.sub(pat, repl, text)

    # 그리스 문자
    greek = {
        'alpha':'α', 'beta':'β', 'gamma':'γ', 'delta':'δ', 'epsilon':'ε',
        'zeta':'ζ', 'eta':'η', 'theta':'θ', 'iota':'ι', 'kappa':'κ',
        'lambda':'λ', 'mu':'μ', 'nu':'ν', 'xi':'ξ', 'pi':'π',
        'rho':'ρ', 'sigma':'σ', 'tau':'τ', 'upsilon':'υ', 'phi':'φ',
        'chi':'χ', 'psi':'ψ', 'omega':'ω',
        'Alpha':'Α', 'Beta':'Β', 'Gamma':'Γ', 'Delta':'Δ', 'Theta':'Θ',
        'Lambda':'Λ', 'Pi':'Π', 'Sigma':'Σ', 'Omega':'Ω',
    }
    for name, sym in greek.items():
        text = re.sub(r'\\' + name + r'\b', sym, text)

    # 위첨자: x^{n+1} → xⁿ⁺¹, x^2 → x²
    text = re.sub(r'\^\{([^}]+)\}', lambda m: to_sup(m.group(1)), text)
    text = re.sub(r'\^(\d)', lambda m: to_sup(m.group(1)), text)

    # 아래첨자: x_{n} → x_n (그대로 유지, 읽기 쉬움)
    text = re.sub(r'_\{([^}]+)\}', r'_\1', text)

    # 남은 {} 제거
    text = text.replace('{', '').replace('}', '')

    # $$ ... $$ → 내용만
    text = re.sub(r'\$\$([^$]*)\$\$', r'\1', text)
    # $ ... $ → 내용만
    text = re.sub(r'\$([^$\n]{0,100})\$', r'\1', text)
    # 남은 $ 제거
    text = text.replace('$', '')

    # 연속 공백 정리
    text = re.sub(r'  +', ' ', text)
    return text.strip()


def clean_value(v):
    if isinstance(v, str):
        return clean_math(v)
    elif isinstance(v, list):
        return [clean_value(i) for i in v]
    elif isinstance(v, dict):
        return {k: clean_value(val) for k, val in v.items()}
    return v


def main():
    path = 'assets/data/practice_problems.json'
    data = json.load(open(path, encoding='utf-8'))
    print(f'변환 전 달러사인: {json.dumps(data, ensure_ascii=False).count("$")}개')

    cleaned = clean_value(data)

    after = json.dumps(cleaned, ensure_ascii=False)
    print(f'변환 후 달러사인: {after.count("$")}개')

    # 샘플 출력
    for concept, entry in list(cleaned.items())[:3]:
        probs = entry.get('problems', [])
        if probs:
            print(f'\n[{concept}] {probs[0].get("question","")[:80]}')

    json.dump(cleaned, open(path, 'w', encoding='utf-8'), ensure_ascii=False, indent=2)
    print('\n저장 완료!')


if __name__ == '__main__':
    main()
