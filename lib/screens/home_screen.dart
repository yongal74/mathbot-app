import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../core/curriculum.dart';
import '../services/game_service.dart';
import '../services/problem_service.dart';
import '../services/wrong_note_service.dart';
import '../models/problem.dart';
import '../models/wrong_note.dart';
import 'tree_screen.dart';
import 'wrong_note_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _game = GameService();
  final _wrongNote = WrongNoteService();
  List<Problem> _recommended = [];
  List<_WrongNoteItem> _reviewItems = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _wrongNote.addListener(_refreshReview);
    _loadData();
  }

  @override
  void dispose() {
    _wrongNote.removeListener(_refreshReview);
    super.dispose();
  }

  void _refreshReview() {
    if (!mounted) return;
    _loadReviewItems();
  }

  Future<void> _loadData() async {
    final all = await ProblemService().loadAll([2024, 2023, 2022, 2021, 2020]);
    final sorted = [...all]..sort((a, b) => b.year.compareTo(a.year));
    if (!mounted) return;
    setState(() {
      _recommended = sorted.where((p) => p.difficulty != '하').take(5).toList();
      _loading = false;
    });
    _loadReviewItems();
  }

  Future<void> _loadReviewItems() async {
    final notes = _wrongNote.all.toList()
      ..sort((a, b) => a.reviewCount.compareTo(b.reviewCount)); // 복습 적은 순
    final items = <_WrongNoteItem>[];
    for (final note in notes.take(3)) {
      final problems = await ProblemService().loadYear(note.year);
      final p = problems.where((p) => p.id == note.problemId).firstOrNull;
      if (p != null) items.add(_WrongNoteItem(note: note, problem: p));
    }
    if (!mounted) return;
    setState(() => _reviewItems = items);
  }

  @override
  Widget build(BuildContext context) {
    final prog = _game.progress;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _header()),
            SliverToBoxAdapter(
                child: _xpCard(prog.level.level, prog.totalXp,
                    prog.streakDays, prog.levelProgress)),

            // ── 오답노트 복습 섹션 ────────────────────────
            if (_reviewItems.isNotEmpty) ...[
              SliverToBoxAdapter(child: _reviewSectionHeader()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ReviewCard(item: _reviewItems[i]),
                    ),
                    childCount: _reviewItems.length,
                  ),
                ),
              ),
            ],

            // ── 추천 문제 섹션 ────────────────────────────
            SliverToBoxAdapter(child: _recommendSectionHeader()),
            if (_loading)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ProblemCard(problem: _recommended[i]),
                    ),
                    childCount: _recommended.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '오늘도 화이팅! 🎯',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('수학 풀이 트리', style: AppTextStyles.heading1),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_none_rounded,
                  color: AppColors.primary, size: 20),
            ),
          ],
        ),
      );

  Widget _xpCard(int level, int xp, int streak, double progress) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'LEVEL $level',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$xp XP',
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '🔥 $streak',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '연속',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('다음 레벨까지',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7))),
                  Text('${(progress * 100).round()}%',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  valueColor:
                      const AlwaysStoppedAnimation(Colors.white),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _reviewSectionHeader() => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text('오답노트 복습', style: AppTextStyles.heading3),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_wrongNote.all.length}문제',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ),
            ]),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const WrongNoteScreen()),
              ),
              child: Text(
                '전체보기 →',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _recommendSectionHeader() => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('오늘의 추천 문제', style: AppTextStyles.heading3),
            Text(
              '전체보기 →',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      );
}

// ── 오답노트 복습 아이템 ───────────────────────────────────────
class _WrongNoteItem {
  final WrongNote note;
  final Problem problem;
  const _WrongNoteItem({required this.note, required this.problem});
}

// ── 오답노트 복습 카드 ──────────────────────────────────────────
class _ReviewCard extends StatelessWidget {
  final _WrongNoteItem item;
  const _ReviewCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final p = item.problem;
    final note = item.note;
    final c = getCurriculum(p.unit);
    final cColor = curriculumColor(c);
    final cBg = curriculumBg(c);
    final isFirst = note.reviewCount == 0;

    return GestureDetector(
      onTap: () {
        WrongNoteService().markReviewed(note.problemId);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TreeScreen(problem: p)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isFirst
                ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                : AppColors.borderMedium,
            width: isFirst ? 1.5 : 1,
          ),
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
            // 좌측 아이콘
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isFirst
                    ? const Color(0xFFFEE2E2)
                    : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  isFirst ? '📌' : '🔁',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                          color: cBg,
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(c,
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: cColor)),
                    ),
                    const SizedBox(width: 6),
                    if (note.weakNodes.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '❓ ${_nodeLabel(note.weakNodes.first)}',
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFEF4444)),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 6),
                  Text(
                    '${p.year}학년도 ${p.no}번 · ${p.unit}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isFirst ? '아직 복습하지 않았어요' : '복습 ${note.reviewCount}회',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isFirst
                          ? const Color(0xFFEF4444)
                          : AppColors.textSecondary,
                      fontWeight: isFirst ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }

  String _nodeLabel(String type) {
    const labels = {
      'given': '조건', 'formula': '공식', 'derive': '유도',
      'calculate': '계산', 'answer': '정답',
    };
    return labels[type] ?? type;
  }
}

// ── 추천 문제 카드 ──────────────────────────────────────────────
class _ProblemCard extends StatelessWidget {
  final Problem problem;
  const _ProblemCard({required this.problem});

  @override
  Widget build(BuildContext context) {
    final c = getCurriculum(problem.unit);
    final cColor = curriculumColor(c);
    final cBg = curriculumBg(c);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TreeScreen(problem: problem)),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
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
            Row(children: [
              _Badge(label: c, color: cColor, bg: cBg),
              const SizedBox(width: 8),
              _Badge(
                label: problem.difficulty,
                color: _diffColor(problem.difficulty),
                bg: _diffBg(problem.difficulty),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textTertiary, size: 18),
            ]),
            const SizedBox(height: 10),
            Text(
              problem.unit.isNotEmpty ? problem.unit : '${problem.no}번',
              style: AppTextStyles.cardTitle,
            ),
            const SizedBox(height: 6),
            Row(children: [
              Container(
                width: 6,
                height: 6,
                decoration:
                    BoxDecoration(color: cColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                '${problem.year}학년도 ${problem.no}번 · 유도 ${problem.nodeDepth}단계',
                style: AppTextStyles.bodySmall,
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Color _diffColor(String d) {
    switch (d) {
      case '상': return AppColors.diffHard;
      case '중': return AppColors.diffMid;
      default:   return AppColors.diffEasy;
    }
  }

  Color _diffBg(String d) {
    switch (d) {
      case '상': return AppColors.diffHardBg;
      case '중': return AppColors.diffMidBg;
      default:   return AppColors.diffEasyBg;
    }
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const _Badge({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      );
}
