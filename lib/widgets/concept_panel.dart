import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/problem.dart';
import '../core/theme.dart';
import '../core/math_format.dart';
import '../services/tts_service.dart';

/// 개념 카드 — 수학자 수준의 깊이 있는 개념 설명
///
/// 구조:
///   1. 직관적 이해 (비유/analogy) — 처음 보는 사람도 "아, 그거구나!" 하는 순간
///   2. 수학적 본질 (explain)     — 정의·원리를 명확하게
///   3. 왜 작동하는가 (why)       — 공식 뒤의 논리적 필연성
///   4. 수능 레이더 (csatTip)     — 출제자가 노리는 함정과 핵심 패턴
class ConceptPanel extends StatelessWidget {
  final Concept concept;
  final bool expanded;
  final VoidCallback onToggle;

  const ConceptPanel({
    super.key,
    required this.concept,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryMedium, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 헤더 (항상 노출) ─────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
            child: Row(
              children: [
                // 🧠 아이콘 + 제목 — 탭하면 펼침
                GestureDetector(
                  onTap: onToggle,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primaryMedium,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text('🧠', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('핵심 개념',
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                  letterSpacing: 0.5)),
                          const SizedBox(height: 2),
                          Text(concept.title,
                              style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary)),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // TTS 버튼 + 속도 조절
                ListenableBuilder(
                  listenable: TtsService(),
                  builder: (ctx, _) {
                    final tts = TtsService();
                    final ttsText = concept.ttsScript.isNotEmpty
                        ? concept.ttsScript
                        : '${concept.title}. ${concept.analogy}';
                    final isReading = tts.isReadingText(ttsText);

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 속도 버튼 (재생 중일 때만 표시)
                        if (isReading) ...[
                          GestureDetector(
                            onTap: () {
                              final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
                              final cur = tts.speed;
                              final idx = speeds.indexWhere((s) => s >= cur);
                              final next = speeds[(idx + 1) % speeds.length];
                              tts.setSpeed(next);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primaryMedium,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                tts.speedLabel,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        // 재생/정지 버튼
                        GestureDetector(
                          onTap: () {
                            if (isReading) {
                              tts.stop();
                            } else {
                              tts.speak(ttsText);
                            }
                          },
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: isReading
                                  ? AppColors.primary
                                  : AppColors.primaryMedium,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isReading
                                  ? Icons.pause_rounded
                                  : Icons.volume_up_rounded,
                              color: isReading
                                  ? Colors.white
                                  : AppColors.primary,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(width: 8),

                // 펼침 chevron
                GestureDetector(
                  onTap: onToggle,
                  child: AnimatedRotation(
                    turns: expanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.primary, size: 22),
                  ),
                ),
              ],
            ),
          ),

          // ── 상세 내용 (펼침) ─────────────────────
          if (expanded) ...[
            Divider(height: 1, color: AppColors.primaryMedium),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // 1. 직관적 이해
                  if (concept.analogy.isNotEmpty) ...[
                    _ConceptBlock(
                      icon: '💡',
                      label: '직관적 이해',
                      labelColor: const Color(0xFF2563EB),
                      bgColor: const Color(0xFFEFF6FF),
                      borderColor: const Color(0xFFBFDBFE),
                      child: Text(
                        mathToKorean(concept.analogy),
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          height: 1.75,
                          color: const Color(0xFF1E3A5F),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // 2. 수학적 본질
                  if (concept.explain.isNotEmpty) ...[
                    _ConceptBlock(
                      icon: '📐',
                      label: '수학적 본질',
                      labelColor: AppColors.primary,
                      bgColor: AppColors.primaryLight,
                      borderColor: AppColors.primaryMedium,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: concept.explain.asMap().entries.map((e) {
                          final isLast =
                              e.key == concept.explain.length - 1;
                          return Padding(
                            padding:
                                EdgeInsets.only(bottom: isLast ? 0 : 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(
                                      top: 6, right: 10),
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    mathToKorean(e.value),
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      height: 1.7,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // 3. 수능 레이더
                  if (concept.csatTip.isNotEmpty)
                    _ConceptBlock(
                      icon: '🎯',
                      label: '수능 레이더',
                      labelColor: const Color(0xFFEA580C),
                      bgColor: const Color(0xFFFFF7ED),
                      borderColor: const Color(0xFFFED7AA),
                      child: Text(
                        mathToKorean(concept.csatTip),
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          height: 1.75,
                          color: const Color(0xFF7C2D12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 개념 카드 내부의 섹션 블록
class _ConceptBlock extends StatelessWidget {
  final String icon;
  final String label;
  final Color labelColor;
  final Color bgColor;
  final Color borderColor;
  final Widget child;

  const _ConceptBlock({
    required this.icon,
    required this.label,
    required this.labelColor,
    required this.bgColor,
    required this.borderColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: labelColor,
                    letterSpacing: 0.3)),
          ]),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
