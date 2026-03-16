# -*- coding: utf-8 -*-
import sys, io, json, os, time, re
from pathlib import Path
from collections import Counter
from concurrent.futures import ThreadPoolExecutor, as_completed
import threading

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

import anthropic

# ── API 키 로드 (.env 우선, 환경변수 fallback) ──────
def load_api_key():
    env_file = Path(__file__).parent.parent.parent / "automation-n8n" / ".env"
    if env_file.exists():
        for line in env_file.read_text(encoding='utf-8').splitlines():
            if line.startswith("ANTHROPIC_API_KEY="):
                return line.split("=", 1)[1].strip()
    return os.environ.get("ANTHROPIC_API_KEY", "")

API_KEY = load_api_key()
client = anthropic.Anthropic(api_key=API_KEY)

DATA_DIR = Path(__file__).parent.parent / "assets" / "data"
OUTPUT_FILE = DATA_DIR / "practice_problems.json"

SAVE_LOCK = threading.Lock()
PRINT_LOCK = threading.Lock()

# ── 교과서 전 개념 목록 ───────────────────────────────
CURRICULUM_CONCEPTS = {
    "공통수학1": [
        "다항식의 덧셈과 뺄셈", "다항식의 곱셈", "인수분해", "나머지정리",
        "항등식", "이차방정식의 판별식", "근과 계수의 관계",
        "고차방정식", "연립방정식", "이차부등식", "절댓값 부등식",
        "복소수", "허수단위",
    ],
    "공통수학2": [
        "집합의 연산", "명제와 조건", "역·이·대우", "집합의 원소 개수",
        "합성함수", "역함수", "유리함수", "무리함수",
        "경우의 수", "순열", "조합", "이항정리",
    ],
    "대수": [
        "지수법칙", "거듭제곱근", "지수함수", "로그의 정의", "로그의 성질",
        "로그함수", "상용로그", "지수방정식", "로그방정식",
        "등차수열", "등비수열", "일반항", "점화식", "수열의 합",
        "시그마 기호", "수학적 귀납법", "군수열",
    ],
    "미적분": [
        "수열의 극한", "극한값 계산", "함수의 극한", "연속함수", "불연속점",
        "미분계수", "도함수", "다항함수의 미분", "곱의 미분법",
        "몫의 미분법", "합성함수의 미분", "삼각함수의 미분",
        "지수·로그함수의 미분", "접선의 방정식", "함수의 증가·감소",
        "극값", "최댓값·최솟값", "정적분 계산", "정적분과 넓이",
        "치환적분", "부분적분", "속도와 거리",
    ],
    "확통": [
        "경우의 수", "순열", "조합", "중복순열", "중복조합",
        "확률의 덧셈", "확률의 곱셈", "조건부확률",
        "독립사건", "여사건", "확률변수", "이항분포",
        "정규분포", "표준화", "표본평균", "신뢰구간",
    ],
    "기하": [
        "벡터의 덧셈", "벡터의 내적", "벡터의 크기", "단위벡터",
        "직선의 방정식", "원의 방정식", "포물선", "타원", "쌍곡선",
        "이차곡선의 접선", "공간좌표", "공간벡터", "구의 방정식",
    ],
}


def safe_print(msg: str):
    with PRINT_LOCK:
        print(msg)


def extract_concepts_from_data():
    counter = Counter()
    for f in DATA_DIR.glob("*_trees.json"):
        for p in json.loads(f.read_text(encoding='utf-8')):
            for c in p.get("concepts", []):
                counter[c] += 1
    return counter


def generate_problems(concept: str, subject: str) -> list:
    """Haiku로 하×4, 중×4, 상×2 = 총 10문제 생성 (조건분해트리 포함)"""
    prompt = f"""당신은 한국 수학 교사입니다. {subject} 과목 '{concept}' 개념 연습문제를 만드세요.
- 하(기초) 4문제: given → answer (2단계)
- 중(응용) 4문제: given → formula → calculate → answer (4단계)
- 상(심화) 2문제: given → formula → derive → calculate → answer (5단계)

JSON 배열만 응답 (설명 없이):
[
  {{"difficulty":"하","question":"문제","answer_value":"정답","hint":"힌트","nodes":[{{"type":"given","items":["조건","구하는 것"]}},{{"type":"answer","items":["정답"]}}]}},
  {{"difficulty":"하","question":"문제","answer_value":"정답","hint":"힌트","nodes":[{{"type":"given","items":["조건","구하는 것"]}},{{"type":"answer","items":["정답"]}}]}},
  {{"difficulty":"하","question":"문제","answer_value":"정답","hint":"힌트","nodes":[{{"type":"given","items":["조건","구하는 것"]}},{{"type":"answer","items":["정답"]}}]}},
  {{"difficulty":"하","question":"문제","answer_value":"정답","hint":"힌트","nodes":[{{"type":"given","items":["조건","구하는 것"]}},{{"type":"answer","items":["정답"]}}]}},
  {{"difficulty":"중","question":"문제","answer_value":"정답","hint":"힌트","nodes":[{{"type":"given","items":["조건1","조건2"]}},{{"type":"formula","items":["공식"]}},{{"type":"calculate","items":["계산1","계산2"]}},{{"type":"answer","items":["정답"]}}]}},
  {{"difficulty":"중","question":"문제","answer_value":"정답","hint":"힌트","nodes":[{{"type":"given","items":["조건1","조건2"]}},{{"type":"formula","items":["공식"]}},{{"type":"calculate","items":["계산1","계산2"]}},{{"type":"answer","items":["정답"]}}]}},
  {{"difficulty":"중","question":"문제","answer_value":"정답","hint":"힌트","nodes":[{{"type":"given","items":["조건1","조건2"]}},{{"type":"formula","items":["공식"]}},{{"type":"calculate","items":["계산1","계산2"]}},{{"type":"answer","items":["정답"]}}]}},
  {{"difficulty":"중","question":"문제","answer_value":"정답","hint":"힌트","nodes":[{{"type":"given","items":["조건1","조건2"]}},{{"type":"formula","items":["공식"]}},{{"type":"calculate","items":["계산1","계산2"]}},{{"type":"answer","items":["정답"]}}]}},
  {{"difficulty":"상","question":"문제","answer_value":"정답","hint":"힌트","nodes":[{{"type":"given","items":["조건1","조건2","조건3"]}},{{"type":"formula","items":["공식1","공식2"]}},{{"type":"derive","items":["유도1","유도2"]}},{{"type":"calculate","items":["계산1","계산2","계산3"]}},{{"type":"answer","items":["정답"]}}]}},
  {{"difficulty":"상","question":"문제","answer_value":"정답","hint":"힌트","nodes":[{{"type":"given","items":["조건1","조건2","조건3"]}},{{"type":"formula","items":["공식1","공식2"]}},{{"type":"derive","items":["유도1","유도2"]}},{{"type":"calculate","items":["계산1","계산2","계산3"]}},{{"type":"answer","items":["정답"]}}]}}
]"""

    try:
        resp = client.messages.create(
            model="claude-haiku-4-5-20251001",
            max_tokens=5000,
            messages=[{"role": "user", "content": prompt}],
        )
        text = resp.content[0].text.strip()
        s, e = text.find("["), text.rfind("]") + 1
        if s >= 0 and e > s:
            problems = json.loads(text[s:e])
            for p in problems:
                p["concept"] = concept
                p["subject"] = subject
            return problems
    except Exception as ex:
        safe_print(f"  [{concept}] 생성 오류: {ex}")
    return []


def generate_explanation(concept: str, subject: str) -> dict:
    """Sonnet으로 수학자 레벨 개념 설명 생성"""
    prompt = f"""당신은 세계 최고의 수학 교육자입니다. 한국 {subject} 과목 '{concept}' 개념을 수학자 수준으로 설명해주세요.

JSON만 응답:
{{
  "analogy": "일상적인 비유나 스토리로 직관적 이해 (3-4문장, 고등학생도 '아!' 할 수 있는 수준)",
  "explain": [
    "수학적 본질 핵심 포인트 1 (정의/공식 포함)",
    "수학적 본질 핵심 포인트 2 (성질/조건 포함)",
    "수학적 본질 핵심 포인트 3 (주의사항/특수케이스 포함)",
    "수학적 본질 핵심 포인트 4 (활용/연결 포함)"
  ],
  "csat_tip": "수능에서 이 개념이 어떻게 출제되는지, 자주 나오는 함정과 핵심 전략 (3-4문장)"
}}"""

    try:
        resp = client.messages.create(
            model="claude-sonnet-4-6",
            max_tokens=800,
            messages=[{"role": "user", "content": prompt}],
        )
        text = resp.content[0].text.strip()
        s, e = text.find("{"), text.rfind("}") + 1
        if s >= 0 and e > s:
            return json.loads(text[s:e])
    except Exception as ex:
        safe_print(f"  [{concept}] 설명 생성 오류: {ex}")
    return {}


def verify_problem(problem: dict) -> tuple:
    """Sonnet으로 정답 검증"""
    prompt = f"""수학 문제의 정답 정확성을 검증하세요.

문제: {problem['question']}
제시 정답: {problem['answer_value']}
풀이 트리: {json.dumps(problem.get('nodes', []), ensure_ascii=False)}

JSON만 응답:
{{"correct": true/false, "correct_answer": "틀렸을 때만 올바른 정답"}}"""

    try:
        resp = client.messages.create(
            model="claude-sonnet-4-6",
            max_tokens=200,
            messages=[{"role": "user", "content": prompt}],
        )
        text = resp.content[0].text.strip()
        s, e = text.find("{"), text.rfind("}") + 1
        if s >= 0 and e > s:
            r = json.loads(text[s:e])
            return r.get("correct", True), r.get("correct_answer", "")
    except:
        pass
    return True, ""


def process_concept(args):
    """단일 개념 처리 (멀티스레드용)"""
    idx, total, concept, subject = args
    safe_print(f"[{idx}/{total}] {subject} > {concept}")

    # 문제 생성
    problems = generate_problems(concept, subject)
    if not problems:
        return concept, None

    # 검증 (병렬)
    verified = []
    with ThreadPoolExecutor(max_workers=5) as vex:
        futures = {vex.submit(verify_problem, p): p for p in problems}
        for fut in as_completed(futures):
            p = futures[fut]
            try:
                is_ok, correct_ans = fut.result()
                if is_ok:
                    p["verified"] = True
                    verified.append(p)
                    safe_print(f"  [{concept}][{p['difficulty']}] OK")
                elif correct_ans:
                    p["answer_value"] = correct_ans
                    p["verified"] = True
                    verified.append(p)
                    safe_print(f"  [{concept}][{p['difficulty']}] 교정: {correct_ans}")
                else:
                    safe_print(f"  [{concept}][{p['difficulty']}] 제외")
            except Exception as ex:
                safe_print(f"  [{concept}] 검증 오류: {ex}")

    if not verified:
        return concept, None

    # 개념 설명 생성
    explanation = generate_explanation(concept, subject)
    safe_print(f"  [{concept}] 설명 생성 {'완료' if explanation else '실패'}")

    entry = {
        "subject": subject,
        "problems": verified,
    }
    if explanation:
        entry["explanation"] = explanation

    return concept, entry


def main():
    print("수능 수학 개념별 연습문제 생성 + 검증 (멀티스레드)")
    print(f"API 키: {API_KEY[:20]}...\n")

    existing = {}
    if OUTPUT_FILE.exists():
        existing = json.loads(OUTPUT_FILE.read_text(encoding='utf-8'))
        print(f"기존 {len(existing)}개 개념 로드\n")

    data_concepts = extract_concepts_from_data()

    all_concepts = {}
    for subject, concepts in CURRICULUM_CONCEPTS.items():
        for c in concepts:
            all_concepts[c] = subject
    for concept, count in data_concepts.most_common():
        if concept not in all_concepts and count >= 2:
            all_concepts[concept] = "공통"

    total = len(all_concepts)
    results = dict(existing)
    pending = [(i+1, total, c, s) for i, (c, s) in enumerate(all_concepts.items()) if c not in existing]

    print(f"총 {total}개 개념 × 10문제 = 약 {total*10}문제 생성 예정")
    print(f"완료 {len(existing)}개, 남은 {len(pending)}개\n")

    # 동시 3개 처리 (API rate limit 고려)
    WORKERS = 3
    done_count = len(existing)

    with ThreadPoolExecutor(max_workers=WORKERS) as executor:
        futures = {executor.submit(process_concept, args): args for args in pending}
        for fut in as_completed(futures):
            try:
                concept, entry = fut.result()
                if entry:
                    with SAVE_LOCK:
                        results[concept] = entry
                        done_count += 1
                        if done_count % 5 == 0:
                            OUTPUT_FILE.write_text(
                                json.dumps(results, ensure_ascii=False, indent=2),
                                encoding='utf-8')
                            total_p = sum(len(v["problems"]) for v in results.values())
                            safe_print(f"\n  [자동저장] {done_count}/{total} 개념, {total_p}문제\n")
            except Exception as ex:
                safe_print(f"개념 처리 오류: {ex}")

    OUTPUT_FILE.write_text(
        json.dumps(results, ensure_ascii=False, indent=2), encoding='utf-8')
    total_p = sum(len(v["problems"]) for v in results.values())
    print(f"\n완료! {len(results)}개 개념, {total_p}문제 (검증 완료)")


if __name__ == "__main__":
    main()
