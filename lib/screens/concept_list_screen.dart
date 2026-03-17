import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../core/curriculum.dart';
import '../services/concept_service.dart';
import 'concept_detail_screen.dart';

// 3단계: 과목 → 단원 → 개념
const Map<String, Map<String, List<String>>> kCurriculumTree = {
  '공통수학1': {
    '다항식': [
      '다항식의 덧셈과 뺄셈', '다항식의 곱셈', '다항식의 나눗셈',
      '나머지정리', '인수정리', '항등식', '인수분해', '복잡한 인수분해',
    ],
    '방정식과 부등식': [
      '복소수', '허수단위', '켤레복소수',
      '이차방정식의 판별식', '근과 계수의 관계', '이차방정식의 활용',
      '고차방정식', '연립방정식', '연립이차방정식',
      '이차부등식', '연립부등식', '절댓값 부등식',
    ],
  },
  '공통수학2': {
    '집합과 명제': [
      '집합의 연산', '집합의 원소 개수', '포함배제원리',
      '명제와 조건', '역·이·대우', '필요조건과 충분조건', '귀류법',
    ],
    '함수': [
      '함수의 정의와 그래프', '합성함수', '역함수', '유리함수', '무리함수',
    ],
    '경우의 수': [
      '경우의 수', '순열', '원순열', '조합', '이항정리', '이항계수의 성질',
    ],
  },
  '대수': {
    '지수와 로그': [
      '지수법칙', '거듭제곱근', '지수함수의 그래프', '지수함수의 성질',
      '로그의 정의', '로그의 성질', '로그함수의 그래프', '상용로그',
      '지수방정식', '지수부등식', '로그방정식', '로그부등식',
    ],
    '수열': [
      '등차수열과 공차', '등차수열의 합', '등비수열과 공비', '등비수열의 합', '등비급수',
      '수열의 일반항', '시그마 기호', '시그마의 성질',
      '점화식', '수학적 귀납법', '군수열',
    ],
  },
  '미적분': {
    '수열의 극한': [
      '수열의 극한', '극한값 계산', '급수의 수렴과 발산', '등비급수 활용',
    ],
    '함수의 극한과 연속': [
      '함수의 극한', '좌극한과 우극한', '연속함수', '불연속점의 분류',
      '중간값 정리', '최대·최소 정리',
    ],
    '미분법': [
      '미분계수', '도함수의 정의', '다항함수의 미분',
      '곱의 미분법', '몫의 미분법', '합성함수의 미분',
      '삼각함수의 미분', '지수·로그함수의 미분', '이계도함수',
    ],
    '미분의 활용': [
      '접선의 방정식', '함수의 증가·감소', '극값',
      '함수의 최댓값·최솟값', '함수의 그래프 개형',
      '방정식의 실근 개수', '속도와 가속도',
    ],
    '적분법': [
      '부정적분', '정적분 계산', '정적분의 성질', '치환적분', '부분적분',
    ],
    '적분의 활용': [
      '정적분과 넓이', '두 곡선 사이의 넓이', '속도와 거리', '입체도형의 부피',
    ],
  },
  '확통': {
    '경우의 수': [
      '경우의 수', '순열', '조합', '중복순열', '중복조합',
    ],
    '확률': [
      '확률의 기본성질', '확률의 덧셈', '여사건의 확률',
      '조건부확률', '확률의 곱셈', '독립사건', '독립시행의 확률',
    ],
    '통계': [
      '확률변수와 확률분포', '이산확률변수의 기댓값', '분산과 표준편차',
      '이항분포', '연속확률변수', '정규분포', '표준정규분포',
      '표준화', '표본평균의 분포', '신뢰구간',
    ],
  },
  '기하': {
    '이차곡선': [
      '포물선', '타원', '쌍곡선', '이차곡선의 접선', '이차곡선과 직선',
    ],
    '평면벡터': [
      '벡터의 정의와 연산', '벡터의 크기', '단위벡터와 방향벡터',
      '벡터의 내적', '벡터의 성분', '위치벡터',
      '직선의 벡터방정식', '원의 벡터방정식',
    ],
    '공간도형과 공간벡터': [
      '공간좌표', '직선과 평면의 위치관계', '이면각과 정사영',
      '공간벡터', '평면의 방정식', '구의 방정식',
    ],
  },
};

// 역호환용 flat map (단원 구분 없이 전체 개념)
Map<String, List<String>> get kCurriculumConcepts {
  final result = <String, List<String>>{};
  for (final entry in kCurriculumTree.entries) {
    result[entry.key] = entry.value.values.expand((e) => e).toList();
  }
  return result;
}

class ConceptListScreen extends StatefulWidget {
  const ConceptListScreen({super.key});

  @override
  State<ConceptListScreen> createState() => _ConceptListScreenState();
}

class _ConceptListScreenState extends State<ConceptListScreen> {
  Map<String, PracticeEntry> _practiceData = {};
  bool _loading = true;
  String _selectedSubject = '전체';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await ConceptService().loadAll();
    setState(() {
      _practiceData = data;
      _loading = false;
    });
  }

  int get totalConcepts =>
      kCurriculumTree.values
          .expand((chapters) => chapters.values)
          .expand((concepts) => concepts)
          .length;

  int get readyConcepts => _practiceData.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 헤더 ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('핵심 개념', style: AppTextStyles.heading1),
                  const SizedBox(height: 4),
                  Row(children: [
                    Text(
                      '교과서 전 범위 $totalConcepts개념',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (readyConcepts > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '연습문제 $readyConcepts개 준비됨',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ]),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── 과목 필터 ─────────────────────────────
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: ['전체', ...kCurriculumTree.keys].map((s) {
                  final selected = s == _selectedSubject;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedSubject = s),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.borderMedium,
                        ),
                      ),
                      child: Text(
                        s,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 8),
            const Divider(height: 1),

            // ── 개념 목록 ─────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                      itemCount: _buildSections().length,
                      itemBuilder: (ctx, i) => _buildSections()[i],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSections() {
    final sections = <Widget>[];
    final subjects = _selectedSubject == '전체'
        ? kCurriculumTree.keys.toList()
        : [_selectedSubject];

    for (final subject in subjects) {
      final chapters = kCurriculumTree[subject] ?? {};
      if (chapters.isEmpty) continue;

      final cColor = curriculumColor(subject);
      final cBg = curriculumBg(subject);

      // 과목 헤더
      sections.add(Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 4),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: cColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              subject,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${chapters.values.expand((e) => e).length}개념',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textTertiary),
          ),
        ]),
      ));

      for (final chapterEntry in chapters.entries) {
        final chapterName = chapterEntry.key;
        final concepts = chapterEntry.value;

        // 단원 헤더
        sections.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6, left: 4),
          child: Row(children: [
            Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                color: cColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              chapterName,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${concepts.length}개',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textTertiary),
            ),
          ]),
        ));

        // 개념 카드들
        for (final concept in concepts) {
          final hasData = _practiceData.containsKey(concept);
          final entry = _practiceData[concept];
          final problemCount = entry?.problems.length ?? 0;

          sections.add(Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ConceptDetailScreen(
                    concept: concept,
                    subject: subject,
                  ),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: hasData ? cBg : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: hasData ? cBg : AppColors.border,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          concept.substring(0, 1),
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: hasData ? cColor : AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            concept,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (hasData)
                            Text(
                              '연습문제 $problemCount개',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: cColor,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          else
                            Text(
                              '준비 중',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textTertiary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: hasData ? AppColors.textSecondary : AppColors.borderMedium,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ));
        }
      }
    }

    return sections;
  }
}
