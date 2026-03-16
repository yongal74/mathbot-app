# -*- coding: utf-8 -*-
"""
개념 설명만 생성 (Haiku 사용 - 저비용)
explanation 없는 개념에 스토리/핵심원리/수능팁 추가
"""
import sys, io, json, os, time
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed
import threading

if hasattr(sys.stdout, 'buffer'):
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', line_buffering=True)
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
DATA_FILE = Path(__file__).parent.parent / "assets" / "data" / "practice_problems.json"
LOCK = threading.Lock()


def generate_explanation(concept: str, subject: str) -> dict:
    prompt = f"""당신은 수학을 재미있게 가르치는 선생님입니다. 한국 고등학교 {subject} 과목 '{concept}' 개념을 설명해주세요.

규칙:
- 수식은 LaTeX($, \\frac 등) 절대 금지. 일반 텍스트로만 (x², √2, a/b, log₂(x))
- 중학생도 이해할 수 있는 쉬운 말로
- 딱딱하지 않게, 생활 속 예시로 자연스럽게

JSON만 응답:
{{
  "analogy": "생활 속 이야기나 상황으로 개념을 자연스럽게 이해시키기. '아, 이래서 이 개념이 필요하구나!' 느낌이 나도록 2-3문장으로. 재미있고 공감 가는 예시.",
  "explain": [
    "개념의 핵심을 한 줄로 (공식·정의 포함, 짧고 명확하게)",
    "왜 이렇게 되는지 — 직관적인 이유 설명",
    "이것만 주의하면 됨 — 가장 흔한 실수 한 가지",
    "이 개념이 나오면 다음에 이게 나온다 — 연결 흐름"
  ],
  "csat_tip": "수능에서 이 개념은 이렇게 나온다. 딱 핵심만 2문장."
}}"""

    try:
        resp = client.messages.create(
            model="claude-haiku-4-5-20251001",
            max_tokens=900,
            messages=[{"role": "user", "content": prompt}],
        )
        text = resp.content[0].text.strip()
        s, e = text.find("{"), text.rfind("}") + 1
        if s >= 0 and e > s:
            return json.loads(text[s:e])
    except Exception as ex:
        print(f"  [{concept}] 오류: {ex}")
    return {}


def main():
    data = json.loads(DATA_FILE.read_text(encoding='utf-8'))
    needs = [(c, v['subject']) for c, v in data.items() if not v.get('explanation')]
    total = len(needs)
    print(f"explanation 없는 개념: {total}개\n")

    if total == 0:
        print("모두 완료됨!")
        return

    done = 0
    save_every = 20

    with ThreadPoolExecutor(max_workers=5) as executor:
        futures = {executor.submit(generate_explanation, c, s): (c, s)
                   for c, s in needs}
        for fut in as_completed(futures):
            concept, subject = futures[fut]
            try:
                result = fut.result()
                if result:
                    with LOCK:
                        data[concept]['explanation'] = result
                        done += 1
                        print(f"[{done}/{total}] {concept} ✓")
                        if done % save_every == 0:
                            DATA_FILE.write_text(
                                json.dumps(data, ensure_ascii=False, indent=2),
                                encoding='utf-8')
                            print(f"  → 자동저장 {done}개")
                else:
                    print(f"  [{concept}] 실패")
            except Exception as ex:
                print(f"  [{concept}] 예외: {ex}")

    DATA_FILE.write_text(
        json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8')
    has_exp = sum(1 for v in data.values() if v.get('explanation'))
    print(f"\n완료! {has_exp}/{len(data)}개 설명 생성됨")


if __name__ == "__main__":
    main()
