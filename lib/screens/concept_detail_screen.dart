import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/curriculum.dart';
import '../models/problem.dart';
import '../services/concept_service.dart';
import '../services/problem_service.dart';
import '../services/purchase_service.dart';
import '../widgets/math_text.dart';
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
    final allProblems =
        await ProblemService().loadAll(ProblemService.availableYears);
    final related = allProblems
        .where((p) =>
            p.concepts.contains(widget.concept) ||
            p.unit.contains(widget.concept))
        .take(12)
        .toList();

    if (!mounted) return;
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
    final isPro = context.watch<PurchaseService>().isPro;
    final keyTerms = (_entry?.explanation?['keyTerms'] as List?)
            ?.cast<String>() ??
        [];

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ── 헤더 ─────────────────────────────────────────
            _Header(
              subject: widget.subject,
              concept: widget.concept,
              cColor: cColor,
            ),

            // ── 핵심 키워드 칩 ────────────────────────────────
            if (keyTerms.isNotEmpty)
              _KeyTermsRow(keyTerms: keyTerms, cColor: cColor, cBg: cBg),

            const SizedBox(height: 10),

            // ── 탭 바 ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: cColor,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w700),
                  unselectedLabelStyle:
                      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
                  dividerColor: Colors.transparent,
                  padding: const EdgeInsets.all(4),
                  tabs: const [
                    Tab(text: '개념 설명'),
                    Tab(text: '연습문제'),
                    Tab(text: '수능 기출'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 4),

            // ── 탭 내용 ──────────────────────────────────────
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(color: cColor))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _ExplanationTab(
                          entry: _entry,
                          cColor: cColor,
                          cBg: cBg,
                          isPro: isPro,
                        ),
                        _PracticeTab(
                          entry: _entry,
                          selectedDiff: _selectedDiff,
                          cColor: cColor,
                          isPro: isPro,
                          onDiffChanged: (d) =>
                              setState(() => _selectedDiff = d),
                        ),
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

// ── 헤더 ──────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final String subject;
  final String concept;
  final Color cColor;

  const _Header({
    required this.subject,
    required this.concept,
    required this.cColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderMedium),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.chevron_left_rounded,
                        color: AppColors.textSecondary, size: 18),
                    Text('개념',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        )),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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
          ]),
          const SizedBox(height: 12),
          Text(
            concept,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.8,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// ── 핵심 키워드 칩 ─────────────────────────────────────────────
class _KeyTermsRow extends StatelessWidget {
  final List<String> keyTerms;
  final Color cColor;
  final Color cBg;

  const _KeyTermsRow({
    required this.keyTerms,
    required this.cColor,
    required this.cBg,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '핵심 키워드',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: cColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: keyTerms.map((term) {
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: cBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: cColor.withValues(alpha: 0.25)),
                ),
                child: Text(
                  term,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cColor,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ── 개념 설명 탭 ───────────────────────────────────────────────
class _ExplanationTab extends StatelessWidget {
  final PracticeEntry? entry;
  final Color cColor;
  final Color cBg;
  final bool isPro;

  const _ExplanationTab({
    required this.entry,
    required this.cColor,
    required this.cBg,
    required this.isPro,
  });

  @override
  Widget build(BuildContext context) {
    final exp = entry?.explanation;

    if (exp == null) {
      return _EmptyState(
        emoji: '📚',
        title: '개념 설명 준비 중',
        subtitle: '곧 업데이트됩니다',
      );
    }

    final analogy = exp['analogy'] as String? ?? '';
    final explain = List<String>.from(exp['explain'] as List? ?? []);
    final commonMistakes =
        List<String>.from(exp['commonMistakes'] as List? ?? []);
    final csatTip = exp['csat_tip'] as String? ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ① 직관적으로 이해하기 (FREE)
          if (analogy.isNotEmpty) ...[
            _SectionCard(
              emoji: '💡',
              title: '직관적으로 이해하기',
              color: const Color(0xFFD97706),
              bg: const Color(0xFFFFFBEB),
              borderColor: const Color(0xFFFDE68A),
              child: MathText(
                analogy,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  height: 1.75,
                  color: const Color(0xFF78350F),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // ② 핵심 원리 & 공식 (FREE)
          if (explain.isNotEmpty) ...[
            _SectionCard(
              emoji: '📐',
              title: '핵심 원리 & 공식',
              color: cColor,
              bg: cBg,
              borderColor: cColor.withValues(alpha: 0.2),
              child: _ExplainContent(items: explain, color: cColor),
            ),
            const SizedBox(height: 14),
          ],

          // ③ 흔한 실수 (FREE)
          if (commonMistakes.isNotEmpty) ...[
            _SectionCard(
              emoji: '⚠️',
              title: '이것만은 주의!',
              color: const Color(0xFFEF4444),
              bg: const Color(0xFFFFF1F2),
              borderColor: const Color(0xFFFECACA),
              child: _MistakeList(
                  mistakes: commonMistakes),
            ),
            const SizedBox(height: 14),
          ],

          // ④ 수능 레이더 (PRO)
          if (csatTip.isNotEmpty)
            isPro
                ? _SectionCard(
                    emoji: '🎯',
                    title: '수능 레이더',
                    color: const Color(0xFF7C3AED),
                    bg: const Color(0xFFF5F3FF),
                    borderColor: const Color(0xFFDDD6FE),
                    child: MathText(
                      csatTip,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        height: 1.75,
                        color: const Color(0xFF4C1D95),
                      ),
                    ),
                  )
                : _ProLockedCard(
                    title: '수능 레이더',
                    description: '수능에 자주 나오는 출제 패턴과 함정 공개',
                    emoji: '🎯',
                  ),
        ],
      ),
    );
  }
}

// ── 개념 설명 내용 렌더러 ────────────────────────────────────────
class _ExplainContent extends StatelessWidget {
  final List<String> items;
  final Color color;

  const _ExplainContent({required this.items, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.asMap().entries.map((e) {
        final i = e.key;
        final item = e.value;

        // ## 로 시작하면 섹션 헤더
        if (item.startsWith('## ')) {
          final heading = item.substring(3).trim();
          return Padding(
            padding: EdgeInsets.only(top: i > 0 ? 16 : 0, bottom: 8),
            child: Row(children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                heading,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ]),
          );
        }

        // 일반 항목 — 불릿 포인트
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 9, right: 10),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Expanded(
                child: MathText(
                  item,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    height: 1.75,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── 흔한 실수 리스트 ────────────────────────────────────────────
class _MistakeList extends StatelessWidget {
  final List<String> mistakes;
  const _MistakeList({required this.mistakes});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: mistakes.asMap().entries.map((e) {
        return Padding(
          padding: EdgeInsets.only(bottom: e.key < mistakes.length - 1 ? 10 : 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 3, right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '✗',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: MathText(
                  e.value,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    height: 1.7,
                    color: const Color(0xFF7F1D1D),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── 섹션 카드 ──────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String emoji;
  final String title;
  final Color color;
  final Color bg;
  final Color borderColor;
  final Widget child;

  const _SectionCard({
    required this.emoji,
    required this.title,
    required this.color,
    required this.bg,
    required this.borderColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: -0.2,
                ),
              ),
            ]),
          ),
          Divider(
              height: 1, color: borderColor, thickness: 1),
          // 내용
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ── PRO 잠금 카드 ──────────────────────────────────────────────
class _ProLockedCard extends StatelessWidget {
  final String title;
  final String description;
  final String emoji;

  const _ProLockedCard({
    required this.title,
    required this.description,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => PaywallScreen(lockedFeature: title)),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(emoji,
                    style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'PRO',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 연습문제 탭 ────────────────────────────────────────────────
class _PracticeTab extends StatelessWidget {
  final PracticeEntry? entry;
  final String selectedDiff;
  final Color cColor;
  final bool isPro;
  final ValueChanged<String> onDiffChanged;

  const _PracticeTab({
    required this.entry,
    required this.selectedDiff,
    required this.cColor,
    required this.isPro,
    required this.onDiffChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (entry == null || entry!.problems.isEmpty) {
      return _EmptyState(
        emoji: '✏️',
        title: '연습문제 준비 중',
        subtitle: '곧 추가됩니다',
      );
    }

    final allProblems = entry!.problems;
    // 비구독자: 하 난이도만 무료
    final filtered = selectedDiff == '전체'
        ? (isPro ? allProblems : allProblems.where((p) => p.difficulty == '하').toList())
        : allProblems.where((p) => p.difficulty == selectedDiff).toList();

    return Column(
      children: [
        // 난이도 필터
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
          child: Row(
            children: ['전체', '하', '중', '상'].map((d) {
              final selected = d == selectedDiff;
              final locked = !isPro && (d == '중' || d == '상');
              return GestureDetector(
                onTap: () {
                  if (locked) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const PaywallScreen(lockedFeature: '심화 연습문제')),
                    );
                    return;
                  }
                  onDiffChanged(d);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? cColor : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? cColor : AppColors.borderMedium,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        d == '전체'
                            ? '전체 ${allProblems.length}'
                            : d,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                      if (locked) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.lock_rounded,
                            size: 12,
                            color: selected
                                ? Colors.white
                                : AppColors.textTertiary),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        if (!isPro)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        const PaywallScreen(lockedFeature: '심화 연습문제')),
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.lock_rounded,
                      color: AppColors.primary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'PRO 구독 시 중·상 난이도 + 상세 풀이 트리 전체 공개',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text('구독하기 →',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      )),
                ]),
              ),
            ),
          ),

        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 48),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (ctx, i) =>
                _PracticeCard(problem: filtered[i], isPro: isPro),
          ),
        ),
      ],
    );
  }
}

// ── 연습문제 카드 ───────────────────────────────────────────────
class _PracticeCard extends StatefulWidget {
  final PracticeProblem problem;
  final bool isPro;
  const _PracticeCard({required this.problem, required this.isPro});

  @override
  State<_PracticeCard> createState() => _PracticeCardState();
}

class _PracticeCardState extends State<_PracticeCard> {
  bool _showTree = false;
  bool _showAnswer = false;

  Color get _diffColor {
    switch (widget.problem.difficulty) {
      case '상': return const Color(0xFFEF4444);
      case '중': return const Color(0xFFD97706);
      default:   return const Color(0xFF16A34A);
    }
  }

  Color get _diffBg {
    switch (widget.problem.difficulty) {
      case '상': return const Color(0xFFFEE2E2);
      case '중': return const Color(0xFFFEF3C7);
      default:   return const Color(0xFFDCFCE7);
    }
  }

  String get _diffLabel {
    switch (widget.problem.difficulty) {
      case '상': return '심화';
      case '중': return '표준';
      default:   return '기본';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 문제 영역
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 난이도 배지
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _diffBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _diffLabel,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _diffColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 문제 텍스트
                MathText(
                  widget.problem.question,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    height: 1.75,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),

                // 버튼
                Row(children: [
                  _ActionBtn(
                    label: _showTree ? '트리 접기' : '풀이 트리',
                    icon: Icons.account_tree_rounded,
                    color: AppColors.primary,
                    locked: !widget.isPro &&
                        widget.problem.difficulty != '하',
                    onTap: () {
                      if (!widget.isPro &&
                          widget.problem.difficulty != '하') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PaywallScreen(
                                  lockedFeature: '풀이 트리')),
                        );
                        return;
                      }
                      setState(() => _showTree = !_showTree);
                    },
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

                // 정답 영역
                if (_showAnswer) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFFFDE68A)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('정답',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFD97706),
                              letterSpacing: 0.5,
                            )),
                        const SizedBox(height: 6),
                        MathText(
                          widget.problem.answerValue,
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF92400E),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('💡 ',
                                style: const TextStyle(fontSize: 13)),
                            Expanded(
                              child: MathText(
                                widget.problem.hint,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFF78350F),
                                  height: 1.6,
                                ),
                              ),
                            ),
                          ],
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
            Divider(height: 1, color: AppColors.borderMedium),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '조건분해트리',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
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
                                    size: 22,
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
  final bool locked;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(locked ? Icons.lock_rounded : icon,
                size: 14, color: color),
            const SizedBox(width: 5),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ]),
        ),
      );
}

// ── 수능 기출 탭 ────────────────────────────────────────────────
class _RelatedTab extends StatelessWidget {
  final List<Problem> problems;
  const _RelatedTab({required this.problems});

  @override
  Widget build(BuildContext context) {
    if (problems.isEmpty) {
      return _EmptyState(
        emoji: '📋',
        title: '관련 수능 기출이 없습니다',
        subtitle: '',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 48),
      itemCount: problems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final p = problems[i];
        final c = getCurriculum(p.unit);
        final cColor = curriculumColor(c);
        final cBg = curriculumBg(c);

        Color diffColor;
        Color diffBg;
        String diffLabel;
        switch (p.difficulty) {
          case '상':
            diffColor = const Color(0xFFEF4444);
            diffBg = const Color(0xFFFEE2E2);
            diffLabel = '킬러';
            break;
          case '중':
            diffColor = const Color(0xFFD97706);
            diffBg = const Color(0xFFFEF3C7);
            diffLabel = '준킬러';
            break;
          default:
            diffColor = const Color(0xFF16A34A);
            diffBg = const Color(0xFFDCFCE7);
            diffLabel = '기본';
        }

        return GestureDetector(
          onTap: () => Navigator.push(
            ctx,
            MaterialPageRoute(builder: (_) => TreeScreen(problem: p)),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderMedium),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                            color: cBg,
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(c,
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: cColor)),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                            color: diffBg,
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(diffLabel,
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: diffColor)),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                      '${p.year}학년도 ${p.no}번',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      p.unit.isNotEmpty ? p.unit : '${p.no}번 문항',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '유도 ${p.nodeDepth}단계',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chevron_right_rounded,
                    color: AppColors.primary, size: 20),
              ),
            ]),
          ),
        );
      },
    );
  }
}

// ── 빈 상태 ────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            Text(title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}
