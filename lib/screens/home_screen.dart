import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
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
  List<Problem> _dailyThree = [];   // 오늘의 3문제
  List<Problem> _recommended = [];
  List<_WrongNoteItem> _reviewItems = [];
  bool _loading = true;
  final Set<String> _solvedToday = {};

  @override
  void initState() {
    super.initState();
    WrongNoteService().addListener(_refreshReview);
    _loadData();
  }

  @override
  void dispose() {
    WrongNoteService().removeListener(_refreshReview);
    super.dispose();
  }

  void _refreshReview() {
    if (!mounted) return;
    _loadReviewItems();
  }

  Future<void> _loadData() async {
    final all =
        await ProblemService().loadAll([2024, 2023, 2022, 2021, 2020]);
    if (!mounted) return;

    // 오늘의 3문제: 날짜 시드로 매일 같은 3문제 (하/중/상 각 1개)
    final seed = _todaySeed();
    final rng = Random(seed);
    final easy =
        all.where((p) => p.difficulty == '하').toList()..shuffle(rng);
    final mid =
        all.where((p) => p.difficulty == '중').toList()..shuffle(rng);
    final hard =
        all.where((p) => p.difficulty == '상').toList()..shuffle(rng);

    final daily = [
      if (easy.isNotEmpty) easy.first,
      if (mid.isNotEmpty) mid.first,
      if (hard.isNotEmpty) hard.first,
    ];

    final sorted = [...all]..sort((a, b) => b.year.compareTo(a.year));

    setState(() {
      _dailyThree = daily;
      _recommended =
          sorted.where((p) => p.difficulty != '하').take(5).toList();
      _loading = false;
    });
    _loadReviewItems();
  }

  Future<void> _loadReviewItems() async {
    final notes = WrongNoteService().all.toList()
      ..sort((a, b) => a.reviewCount.compareTo(b.reviewCount));
    final items = <_WrongNoteItem>[];
    for (final note in notes.take(3)) {
      final problems = await ProblemService().loadYear(note.year);
      final p = problems.where((p) => p.id == note.problemId).firstOrNull;
      if (p != null) items.add(_WrongNoteItem(note: note, problem: p));
    }
    if (!mounted) return;
    setState(() => _reviewItems = items);
  }

  int _todaySeed() {
    final now = DateTime.now();
    return now.year * 10000 + now.month * 100 + now.day;
  }

  @override
  Widget build(BuildContext context) {
    final prog = context.watch<GameService>().progress;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── 헤더 ────────────────────────────────────────
            SliverToBoxAdapter(child: _NunHeader()),

            // ── 오늘의 3문제 카드 ─────────────────────────────
            SliverToBoxAdapter(
              child: _DailyThreeCard(
                problems: _dailyThree,
                solvedToday: _solvedToday,
                onSolved: (id) => setState(() => _solvedToday.add(id)),
                loading: _loading,
              ),
            ),

            // ── XP + 스트릭 카드 ──────────────────────────────
            SliverToBoxAdapter(
              child: _XpCard(
                level: prog.level.level,
                xp: prog.totalXp,
                streak: prog.streakDays,
                progress: prog.levelProgress,
              ),
            ),

            // ── 오답노트 복습 ─────────────────────────────────
            if (_reviewItems.isNotEmpty) ...[
              SliverToBoxAdapter(child: _SectionHeader(
                icon: Icons.refresh_rounded,
                iconColor: const Color(0xFFEF4444),
                iconBg: const Color(0xFFFEE2E2),
                title: '오답노트 복습',
                badge: '${WrongNoteService().all.length}문제',
                badgeColor: const Color(0xFFEF4444),
                badgeBg: const Color(0xFFFEE2E2),
                actionLabel: '전체보기 →',
                onAction: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const WrongNoteScreen())),
              )),
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

            // ── 추천 문제 ─────────────────────────────────────
            SliverToBoxAdapter(child: _SectionHeader(
              icon: Icons.star_rounded,
              iconColor: const Color(0xFFD97706),
              iconBg: const Color(0xFFFEF3C7),
              title: '추천 문제',
              actionLabel: '전체보기 →',
              onAction: () {},
            )),
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
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 48),
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
}

// ── 눈수학 헤더 ────────────────────────────────────────────────
class _NunHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? '좋은 아침이에요! ☀️'
        : hour < 18
            ? '집중하는 시간이에요! 💪'
            : '오늘 마무리 잘 하고 있어요! 🌙';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '눈수학',
                      style: GoogleFonts.inter(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '눈으로 보면 이해된다',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none_rounded,
                color: AppColors.primary, size: 22),
          ),
        ],
      ),
    );
  }
}

// ── 오늘의 3문제 카드 ──────────────────────────────────────────
class _DailyThreeCard extends StatelessWidget {
  final List<Problem> problems;
  final Set<String> solvedToday;
  final ValueChanged<String> onSolved;
  final bool loading;

  const _DailyThreeCard({
    required this.problems,
    required this.solvedToday,
    required this.onSolved,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final solved = problems.where((p) => solvedToday.contains(p.id)).length;
    final total = problems.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '매일 아침 3문제로 1등급',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.75),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '오늘의 3문제',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$solved / $total 완료',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ]),
            ),

            // 프로그레스 바
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: total > 0 ? solved / total : 0,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor:
                      const AlwaysStoppedAnimation(Colors.white),
                  minHeight: 5,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 문제 리스트
            if (loading)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              )
            else
              ...problems.asMap().entries.map((e) {
                final i = e.key;
                final p = e.value;
                final isSolved = solvedToday.contains(p.id);
                final c = getCurriculum(p.unit);
                final label = ['기본', '표준', '심화'][
                    i.clamp(0, 2)];

                return GestureDetector(
                  onTap: () {
                    onSolved(p.id);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => TreeScreen(problem: p)),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSolved
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSolved
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isSolved
                              ? Colors.white.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isSolved
                              ? const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 16)
                              : Text(
                                  '${i + 1}',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
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
                              p.unit.isNotEmpty
                                  ? p.unit
                                  : '${p.no}번',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isSolved
                                    ? Colors.white.withValues(alpha: 0.5)
                                    : Colors.white,
                              ),
                            ),
                            Text(
                              '$label · ${p.year}학년도 ${p.no}번 · $c',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isSolved
                            ? Icons.check_circle_rounded
                            : Icons.chevron_right_rounded,
                        color: Colors.white
                            .withValues(alpha: isSolved ? 0.4 : 0.7),
                        size: 20,
                      ),
                    ]),
                  ),
                );
              }),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

// ── XP 카드 ──────────────────────────────────────────────────
class _XpCard extends StatelessWidget {
  final int level;
  final int xp;
  final int streak;
  final double progress;

  const _XpCard({
    required this.level,
    required this.xp,
    required this.streak,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(children: [
            // 레벨 + XP
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('LEVEL $level',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: 1,
                        )),
                  ),
                  const SizedBox(height: 6),
                  Text('$xp XP',
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: -0.5,
                      )),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.primaryLight,
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.primary),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '다음 레벨까지 ${((1 - progress) * 100).round()}%',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // 스트릭
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Column(
                children: [
                  Text('🔥',
                      style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 4),
                  Text(
                    '$streak일',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFEA580C),
                    ),
                  ),
                  Text('연속',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFFEA580C)
                            .withValues(alpha: 0.7),
                      )),
                ],
              ),
            ),
          ]),
        ),
      );
}

// ── 섹션 헤더 ─────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String? badge;
  final Color? badgeColor;
  final Color? badgeBg;
  final String actionLabel;
  final VoidCallback onAction;

  const _SectionHeader({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    this.badge,
    this.badgeColor,
    this.badgeBg,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  )),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(badge!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: badgeColor,
                      )),
                ),
              ],
            ]),
            GestureDetector(
              onTap: onAction,
              child: Text(actionLabel,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  )),
            ),
          ],
        ),
      );
}

// ── 오답 복습 관련 ────────────────────────────────────────────
class _WrongNoteItem {
  final WrongNote note;
  final Problem problem;
  const _WrongNoteItem({required this.note, required this.problem});
}

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
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => TreeScreen(problem: p)));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isFirst
                ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                : AppColors.borderMedium,
            width: isFirst ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(children: [
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
              child: Text(isFirst ? '📌' : '🔁',
                  style: const TextStyle(fontSize: 20)),
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
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: cBg,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(c,
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: cColor)),
                  ),
                ]),
                const SizedBox(height: 6),
                Text(
                  '${p.year}학년도 ${p.no}번 · ${p.unit}',
                  style: GoogleFonts.inter(
                    fontSize: 15,
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
        ]),
      ),
    );
  }
}

// ── 추천 문제 카드 ────────────────────────────────────────────
class _ProblemCard extends StatelessWidget {
  final Problem problem;
  const _ProblemCard({required this.problem});

  @override
  Widget build(BuildContext context) {
    final c = getCurriculum(problem.unit);
    final cColor = curriculumColor(c);
    final cBg = curriculumBg(c);

    Color diffColor;
    Color diffBg;
    String diffLabel;
    switch (problem.difficulty) {
      case '상':
        diffColor = AppColors.diffHard;
        diffBg = AppColors.diffHardBg;
        diffLabel = '심화';
        break;
      case '중':
        diffColor = AppColors.diffMid;
        diffBg = AppColors.diffMidBg;
        diffLabel = '표준';
        break;
      default:
        diffColor = AppColors.diffEasy;
        diffBg = AppColors.diffEasyBg;
        diffLabel = '기본';
    }

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => TreeScreen(problem: problem))),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
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
              _Chip(label: c, color: cColor, bg: cBg),
              const SizedBox(width: 8),
              _Chip(label: diffLabel, color: diffColor, bg: diffBg),
              const Spacer(),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textTertiary, size: 18),
            ]),
            const SizedBox(height: 10),
            Text(
              problem.unit.isNotEmpty ? problem.unit : '${problem.no}번',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '${problem.year}학년도 ${problem.no}번 · 유도 ${problem.nodeDepth}단계',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const _Chip({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      );
}
