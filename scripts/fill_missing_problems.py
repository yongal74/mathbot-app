# -*- coding: utf-8 -*-
"""
연습문제 완성: 2개씩 생성 + Sonnet 검증
- 6문제 → 12문제 (하×2 + 중×2 + 상×2 추가, 각 2개씩 3번 호출)
- 10문제 → 12문제 (상×2 추가)
"""
import sys, io, json, os, re
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed
import threading

if hasattr(sys.stdout, 'buffer'):
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', line_buffering=True)

import anthropic

def load_api_key():
    env_file = Path('C:/Users/장우경/.gemini/antigravity/automation-n8n/.env')
    for line in env_file.read_text(encoding='utf-8').splitlines():
        if line.startswith("ANTHROPIC_API_KEY="):
            return line.split("=", 1)[1].strip()
    return os.environ.get("ANTHROPIC_API_KEY", "")

API_KEY = load_api_key()
client = anthropic.Anthropic(api_key=API_KEY)
DATA_FILE = Path('C:/Users/장우경/.gemini/antigravity/mathbot-app/assets/data/practice_problems.json')
LOCK = threading.Lock()

DIFF_NODES = {
    '하': [{"type":"given","items":["조건","구하는것"]},{"type":"answer","items":["정답"]}],
    '중': [{"type":"given","items":["조건"]},{"type":"formula","items":["공식"]},{"type":"calculate","items":["계산"]},{"type":"answer","items":["정답"]}],
    '상': [{"type":"given","items":["조건1","조건2"]},{"type":"formula","items":["공식"]},{"type":"derive","items":["유도"]},{"type":"calculate","items":["계산"]},{"type":"answer","items":["정답"]}],
}

def clean_math(text: str) -> str:
    if not isinstance(text, str): return text
    text = re.sub(r'\\frac\{([^}]+)\}\{([^}]+)\}', r'\1/\2', text)
    text = re.sub(r'\\sqrt\{([^}]+)\}', r'√(\1)', text)
    sup_map = {'0':'⁰','1':'¹','2':'²','3':'³','4':'⁴','5':'⁵','6':'⁶','7':'⁷','8':'⁸','9':'⁹','n':'ⁿ'}
    text = re.sub(r'\^\{([^}]+)\}', lambda m: ''.join(sup_map.get(c,c) for c in m.group(1)), text)
    text = re.sub(r'\^(\d)', lambda m: sup_map.get(m.group(1), m.group(1)), text)
    for pat, rep in [(r'\\leq','≤'),(r'\\geq','≥'),(r'\\neq','≠'),(r'\\times','×'),(r'\\div','÷'),(r'\\pm','±'),(r'\\infty','∞')]:
        text = re.sub(pat, rep, text)
    text = re.sub(r'\$\$([^$]*)\$\$', r'\1', text)
    text = re.sub(r'\$([^$\n]{0,100})\$', r'\1', text)
    text = text.replace('$','').replace('{','').replace('}','')
    return text.strip()


def _safe_json_parse(text: str) -> dict:
    """JSON 파싱 전 문제 문자 정리 후 파싱"""
    # 백슬래시 제거, 따옴표 내부 이중따옴표를 단따옴표로
    text = re.sub(r'\\(?!["\\/bfnrt])', '', text)
    # 문자열 값 안의 이중따옴표를 단따옴표로 안전하게 교체
    def fix_quotes(m):
        inner = m.group(1).replace('"', "'")
        return f'"{inner}"'
    text = re.sub(r'"([^"]*)"', fix_quotes, text)
    return json.loads(text)


def gen_1_problem(concept: str, subject: str, difficulty: str) -> dict | None:
    """1문제 생성 (JSON 파싱 실패율 최소화)"""
    diff_kor = {'하':'기초(쉬운 계산)', '중':'응용(공식 적용)', '상':'심화(수능형 복합)'}
    prompt = f"""{subject} '{concept}' {diff_kor[difficulty]} 문제 1개.
수식은 숫자와 한글만 사용. 특수기호(따옴표 쉼표 괄호) 최소화.
JSON만 출력:
{{"q":"문제내용","a":"정답","h":"힌트"}}"""
    for _ in range(3):
        try:
            resp = client.messages.create(
                model="claude-haiku-4-5-20251001",
                max_tokens=300,
                messages=[{"role": "user", "content": prompt}],
            )
            text = resp.content[0].text.strip()
            s, e = text.find("{"), text.rfind("}") + 1
            if s < 0 or e <= s: continue
            raw = text[s:e]
            try:
                p = json.loads(raw)
            except Exception:
                p = _safe_json_parse(raw)
            if p.get('q') and p.get('a'):
                return {
                    "difficulty": difficulty,
                    "question": clean_math(p['q']),
                    "answer_value": clean_math(p['a']),
                    "hint": clean_math(p.get('h', '')),
                    "nodes": DIFF_NODES[difficulty],
                    "concept": concept,
                    "subject": subject,
                    "verified": False,
                }
        except Exception:
            pass
    return None


def gen_2_problems(concept: str, subject: str, difficulty: str) -> list:
    """난이도별 2문제 생성 (1개씩 2회 호출)"""
    results = []
    for _ in range(2):
        p = gen_1_problem(concept, subject, difficulty)
        if p:
            results.append(p)
    return results


def verify_and_fix(problem: dict) -> dict:
    """Sonnet으로 정답 검증"""
    try:
        resp = client.messages.create(
            model="claude-sonnet-4-6",
            max_tokens=100,
            messages=[{"role": "user", "content":
                f"수학 문제 정답 검증.\n문제: {problem['question']}\n정답: {problem['answer_value']}\n\nJSON만: {{\"ok\": true/false, \"fix\": \"교정값(틀릴때만)\"}}"}],
        )
        text = resp.content[0].text.strip()
        s, e = text.find("{"), text.rfind("}") + 1
        if s >= 0 and e > s:
            r = json.loads(text[s:e])
            if not r.get('ok') and r.get('fix'):
                problem['answer_value'] = clean_math(r['fix'])
        problem['verified'] = True
    except:
        pass
    return problem


def process_concept(concept: str, subject: str, need_basic: bool) -> list:
    """개념 하나 처리: 생성 + 검증"""
    problems = []
    if need_basic:
        for diff in ['하', '중', '상']:
            probs = gen_2_problems(concept, subject, diff)
            problems.extend(probs)
    else:
        problems = gen_2_problems(concept, subject, '상')

    # Sonnet 검증
    verified = [verify_and_fix(p) for p in problems]
    return verified


def main():
    data = json.loads(DATA_FILE.read_text(encoding='utf-8'))

    need_basic = [(c, v['subject']) for c, v in data.items() if len(v.get('problems',[])) < 10]
    need_hard  = [(c, v['subject']) for c, v in data.items() if 10 <= len(v.get('problems',[])) < 12]

    total = len(need_basic) + len(need_hard)
    print(f"미완성(→12문제): {len(need_basic)}개")
    print(f"심화만 추가(→12문제): {len(need_hard)}개")
    print(f"총 {total}개 처리 시작\n")

    done = 0
    all_tasks = [(c,s,True) for c,s in need_basic] + [(c,s,False) for c,s in need_hard]

    with ThreadPoolExecutor(max_workers=4) as executor:
        futures = {executor.submit(process_concept, c, s, basic): (c, basic)
                   for c, s, basic in all_tasks}
        for fut in as_completed(futures):
            concept, is_basic = futures[fut]
            try:
                new_probs = fut.result()
                if new_probs:
                    with LOCK:
                        data[concept]['problems'].extend(new_probs)
                        done += 1
                        n = len(data[concept]['problems'])
                        tag = f"+{len(new_probs)}" + ("(기초+심화)" if is_basic else "(심화)")
                        print(f"[{done}/{total}] {concept} {tag} → {n}문제 ✓")
                        if done % 5 == 0:
                            DATA_FILE.write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
                            print(f"  → 저장 ({done}/{total})")
                else:
                    print(f"  [{concept}] 실패")
            except Exception as ex:
                print(f"  [{concept}] 오류: {ex}")

    DATA_FILE.write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
    total_probs = sum(len(v.get('problems',[])) for v in data.values())
    full = sum(1 for v in data.values() if len(v.get('problems',[])) >= 12)
    print(f"\n완료! 12문제 이상: {full}/292, 총 {total_probs}문제")

if __name__ == "__main__":
    main()
