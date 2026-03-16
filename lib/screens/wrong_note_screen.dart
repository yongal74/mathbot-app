import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../core/curriculum.dart';
import '../services/wrong_note_service.dart';
import '../services/problem_service.dart';
import '../models/wrong_note.dart';
import 'tree_screen.dart';

class WrongNoteScreen extends StatelessWidget {
  const WrongNoteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: WrongNoteService(),
      builder: (context, _) {
        final notes = WrongNoteService().all;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.chevron_left_rounded, color: AppColors.primary, size: 18),
                              const SizedBox(width: 2),
                              Text('나', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                            ]),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 14),
                      Text('오답노트', style: AppTextStyles.heading1),
                      const SizedBox(height: 4),
                      Text(
                        notes.isEmpty ? '저장된 문제가 없어요' : '${notes.length}문제 저장됨',
                        style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: notes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('📝', style: TextStyle(fontSize: 52)),
                              const SizedBox(height: 16),
                              Text('오답노트가 비어있어요', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                              const SizedBox(height: 8),
                              Text('문제 풀다가 북마크 버튼으로 추가하세요', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                          itemCount: notes.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (ctx, i) => _WrongNoteTile(note: notes[i]),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WrongNoteTile extends StatelessWidget {
  final WrongNote note;
  const _WrongNoteTile({required this.note});

  Color get _diffColor {
    switch (note.difficulty) {
      case '상': return const Color(0xFFEF4444);
      case '중': return const Color(0xFFCA8A04);
      default:   return const Color(0xFF16A34A);
    }
  }

  Color get _diffBg {
    switch (note.difficulty) {
      case '상': return const Color(0xFFFEE2E2);
      case '중': return const Color(0xFFFEF9C3);
      default:   return const Color(0xFFDCFCE7);
    }
  }

  static const _nodeLabels = {
    'given':     '조건',
    'formula':   '공식',
    'derive':    '유도',
    'calculate': '계산',
    'answer':    '정답',
  };

  @override
  Widget build(BuildContext context) {
    final c = getCurriculum(note.unit);
    final cColor = curriculumColor(c);
    final cBg = curriculumBg(c);

    return Dismissible(
      key: Key(note.problemId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Color(0xFFEF4444)),
      ),
      onDismissed: (_) => WrongNoteService().remove(note.problemId),
      child: GestureDetector(
        onTap: () async {
          final problems = await ProblemService().loadYear(note.year);
          final problem = problems.where((p) => p.id == note.problemId).firstOrNull;
          if (problem != null && context.mounted) {
            WrongNoteService().markReviewed(note.problemId);
            Navigator.push(context, MaterialPageRoute(builder: (_) => TreeScreen(problem: problem)));
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderMedium),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                // 교과 배지
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: cBg, borderRadius: BorderRadius.circular(20)),
                  child: Text(c, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: cColor)),
                ),
                const SizedBox(width: 6),
                // 난이도 배지
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: _diffBg, borderRadius: BorderRadius.circular(20)),
                  child: Text(note.difficulty, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: _diffColor)),
                ),
                const Spacer(),
                if (note.reviewCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(20)),
                    child: Text('복습 ${note.reviewCount}회', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ),
              ]),
              const SizedBox(height: 10),
              Text(
                '${note.year}학년도 ${note.no}번',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              Text(
                note.unit,
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
              ),
              // 약한 노드 표시
              if (note.weakNodes.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  children: note.weakNodes.map((n) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '❓ ${_nodeLabels[n] ?? n}',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFEF4444)),
                    ),
                  )).toList(),
                ),
              ],
              if (note.memo.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('✏️ ${note.memo}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 8),
              Text(
                '${note.savedAt.month}월 ${note.savedAt.day}일 저장',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
