# -*- coding: utf-8 -*-
"""
2000~2004년 수능 수학 조건분해트리 생성
- 실제 수능 문제 기반으로 Claude가 재현 (나형/가형 → 수학I/II 체계)
- 연도별 30문제, 조건분해트리 포함
"""
import sys, io, json, os, time
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed
import threading

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
import anthropic

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
PRINT_LOCK = threading.Lock()

def safe_print(msg):
    with PRINT_LOCK:
        print(msg)

# 연도별 출제 단원 구성 (2000~2004 수능 나형 기준 - 문과/이과 공통)
YEAR_UNITS = {
    2000: [
        ("지수와 로그", "대수", "하"), ("지수와 로그", "대수", "중"), ("지수함수의 그래프", "대수", "하"),
        ("로그의 성질", "대수", "중"), ("상용로그", "대수", "하"), ("등차수열", "대수", "중"),
        ("등비수열", "대수", "중"), ("수열의 합", "대수", "상"), ("수학적 귀납법", "대수", "상"),
        ("극한값 계산", "미적분", "중"), ("함수의 극한", "미적분", "중"), ("연속함수", "미적분", "중"),
        ("다항함수의 미분", "미적분", "하"), ("도함수의 정의", "미적분", "중"),
        ("접선의 방정식", "미적분", "중"), ("함수의 증가·감소", "미적분", "중"),
        ("극값", "미적분", "상"), ("정적분 계산", "미적분", "중"), ("정적분과 넓이", "미적분", "상"),
        ("집합의 연산", "공통수학2", "하"), ("명제와 조건", "공통수학2", "하"),
        ("역·이·대우", "공통수학2", "중"), ("함수의 정의와 그래프", "공통수학2", "중"),
        ("합성함수", "공통수학2", "중"), ("역함수", "공통수학2", "중"),
        ("경우의 수", "공통수학2", "하"), ("순열", "공통수학2", "중"),
        ("조합", "공통수학2", "중"), ("확률의 덧셈", "확통", "중"), ("조건부확률", "확통", "상"),
    ],
    2001: [
        ("지수법칙", "대수", "하"), ("로그의 정의", "대수", "하"), ("로그의 성질", "대수", "중"),
        ("지수방정식", "대수", "중"), ("상용로그", "대수", "중"), ("등차수열과 공차", "대수", "하"),
        ("등비수열과 공비", "대수", "중"), ("시그마 기호", "대수", "중"),
        ("점화식", "대수", "상"), ("수학적 귀납법", "대수", "상"),
        ("수열의 극한", "미적분", "중"), ("극한값 계산", "미적분", "중"),
        ("함수의 극한", "미적분", "중"), ("미분계수", "미적분", "중"),
        ("다항함수의 미분", "미적분", "하"), ("곱의 미분법", "미적분", "중"),
        ("함수의 최댓값·최솟값", "미적분", "상"), ("정적분 계산", "미적분", "중"),
        ("두 곡선 사이의 넓이", "미적분", "상"), ("집합의 원소 개수", "공통수학2", "중"),
        ("명제와 조건", "공통수학2", "하"), ("필요조건과 충분조건", "공통수학2", "중"),
        ("합성함수", "공통수학2", "중"), ("역함수", "공통수학2", "중"),
        ("유리함수", "공통수학2", "중"), ("경우의 수", "공통수학2", "하"),
        ("조합", "공통수학2", "중"), ("이항정리", "공통수학2", "중"),
        ("확률의 곱셈", "확통", "중"), ("이항분포", "확통", "상"),
    ],
    2002: [
        ("지수함수의 성질", "대수", "중"), ("로그함수의 그래프", "대수", "중"),
        ("지수부등식", "대수", "중"), ("로그방정식", "대수", "중"),
        ("상용로그", "대수", "하"), ("등차수열의 합", "대수", "중"),
        ("등비수열의 합", "대수", "중"), ("시그마의 성질", "대수", "중"),
        ("점화식", "대수", "상"), ("군수열", "대수", "상"),
        ("급수의 수렴과 발산", "미적분", "중"), ("등비급수 활용", "미적분", "상"),
        ("좌극한과 우극한", "미적분", "중"), ("연속함수", "미적분", "중"),
        ("합성함수의 미분", "미적분", "중"), ("다항함수의 미분", "미적분", "하"),
        ("극값", "미적분", "중"), ("함수의 그래프 개형", "미적분", "상"),
        ("정적분과 넓이", "미적분", "상"), ("속도와 거리", "미적분", "상"),
        ("집합의 연산", "공통수학2", "하"), ("역·이·대우", "공통수학2", "중"),
        ("함수의 정의와 그래프", "공통수학2", "하"), ("무리함수", "공통수학2", "중"),
        ("유리함수", "공통수학2", "중"), ("순열", "공통수학2", "중"),
        ("중복조합", "공통수학2", "중"), ("이항정리", "공통수학2", "중"),
        ("조건부확률", "확통", "상"), ("정규분포", "확통", "상"),
    ],
    2003: [
        ("지수법칙", "대수", "하"), ("지수함수의 그래프", "대수", "중"),
        ("로그의 성질", "대수", "하"), ("상용로그", "대수", "중"),
        ("로그부등식", "대수", "중"), ("등비급수", "대수", "중"),
        ("수열의 일반항", "대수", "중"), ("시그마 기호", "대수", "중"),
        ("수학적 귀납법", "대수", "상"), ("점화식", "대수", "상"),
        ("수열의 극한", "미적분", "중"), ("함수의 극한", "미적분", "중"),
        ("불연속점의 분류", "미적분", "중"), ("중간값 정리", "미적분", "중"),
        ("도함수의 정의", "미적분", "중"), ("몫의 미분법", "미적분", "중"),
        ("접선의 방정식", "미적분", "중"), ("함수의 증가·감소", "미적분", "상"),
        ("정적분 계산", "미적분", "중"), ("두 곡선 사이의 넓이", "미적분", "상"),
        ("집합의 원소 개수", "공통수학2", "중"), ("명제와 조건", "공통수학2", "하"),
        ("합성함수", "공통수학2", "중"), ("역함수", "공통수학2", "중"),
        ("유리함수", "공통수학2", "중"), ("경우의 수", "공통수학2", "하"),
        ("조합", "공통수학2", "중"), ("중복순열", "공통수학2", "중"),
        ("여사건의 확률", "확통", "중"), ("표준화", "확통", "상"),
    ],
    2004: [
        ("거듭제곱근", "대수", "하"), ("지수함수의 성질", "대수", "중"),
        ("로그의 정의", "대수", "하"), ("로그함수의 그래프", "대수", "중"),
        ("지수방정식", "대수", "중"), ("등차수열의 합", "대수", "중"),
        ("등비수열의 합", "대수", "중"), ("시그마의 성질", "대수", "중"),
        ("군수열", "대수", "상"), ("등비급수", "대수", "중"),
        ("극한값 계산", "미적분", "중"), ("좌극한과 우극한", "미적분", "중"),
        ("최대·최소 정리", "미적분", "중"), ("미분계수", "미적분", "중"),
        ("합성함수의 미분", "미적분", "중"), ("곱의 미분법", "미적분", "중"),
        ("극값", "미적분", "중"), ("함수의 최댓값·최솟값", "미적분", "상"),
        ("정적분과 넓이", "미적분", "상"), ("속도와 거리", "미적분", "상"),
        ("집합의 연산", "공통수학2", "하"), ("역·이·대우", "공통수학2", "중"),
        ("필요조건과 충분조건", "공통수학2", "중"), ("무리함수", "공통수학2", "중"),
        ("합성함수", "공통수학2", "중"), ("순열", "공통수학2", "하"),
        ("중복조합", "공통수학2", "중"), ("이항정리", "공통수학2", "중"),
        ("독립사건", "확통", "중"), ("신뢰구간", "확통", "상"),
    ],
}

# 난이도별 트리 단계
DIFFICULTY_NODES = {
    "하": ["given", "calculate", "answer"],
    "중": ["given", "formula", "calculate", "answer"],
    "상": ["given", "formula", "derive", "calculate", "answer"],
}


def generate_problem_tree(year: int, no: int, unit: str, subject: str, difficulty: str) -> dict:
    """Claude로 수능 스타일 문제 + 트리 생성"""
    node_types = DIFFICULTY_NODES[difficulty]
    nodes_example = json.dumps([
        {"type": t, "label": {"given":"주어진 조건","formula":"공식 적용","derive":"식 유도","calculate":"계산","answer":"정답"}[t],
         "detail": f"{t} 단계 설명", "items": [f"{t} 항목1", f"{t} 항목2"]}
        for t in node_types
    ], ensure_ascii=False)

    prompt = f"""{year}학년도 대학수학능력시험 수학 {no}번 문제를 재현해주세요.
단원: {subject} - {unit}
난이도: {difficulty} ({"기초계산" if difficulty=="하" else "응용" if difficulty=="중" else "심화"})

실제 수능 스타일로 자연스러운 한국어 수학 문제를 만들고 조건분해트리를 작성하세요.
노드 타입 순서: {" → ".join(node_types)}

JSON만 응답:
{{
  "problem_text": "문제 본문 (수식 포함, LaTeX 없이 일반 텍스트)",
  "choices": [],
  "answer": "정답값",
  "concepts": ["{unit}"],
  "hints": ["힌트1", "힌트2"],
  "common_mistake": "자주 하는 실수",
  "nodes": {nodes_example}
}}"""

    try:
        resp = client.messages.create(
            model="claude-haiku-4-5-20251001",
            max_tokens=2000,
            messages=[{"role": "user", "content": prompt}],
        )
        text = resp.content[0].text.strip()
        s, e = text.find("{"), text.rfind("}") + 1
        if s >= 0 and e > s:
            data = json.loads(text[s:e])
            return {
                "id": f"{year}_{no}",
                "year": year,
                "no": no,
                "problem_text": data.get("problem_text", ""),
                "problem_type": "단답형" if difficulty == "상" else "객관식",
                "choices": data.get("choices", []),
                "answer": str(data.get("answer", "")),
                "unit_order": no,
                "subject": subject,
                "unit": unit,
                "concepts": data.get("concepts", [unit]),
                "difficulty": difficulty,
                "node_depth": len(node_types),
                "reason": f"{year}학년도 수능 재현",
                "grade": "3",
                "nodes": data.get("nodes", []),
                "optimal_path": node_types,
                "common_mistake": data.get("common_mistake", ""),
                "hints": data.get("hints", []),
                "concept": unit,
                "review_status": "unseen",
            }
    except Exception as ex:
        safe_print(f"  [{year}번{no}] 오류: {ex}")
    return None


def generate_year(year: int) -> list:
    """한 연도 전체 30문제 생성 (병렬)"""
    units = YEAR_UNITS[year]
    results = [None] * len(units)

    with ThreadPoolExecutor(max_workers=5) as ex:
        futures = {ex.submit(generate_problem_tree, year, i+1, u, s, d): i
                   for i, (u, s, d) in enumerate(units)}
        for fut in as_completed(futures):
            i = futures[fut]
            try:
                problem = fut.result()
                if problem:
                    results[i] = problem
                    safe_print(f"  {year}년 {i+1}번 ({units[i][0]}) 완료")
            except Exception as ex:
                safe_print(f"  {year}년 {i+1}번 오류: {ex}")

    return [p for p in results if p is not None]


def main():
    print("2000~2004년 수능 수학 조건분해트리 생성")
    print(f"API 키: {API_KEY[:20]}...\n")

    for year in [2000, 2001, 2002, 2003, 2004]:
        output_file = DATA_DIR / f"{year}_trees.json"
        if output_file.exists():
            data = json.loads(output_file.read_text(encoding='utf-8'))
            print(f"{year}년: 이미 존재 ({len(data)}문제), 스킵")
            continue

        print(f"\n=== {year}학년도 ({len(YEAR_UNITS[year])}문제) ===")
        problems = generate_year(year)
        output_file.write_text(
            json.dumps(problems, ensure_ascii=False, indent=2), encoding='utf-8')
        print(f"{year}년 완료: {len(problems)}문제 저장")
        time.sleep(2)

    print("\n전체 완료!")


if __name__ == "__main__":
    main()
