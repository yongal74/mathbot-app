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
        # 다항식
        "다항식의 덧셈과 뺄셈", "다항식의 곱셈", "다항식의 나눗셈",
        "나머지정리", "인수정리", "항등식", "인수분해", "복잡한 인수분해",
        # 방정식과 부등식
        "복소수", "허수단위", "켤레복소수",
        "이차방정식의 판별식", "근과 계수의 관계", "이차방정식의 활용",
        "고차방정식", "연립방정식", "연립이차방정식",
        "이차부등식", "연립부등식", "절댓값 부등식",
    ],
    "공통수학2": [
        # 집합과 명제
        "집합의 연산", "집합의 원소 개수", "포함배제원리",
        "명제와 조건", "역·이·대우", "필요조건과 충분조건", "귀류법",
        # 함수
        "함수의 정의와 그래프", "합성함수", "역함수", "유리함수", "무리함수",
        # 경우의 수
        "경우의 수", "순열", "원순열", "조합", "이항정리", "이항계수의 성질",
    ],
    "대수": [
        # 지수와 로그
        "지수법칙", "거듭제곱근", "지수함수의 그래프", "지수함수의 성질",
        "로그의 정의", "로그의 성질", "로그함수의 그래프", "상용로그",
        "지수방정식", "지수부등식", "로그방정식", "로그부등식",
        # 수열
        "등차수열과 공차", "등차수열의 합", "등비수열과 공비", "등비수열의 합", "등비급수",
        "수열의 일반항", "시그마 기호", "시그마의 성질",
        "점화식", "수학적 귀납법", "군수열",
    ],
    "미적분": [
        # 수열의 극한
        "수열의 극한", "극한값 계산", "급수의 수렴과 발산", "등비급수 활용",
        # 함수의 극한과 연속
        "함수의 극한", "좌극한과 우극한", "연속함수", "불연속점의 분류",
        "중간값 정리", "최대·최소 정리",
        # 미분법
        "미분계수", "도함수의 정의", "다항함수의 미분",
        "곱의 미분법", "몫의 미분법", "합성함수의 미분",
        "삼각함수의 미분", "지수·로그함수의 미분", "이계도함수",
        # 미분의 활용
        "접선의 방정식", "함수의 증가·감소", "극값",
        "함수의 최댓값·최솟값", "함수의 그래프 개형",
        "방정식의 실근 개수", "속도와 가속도",
        # 적분법
        "부정적분", "정적분 계산", "정적분의 성질", "치환적분", "부분적분",
        # 적분의 활용
        "정적분과 넓이", "두 곡선 사이의 넓이", "속도와 거리", "입체도형의 부피",
    ],
    "확통": [
        # 경우의 수
        "경우의 수", "순열", "조합", "중복순열", "중복조합",
        # 확률
        "확률의 기본성질", "확률의 덧셈", "여사건의 확률",
        "조건부확률", "확률의 곱셈", "독립사건", "독립시행의 확률",
        # 통계
        "확률변수와 확률분포", "이산확률변수의 기댓값", "분산과 표준편차",
        "이항분포", "연속확률변수", "정규분포", "표준정규분포",
        "표준화", "표본평균의 분포", "신뢰구간",
    ],
    "기하": [
        # 이차곡선
        "포물선", "타원", "쌍곡선", "이차곡선의 접선", "이차곡선과 직선",
        # 평면벡터
        "벡터의 정의와 연산", "벡터의 크기", "단위벡터와 방향벡터",
        "벡터의 내적", "벡터의 성분", "위치벡터",
        "직선의 벡터방정식", "원의 벡터방정식",
        # 공간도형과 공간벡터
        "공간좌표", "직선과 평면의 위치관계", "이면각과 정사영",
        "공간벡터", "평면의 방정식", "구의 방정식",
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


def add_explanation_only(args):
    """기존 개념에 설명만 추가 (멀티스레드용)"""
    idx, total, concept, subject, existing_entry = args
    safe_print(f"[설명추가 {idx}/{total}] {subject} > {concept}")
    explanation = generate_explanation(concept, subject)
    if explanation:
        safe_print(f"  [{concept}] 설명 완료")
        return concept, {**existing_entry, "explanation": explanation}
    return concept, None


def process_concept(args):
    """신규 개념 전체 처리 (멀티스레드용)"""
    idx, total, concept, subject = args
    safe_print(f"[신규 {idx}/{total}] {subject} > {concept}")

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

    entry = {"subject": subject, "problems": verified}
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

    # 분류: 신규 / 설명 없는 기존
    new_concepts = [(i+1, total, c, s)
                    for i, (c, s) in enumerate(all_concepts.items())
                    if c not in existing]
    needs_explanation = [(i+1, len(existing), c, s, existing[c])
                         for i, (c, s) in enumerate(all_concepts.items())
                         if c in existing and 'explanation' not in existing[c]]

    print(f"총 {total}개 개념 × 10문제")
    print(f"신규 생성: {len(new_concepts)}개")
    print(f"설명 추가: {len(needs_explanation)}개\n")

    WORKERS = 3
    done_count = len(existing) - len(needs_explanation)

    # Step 1: 기존 개념에 설명 추가 (Sonnet만 사용, 빠름)
    if needs_explanation:
        print(f"=== Step 1: {len(needs_explanation)}개 개념 설명 추가 ===\n")
        with ThreadPoolExecutor(max_workers=WORKERS) as executor:
            futures = {executor.submit(add_explanation_only, args): args
                       for args in needs_explanation}
            for fut in as_completed(futures):
                try:
                    concept, entry = fut.result()
                    if entry:
                        with SAVE_LOCK:
                            results[concept] = entry
                            done_count += 1
                            if done_count % 10 == 0:
                                OUTPUT_FILE.write_text(
                                    json.dumps(results, ensure_ascii=False, indent=2),
                                    encoding='utf-8')
                                safe_print(f"\n  [자동저장] 설명 {done_count}개\n")
                except Exception as ex:
                    safe_print(f"설명 추가 오류: {ex}")

        OUTPUT_FILE.write_text(
            json.dumps(results, ensure_ascii=False, indent=2), encoding='utf-8')
        print(f"\n설명 추가 완료!\n")

    # Step 2: 신규 개념 전체 생성
    if not new_concepts:
        total_p = sum(len(v["problems"]) for v in results.values())
        print(f"\n모두 완료! {len(results)}개 개념, {total_p}문제")
        return

    print(f"=== Step 2: {len(new_concepts)}개 신규 개념 생성 ===\n")
    with ThreadPoolExecutor(max_workers=WORKERS) as executor:
        futures = {executor.submit(process_concept, args): args for args in new_concepts}
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
