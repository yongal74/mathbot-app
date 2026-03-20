import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../core/curriculum.dart';
import '../models/problem.dart';
import '../services/problem_service.dart';
import 'tree_screen.dart';

class ProblemListScreen extends StatefulWidget {
  const ProblemListScreen({super.key});

  @override
  State<ProblemListScreen> createState() => _ProblemListScreenState();
}

class _ProblemListScreenState extends State<ProblemListScreen> {
  List<Problem> _all = [];
  List<Problem> _filtered = [];
  bool _loading = true;

  String _selectedCurriculum = '전체';
  String _selectedYear = '전체';

  static const _yearOptions = [
    '전체', '최근 3년', '2000~2004',
    '2024', '2023', '2022', '2021', '2020',
    '2019', '2018', '2017', '2016', '2015', '2014', '2013', '2012',
    '2011', '2010', '2009', '2008', '2007', '2006', '2005',
    '2004', '2003', '2002', '2001', '2000',
  ];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final problems = await ProblemService().loadAll(
        ProblemService.availableYears); // 2000~2024 전체
    // 교과 순서로 정렬
    problems.sort((a, b) {
      final ca = kCurriculumOrder.indexOf(getCurriculum(a.unit));
      final cb = kCurriculumOrder.indexOf(getCurriculum(b.unit));
      if (ca != cb) return ca.compareTo(cb);
      return b.year.compareTo(a.year);
    });
    setState(() {
      _all = problems;
      _filtered = problems;
      _loading = false;
    });
  }

  void _applyFilters() {
    setState(() {
      _filtered = _all.where((p) {
        // 교과 필터
        if (_selectedCurriculum != '전체' &&
            getCurriculum(p.unit) != _selectedCurriculum) {
          return false;
        }
        // 연도 필터
        if (_selectedYear == '최근 3년') {
          return p.year >= 2022;
        } else if (_selectedYear == '2000~2004') {
          return p.year >= 2000 && p.year <= 2004;
        } else if (_selectedYear != '전체') {
          return p.year == int.tryParse(_selectedYear);
        }
        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 헤더 ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('문제 목록', style: AppTextStyles.heading1),
                  const SizedBox(height: 4),
                  Text(
                    '2000~2024 수능 기출 750문제',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // ── 교과 필터 (가로 스크롤) ───────────
            _buildCurriculumFilter(),
            const SizedBox(height: 8),

            // ── 연도 필터 ─────────────────────────
            _buildYearFilter(),
            const SizedBox(height: 8),

            const Divider(height: 1),

            // ── 문제 목록 ─────────────────────────
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary))
                  : _filtered.isEmpty
                      ? Center(
                          child: Text(
                            '해당 조건의 문제가 없습니다',
                            style: AppTextStyles.bodySmall,
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                              20, 12, 20, 32),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (ctx, i) =>
                              _ProblemRow(problem: _filtered[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurriculumFilter() {
    final options = ['전체', ...kCurriculumOrder];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final opt = options[i];
          final selected = opt == _selectedCurriculum;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedCurriculum = opt);
              _applyFilters();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? AppColors.primary
                      : AppColors.borderMedium,
                ),
              ),
              child: Text(
                opt,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? Colors.white
                      : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildYearFilter() {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _yearOptions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (ctx, i) {
          final opt = _yearOptions[i];
          final selected = opt == _selectedYear;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedYear = opt);
              _applyFilters();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary
                    : Colors.white.withOpacity(0.65),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                opt,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? Colors.white
                      : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── 문제 행 ────────────────────────────────────────────────
class _ProblemRow extends StatelessWidget {
  final Problem problem;
  const _ProblemRow({required this.problem});

  @override
  Widget build(BuildContext context) {
    final c = getCurriculum(problem.unit);
    final cColor = curriculumColor(c);
    final cBg = curriculumBg(c);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => TreeScreen(problem: problem)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderMedium),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    _Chip(label: c, color: cColor, bg: cBg),
                    const SizedBox(width: 6),
                    _Chip(
                      label: problem.difficulty,
                      color: _diffColor(problem.difficulty),
                      bg: _diffBg(problem.difficulty),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Text(
                    problem.unit.isNotEmpty
                        ? problem.unit
                        : '${problem.no}번',
                    style: AppTextStyles.cardTitle,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${problem.year}학년도 ${problem.no}번 · 유도 ${problem.nodeDepth}단계',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textTertiary, size: 20),
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

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const _Chip({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(16)),
        child: Text(label,
            style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      );
}
