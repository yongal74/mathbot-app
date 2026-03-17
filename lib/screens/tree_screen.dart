import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../models/problem.dart';
import '../widgets/tree_node_card.dart';
import '../widgets/hint_panel.dart';
import '../widgets/concept_panel.dart';
import '../core/curriculum.dart';
import '../core/math_format.dart';
import '../services/wrong_note_service.dart';

class TreeScreen extends StatefulWidget {
  final Problem problem;
  const TreeScreen({super.key, required this.problem});

  @override
  State<TreeScreen> createState() => _TreeScreenState();
}

class _TreeScreenState extends State<TreeScreen> {
  int _hintsRevealed = 0;
  bool _showConcept = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.problem;
    final mainNodes = p.nodes.where((n) => n.type != 'answer').toList();
    final answerNode = p.nodes.where((n) => n.type == 'answer').firstOrNull;
    final curriculum = getCurriculum(p.unit);
    final cColor = curriculumColor(curriculum);

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(p),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitleCard(p, curriculum, cColor),
                    const SizedBox(height: 20),

                    // 트리 섹션 라벨
                    Row(children: [
                      Container(
                        width: 4, height: 18,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '조건분해트리',
                        style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryMedium,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${p.nodes.length}단계',
                          style: GoogleFonts.inter(
                            fontSize: 11, fontWeight: FontWeight.w600,
                            color: AppColors.primary),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),

                    // 노드 + 화살표 연결
                    ...mainNodes.asMap().entries.expand((e) => [
                      TreeNodeCard(node: e.value),
                      if (e.key < mainNodes.length - 1 || answerNode != null)
                        const _Arrow(),
                    ]),

                    if (answerNode != null) TreeNodeCard(node: answerNode),

                    // 자주 하는 실수
                    if (p.commonMistake.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _MistakeCard(text: p.commonMistake),
                    ],

                    // 힌트 패널
                    const SizedBox(height: 16),
                    HintPanel(
                      hints: p.hints,
                      revealed: _hintsRevealed,
                      onReveal: () => setState(() {
                        if (_hintsRevealed < p.hints.length) {
                          _hintsRevealed++;
                        }
                      }),
                    ),

                    // 개념 카드
                    if (p.concept != null) ...[
                      const SizedBox(height: 16),
                      ConceptPanel(
                        concept: p.concept!,
                        expanded: _showConcept,
                        onToggle: () =>
                            setState(() => _showConcept = !_showConcept),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Problem p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.chevron_left_rounded,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 2),
              Text('목록',
                  style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
            ]),
          ),
        ),
        const Spacer(),
        Text(
          '${p.year}학년도 ${p.no}번',
          style: GoogleFonts.inter(
            fontSize: 13, color: AppColors.textSecondary,
            letterSpacing: 0.3),
        ),
        const SizedBox(width: 12),
        ListenableBuilder(
          listenable: WrongNoteService(),
          builder: (ctx, _) {
            final saved = WrongNoteService().has(p.id);
            return GestureDetector(
              onTap: () {
                if (saved) {
                  WrongNoteService().remove(p.id);
                } else {
                  WrongNoteService().add(p);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: saved ? AppColors.primaryLight : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: saved ? AppColors.primary : AppColors.border),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    size: 16,
                    color: saved ? AppColors.primary : AppColors.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    saved ? '저장됨' : '오답노트',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: saved ? AppColors.primary : AppColors.textTertiary,
                    ),
                  ),
                ]),
              ),
            );
          },
        ),
      ]),
    );
  }

  Widget _buildTitleCard(Problem p, String curriculum, Color cColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(curriculum,
                  style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: Colors.white)),
            ),
            const SizedBox(width: 8),
            _DiffBadge(difficulty: p.difficulty),
          ]),
          const SizedBox(height: 10),
          Text(
            p.unit.isNotEmpty ? p.unit : '${p.no}번',
            style: GoogleFonts.inter(
              fontSize: 20, fontWeight: FontWeight.w800,
              color: AppColors.textPrimary, letterSpacing: -0.5),
          ),
          const SizedBox(height: 6),
          Row(children: [
            Container(
              width: 6, height: 6,
              decoration: const BoxDecoration(
                color: AppColors.primary, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              '조건분해트리 · ${p.nodes.length}단계',
              style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w500,
                color: AppColors.primary),
            ),
          ]),

          // ── 문제 본문 ──────────────────────────
          if (p.problemText.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Text(
              mathToKorean(p.problemText),
              style: GoogleFonts.inter(
                fontSize: 15, height: 1.7,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),

            // 보기 (선택형)
            if (p.choices.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...p.choices.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  mathToKorean(c),
                  style: GoogleFonts.inter(
                    fontSize: 14, height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              )),
            ],
          ],
        ],
      ),
    );
  }
}

// ── 화살표 ────────────────────────────────────────────────
class _Arrow extends StatelessWidget {
  const _Arrow();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 4),
    child: Center(
      child: Icon(Icons.keyboard_arrow_down_rounded,
          color: AppColors.textTertiary, size: 24),
    ),
  );
}

// ── 자주 하는 실수 카드 ────────────────────────────────────
class _MistakeCard extends StatelessWidget {
  final String text;
  const _MistakeCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('⚠️', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text('자주 하는 실수',
                style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: const Color(0xFFDC2626), letterSpacing: 0.3)),
          ]),
          const SizedBox(height: 8),
          Text(text,
              style: GoogleFonts.inter(
                fontSize: 14, height: 1.65,
                color: const Color(0xFF7F1D1D))),
        ],
      ),
    );
  }
}

// ── 난이도 배지 ────────────────────────────────────────────
class _DiffBadge extends StatelessWidget {
  final String difficulty;
  const _DiffBadge({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bg;
    switch (difficulty) {
      case '상':
        color = const Color(0xFFEF4444);
        bg = const Color(0xFFFEE2E2);
        break;
      case '중':
        color = const Color(0xFFCA8A04);
        bg = const Color(0xFFFEF9C3);
        break;
      default:
        color = const Color(0xFF16A34A);
        bg = const Color(0xFFDCFCE7);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(difficulty,
          style: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
