import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../core/curriculum.dart';
import '../services/concept_service.dart';
import 'concept_detail_screen.dart';

// 교육과정 순서별 개념 목록
const Map<String, List<String>> kCurriculumConcepts = {
  '공통수학1': [
    '다항식의 덧셈과 뺄셈', '다항식의 곱셈', '인수분해', '나머지정리',
    '항등식', '이차방정식의 판별식', '근과 계수의 관계',
    '고차방정식', '연립방정식', '이차부등식', '절댓값 부등식',
    '복소수', '허수단위',
  ],
  '공통수학2': [
    '집합의 연산', '명제와 조건', '역·이·대우', '집합의 원소 개수',
    '합성함수', '역함수', '유리함수', '무리함수',
    '경우의 수', '순열', '조합', '이항정리',
  ],
  '대수': [
    '지수법칙', '거듭제곱근', '지수함수', '로그의 정의', '로그의 성질',
    '로그함수', '상용로그', '지수방정식', '로그방정식',
    '등차수열', '등비수열', '일반항', '점화식', '수열의 합',
    '시그마 기호', '수학적 귀납법', '군수열',
  ],
  '미적분': [
    '수열의 극한', '극한값 계산', '함수의 극한', '연속함수', '불연속점',
    '미분계수', '도함수', '다항함수의 미분', '곱의 미분법',
    '몫의 미분법', '합성함수의 미분', '삼각함수의 미분',
    '지수·로그함수의 미분', '접선의 방정식', '함수의 증가·감소',
    '극값', '최댓값·최솟값', '정적분 계산', '정적분과 넓이',
    '치환적분', '부분적분', '속도와 거리',
  ],
  '확통': [
    '경우의 수', '순열', '조합', '중복순열', '중복조합',
    '확률의 덧셈', '확률의 곱셈', '조건부확률',
    '독립사건', '여사건', '확률변수', '이항분포',
    '정규분포', '표준화', '표본평균', '신뢰구간',
  ],
  '기하': [
    '벡터의 덧셈', '벡터의 내적', '벡터의 크기', '단위벡터',
    '직선의 방정식', '원의 방정식', '포물선', '타원', '쌍곡선',
    '이차곡선의 접선', '공간좌표', '공간벡터', '구의 방정식',
  ],
};

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
      kCurriculumConcepts.values.fold(0, (s, list) => s + list.length);

  int get readyConcepts => _practiceData.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                children: ['전체', ...kCurriculumOrder].map((s) {
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
        ? kCurriculumConcepts.keys.toList()
        : [_selectedSubject];

    for (final subject in subjects) {
      final concepts = kCurriculumConcepts[subject] ?? [];
      if (concepts.isEmpty) continue;

      final cColor = curriculumColor(subject);
      final cBg = curriculumBg(subject);

      // 섹션 헤더
      sections.add(Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 10),
        child: Row(children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: cColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              subject,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${concepts.length}개념',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
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
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (hasData)
                          Text(
                            '연습문제 ${problemCount}개',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: cColor,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        else
                          Text(
                            '준비 중',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textTertiary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: hasData
                        ? AppColors.textSecondary
                        : AppColors.borderMedium,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ));
      }
    }

    return sections;
  }
}
