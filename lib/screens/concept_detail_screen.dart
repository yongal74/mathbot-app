import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../core/curriculum.dart';
import '../core/math_format.dart';
import '../models/problem.dart';
import '../services/concept_service.dart';
import '../services/problem_service.dart';
import '../widgets/tree_node_card.dart';
import 'tree_screen.dart';
import 'paywall_screen.dart';

class ConceptDetailScreen extends StatefulWidget {
  final String concept;
  final String subject;

  const ConceptDetailScreen({
    super.key,
    required this.concept,
    required this.subject,
  });

  @override
  State<ConceptDetailScreen> createState() => _ConceptDetailScreenState();
}

class _ConceptDetailScreenState extends State<ConceptDetailScreen>
    with SingleTickerProviderStateMixin {
  PracticeEntry? _entry;
  List<Problem> _relatedProblems = [];
  bool _loading = true;
  String _selectedDiff = '전체';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final entry = await ConceptService().loadConcept(widget.concept);
    // 관련 수능 기출 찾기
    final allProblems = await ProblemService().loadAll(
        ProblemService.availableYears);
    final related = allProblems
        .where((p) => p.concepts.contains(widget.concept) ||
            p.unit.contains(widget.concept))
        .take(10)
        .toList();

    setState(() {
      _entry = entry;
      _relatedProblems = related;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cColor = curriculumColor(widget.subject);
    final cBg = curriculumBg(widget.subject);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── 헤더 ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.chevron_left_rounded,
                              color: AppColors.primary, size: 18),
                          const SizedBox(width: 2),
                          Text('개념',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              )),
                        ]),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.subject,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ]),
            ),

            // ── 타이틀 ───────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.concept,
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ── 탭 바 ────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle:
                    GoogleFonts.inter(fontSize: 13),
                dividerColor: Colors.transparent,
                padding: const EdgeInsets.all(4),
                tabs: const [
                  Tab(text: '개념 설명'),
                  Tab(text: '연습문제'),
                  Tab(text: '수능 기출'),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // ── 탭 내용 ──────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _ExplanationTab(
                            entry: _entry, cColor: cColor, cBg: cBg),
                        _PracticeTab(
                            entry: _entry,
                            selectedDiff: _selectedDiff,
                            onDiffChanged: (d) =>
                                setState(() => _selectedDiff = d)),
                        _RelatedTab(problems: _relatedProblems),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 개념 설명 탭 ──────────────────────────────────────
class _ExplanationTab extends StatelessWidget {
  final PracticeEntry? entry;
  final Color cColor;
  final Color cBg;
  static const bool isPro = false;

  const _ExplanationTab(
      {required this.entry, required this.cColor, required this.cBg});

  @override
  Widget build(BuildContext context) {
    final explanation = entry?.explanation;

    if (explanation == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('📚', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text(
                '개념 설명 준비 중',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '곧 업데이트됩니다',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 💡 직관적 이해
          _ExplainBlock(
            emoji: '💡',
            title: '직관적으로 이해하기',
            color: const Color(0xFFF59E0B),
            bg: const Color(0xFFFFFBEB),
            content: explanation['analogy'] ?? '',
            isStory: true,
          ),
          const SizedBox(height: 12),

          // 📐 수학적 본질
          if (isPro)
            _ExplainBlock(
              emoji: '📐',
              title: '수학적 본질',
              color: AppColors.primary,
              bg: AppColors.primaryLight,
              content: '',
              bullets: List<String>.from(
                  explanation['explain'] as List? ?? []),
            )
          else
            _lockedBlock(title: '수학적 본질', context: context),
          const SizedBox(height: 12),

          // 🎯 수능 레이더
          if (isPro)
            _ExplainBlock(
              emoji: '🎯',
              title: '수능 레이더',
              color: const Color(0xFFEF4444),
              bg: const Color(0xFFFFF1F2),
              content: explanation['csat_tip'] ?? '',
            )
          else
            _lockedBlock(title: '수능 레이더', context: context),
        ],
      ),
    );
  }

  // 잠금 오버레이 (유료 콘텐츠)
  Widget _lockedBlock(
      {required String title, required BuildContext context}) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => PaywallScreen(lockedFeature: title)),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.lock_rounded,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'PRO 구독으로 잠금 해제',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'PRO',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExplainBlock extends StatelessWidget {
  final String emoji;
  final String title;
  final Color color;
  final Color bg;
  final String content;
  final List<String> bullets;
  final bool isStory;

  const _ExplainBlock({
    required this.emoji,
    required this.title,
    required this.color,
    required this.bg,
    required this.content,
    this.bullets = const [],
    this.isStory = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ]),
          const SizedBox(height: 10),
          if (bullets.isNotEmpty)
            ...bullets.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6, right: 8),
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                              color: color, shape: BoxShape.circle),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          mathToKorean(b),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            height: 1.6,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
          else
            Text(
              mathToKorean(content),
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.7,
                color: AppColors.textPrimary,
                fontStyle:
                    isStory ? FontStyle.italic : FontStyle.normal,
              ),
            ),
        ],
      ),
    );
  }
}

// ── 연습문제 탭 ───────────────────────────────────────
class _PracticeTab extends StatelessWidget {
  final PracticeEntry? entry;
  final String selectedDiff;
  final ValueChanged<String> onDiffChanged;

  const _PracticeTab({
    required this.entry,
    required this.selectedDiff,
    required this.onDiffChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (entry == null || entry!.problems.isEmpty) {
      return Center(
        child: Text('연습문제 준비 중',
            style: AppTextStyles.bodySmall),
      );
    }

    final filtered = selectedDiff == '전체'
        ? entry!.problems
        : entry!.problems
            .where((p) => p.difficulty == selectedDiff)
            .toList();

    return Column(
      children: [
        // 난이도 필터
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(
            children: ['전체', '하', '중', '상'].map((d) {
              final selected = d == selectedDiff;
              return GestureDetector(
                onTap: () => onDiffChanged(d),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
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
                    d == '전체' ? '전체 ${entry!.problems.length}' : '$d난이도',
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

        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (ctx, i) =>
                _PracticeCard(problem: filtered[i]),
          ),
        ),
      ],
    );
  }
}

class _PracticeCard extends StatefulWidget {
  final PracticeProblem problem;
  const _PracticeCard({required this.problem});

  @override
  State<_PracticeCard> createState() => _PracticeCardState();
}

class _PracticeCardState extends State<_PracticeCard> {
  bool _showTree = false;
  bool _showAnswer = false;

  Color get _diffColor {
    switch (widget.problem.difficulty) {
      case '상': return const Color(0xFFEF4444);
      case '중': return const Color(0xFFCA8A04);
      default:   return const Color(0xFF16A34A);
    }
  }

  Color get _diffBg {
    switch (widget.problem.difficulty) {
      case '상': return const Color(0xFFFEE2E2);
      case '중': return const Color(0xFFFEF9C3);
      default:   return const Color(0xFFDCFCE7);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 문제
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _diffBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${widget.problem.difficulty}난이도',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _diffColor,
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                Text(
                  mathToKorean(widget.problem.question),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    height: 1.65,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),

                // 버튼들
                Row(children: [
                  _ActionBtn(
                    label: _showTree ? '트리 접기' : '풀이 트리',
                    icon: Icons.account_tree_rounded,
                    color: AppColors.primary,
                    onTap: () =>
                        setState(() => _showTree = !_showTree),
                  ),
                  const SizedBox(width: 8),
                  _ActionBtn(
                    label: _showAnswer ? '정답 숨기기' : '정답 보기',
                    icon: Icons.lightbulb_rounded,
                    color: const Color(0xFFD97706),
                    onTap: () =>
                        setState(() => _showAnswer = !_showAnswer),
                  ),
                ]),

                if (_showAnswer) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('정답',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            )),
                        const SizedBox(height: 4),
                        Text(
                          mathToKorean(widget.problem.answerValue),
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '💡 ${mathToKorean(widget.problem.hint)}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 조건분해트리
          if (_showTree && widget.problem.nodes.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '조건분해트리',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...widget.problem.nodes
                      .asMap()
                      .entries
                      .expand((e) => [
                            TreeNodeCard(node: e.value),
                            if (e.key <
                                widget.problem.nodes.length - 1)
                              const Padding(
                                padding:
                                    EdgeInsets.symmetric(vertical: 4),
                                child: Center(
                                  child: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: AppColors.textTertiary,
                                    size: 20,
                                  ),
                                ),
                              ),
                          ]),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ]),
        ),
      );
}

// ── 수능 기출 탭 ──────────────────────────────────────
class _RelatedTab extends StatelessWidget {
  final List<Problem> problems;

  const _RelatedTab({required this.problems});

  @override
  Widget build(BuildContext context) {
    if (problems.isEmpty) {
      return Center(
        child: Text('관련 수능 기출이 없습니다',
            style: AppTextStyles.bodySmall),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      itemCount: problems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final p = problems[i];
        final c = getCurriculum(p.unit);
        final cColor = curriculumColor(c);
        final cBg = curriculumBg(c);

        return GestureDetector(
          onTap: () => Navigator.push(
            ctx,
            MaterialPageRoute(
                builder: (_) => TreeScreen(problem: p)),
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderMedium),
            ),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: cBg,
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(c,
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: cColor)),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${p.year}학년도 ${p.no}번',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    Text(
                      p.unit.isNotEmpty ? p.unit : '${p.no}번',
                      style: AppTextStyles.cardTitle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '유도 ${p.nodeDepth}단계',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textTertiary, size: 20),
            ]),
          ),
        );
      },
    );
  }
}
