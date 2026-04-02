"""
수능 수학 PDF → 문제 이미지 추출 스크립트
- PDFs: C:/Users/장우경/.gemini/antigravity/automation-n8n/mathbot/data/raw/
- Output: assets/images/{year}_p{page}.jpg
- Updates: assets/data/{year}_trees.json (image_url 필드 추가)
"""

import os
import re
import json
import fitz  # pymupdf

PDF_DIR = r'C:\Users\장우경\.gemini\antigravity\automation-n8n\mathbot\data\raw'
APP_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IMG_DIR = os.path.join(APP_DIR, 'assets', 'images')
DATA_DIR = os.path.join(APP_DIR, 'assets', 'data')

DPI = 100
QUALITY = 72  # JPEG quality (lower = smaller file)


def build_prob_page_map(doc: fitz.Document) -> dict[int, int]:
    """PDF 페이지에서 문제 번호 → 페이지 인덱스 매핑 생성"""
    prob_page: dict[int, int] = {}
    for pi in range(len(doc)):
        text = doc[pi].get_text()
        for m in re.finditer(r'(?:^|\n| )([1-9][0-9]?)\. ', text):
            n = int(m.group(1))
            if 1 <= n <= 30 and n not in prob_page:
                prob_page[n] = pi
    return prob_page


def extract_year(pdf_dir: str, year: int, img_dir: str, data_dir: str) -> None:
    pdf_path = os.path.join(pdf_dir, f'{year}_math.pdf')
    if not os.path.exists(pdf_path):
        print(f'  SKIP no PDF: {pdf_path}')
        return

    doc = fitz.open(pdf_path)
    prob_page = build_prob_page_map(doc)

    if not prob_page:
        print(f'  SKIP {year}: no problem numbers found')
        doc.close()
        return

    # 사용된 페이지만 이미지로 추출
    mat = fitz.Matrix(DPI / 72, DPI / 72)
    pages_rendered: set[int] = set()
    for page_idx in set(prob_page.values()):
        img_name = f'{year}_p{page_idx + 1}.jpg'
        img_path = os.path.join(img_dir, img_name)
        if not os.path.exists(img_path):
            page = doc[page_idx]
            pix = page.get_pixmap(matrix=mat)
            pix.save(img_path, jpg_quality=QUALITY)
        pages_rendered.add(page_idx)

    doc.close()

    # JSON 업데이트
    json_path = os.path.join(data_dir, f'{year}_trees.json')
    if not os.path.exists(json_path):
        print(f'  SKIP no JSON: {json_path}')
        return

    with open(json_path, 'r', encoding='utf-8') as f:
        problems = json.load(f)

    updated = 0
    for p in problems:
        no = p.get('no', 0)
        if no in prob_page:
            page_idx = prob_page[no]
            p['image_url'] = f'assets/images/{year}_p{page_idx + 1}.jpg'
            updated += 1

    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(problems, f, ensure_ascii=False, indent=2)

    print(f'  OK {year}: {len(pages_rendered)} pages, {updated} problems mapped')


def main() -> None:
    os.makedirs(IMG_DIR, exist_ok=True)

    years = sorted([
        int(f.split('_')[0])
        for f in os.listdir(PDF_DIR)
        if f.endswith('_math.pdf') and f.split('_')[0].isdigit()
    ])

    print(f'Target years: {years}')
    print(f'Output: {IMG_DIR}')
    print()

    for year in years:
        print(f'Processing {year}...')
        extract_year(PDF_DIR, year, IMG_DIR, DATA_DIR)

    print()
    print('Done!')


if __name__ == '__main__':
    main()
