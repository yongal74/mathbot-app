import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../services/wrong_note_service.dart';
import '../services/game_service.dart';
import '../services/ai_analysis_service.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([WrongNoteService(), GameService(), AiAnalysisService()]),
      builder: (context, _) {
        final notes = WrongNoteService().all;
        final progress = GameService().progress;

        // ── 단원별 오답 집계 ─────────────────────────
        final unitMap = WrongNoteService().unitWeakness;
        final sortedUnits = unitMap.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final top3 = sortedUnits.take(3).toList();
        final maxCount = top3.isEmpty ? 1 : top3.first.value;

        // ── weakNodes depth 분석 ─────────────────────
        final allWeakNodes = notes.expand((n) => n.weakNodes).toList();
        final deepNodeTypes = ['derive', 'calc']; // 깊은 단계 노드 타입
        final deepCount = allWeakNodes
            .where((n) => deepNodeTypes.any((d) => n.toLowerCase().contains(d)))
            .length;
        final highDepthRatio = allWeakNodes.isEmpty
            ? 0.0
            : deepCount / allWeakNodes.length;

        // ── AI 제안 규칙 ─────────────────────────────
        final suggestions = <String>[];
        for (final entry in unitMap.entries) {
          if (entry.value >= 3) {
            suggestions.add('${entry.key} 단원에서 오답이 ${entry.value}개입니다. 집중 복습을 권장합니다.');
          }
        }
        if (highDepthRatio >= 0.5) {
          suggestions.add('유도 조건 및 계산 단계에서 자주 막힙니다. 유도 조건 훈련이 필요합니다.');
        }
        if (suggestions.isEmpty) {
          if (notes.isEmpty) {
            suggestions.add('아직 오답 데이터가 없습니다. 문제를 풀고 오답을 저장해 보세요.');
          } else {
            suggestions.add('전반적으로 고른 학습 패턴을 보이고 있습니다. 꾸준히 유지하세요!');
          }
        }

        return Scaffold(
          backgroundColor: AppColors.pageBackground,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 헤더 ──────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Text('오답 패턴 분석', style: AppTextStyles.heading1),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
                    child: Text(
                      '오답 데이터를 기반으로 약점을 파악합니다',
                      style: AppTextStyles.bodySmall,
                    ),
                  ),

                  // ── 약점 단원 Top 3 ───────────────────
                  _SectionCard(
                    title: '약점 단원 Top 3',
                    icon: Icons.bar_chart_rounded,
                    child: top3.isEmpty
                        ? _EmptyHint(message: '오답 데이터가 없습니다')
                        : Column(
                            children: top3.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final e = entry.value;
                              final ratio = e.value / maxCount;
                              final colors = [
                                AppColors.primary,
                                AppColors.teal,
                                AppColors.pink,
                              ];
                              final color = colors[idx % colors.length];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            e.key,
                                            style: AppTextStyles.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          '${e.value}개',
                                          style: AppTextStyles.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: color,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        return Stack(
                                          children: [
                                            Container(
                                              height: 8,
                                              width: constraints.maxWidth,
                                              decoration: BoxDecoration(
                                                color: color.withValues(alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                            ),
                                            Container(
                                              height: 8,
                                              width: constraints.maxWidth * ratio,
                                              decoration: BoxDecoration(
                                                color: color,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ),

                  // ── 노드별 취약점 ─────────────────────
                  _SectionCard(
                    title: '노드별 취약점',
                    icon: Icons.account_tree_rounded,
                    child: allWeakNodes.isEmpty
                        ? _EmptyHint(message: '저장된 약점 노드가 없습니다')
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _NodeTypeRow(
                                label: '전체 약점 노드',
                                count: allWeakNodes.length,
                                color: AppColors.primary,
                              ),
                              const SizedBox(height: 8),
                              _NodeTypeRow(
                                label: '유도/계산 단계 (깊은 노드)',
                                count: deepCount,
                                color: AppColors.teal,
                              ),
                              if (highDepthRatio >= 0.5) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.info_outline_rounded,
                                        color: AppColors.primary,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '유도 조건에서 주로 막힙니다',
                                          style: AppTextStyles.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primaryDark,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ),

                  // ── 학습 패턴 ─────────────────────────
                  _SectionCard(
                    title: '학습 패턴',
                    icon: Icons.trending_up_rounded,
                    child: Column(
                      children: [
                        _StatRow(
                          label: '연속 학습',
                          value: '${progress.streakDays}일',
                          icon: Icons.local_fire_department_rounded,
                          color: const Color(0xFFEF4444),
                        ),
                        const SizedBox(height: 12),
                        _StatRow(
                          label: '현재 레벨',
                          value: 'Lv.${progress.level.level} ${progress.level.title}',
                          icon: Icons.star_rounded,
                          color: const Color(0xFFD97706),
                        ),
                        const SizedBox(height: 12),
                        _StatRow(
                          label: '총 XP',
                          value: '${progress.totalXp} XP',
                          icon: Icons.bolt_rounded,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 12),
                        _StatRow(
                          label: '완료 문제',
                          value: '${progress.completedCount}문제',
                          icon: Icons.check_circle_rounded,
                          color: const Color(0xFF16A34A),
                        ),
                      ],
                    ),
                  ),

                  // ── 규칙 기반 제안 ────────────────────
                  _SectionCard(
                    title: '기본 제안',
                    icon: Icons.lightbulb_rounded,
                    iconColor: const Color(0xFFD97706),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: suggestions.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final text = entry.value;
                        return Padding(
                          padding: EdgeInsets.only(bottom: idx < suggestions.length - 1 ? 12 : 0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryMedium,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${idx + 1}',
                                    style: AppTextStyles.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  text,
                                  style: AppTextStyles.inter(
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // ── Claude AI 심층 분석 ───────────────
                  _AiAnalysisCard(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── 공통 섹션 카드 ────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    this.iconColor = AppColors.primary,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 18),
                const SizedBox(width: 8),
                Text(title, style: AppTextStyles.heading3),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

// ── 빈 상태 힌트 ──────────────────────────────────────
class _EmptyHint extends StatelessWidget {
  final String message;
  const _EmptyHint({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(message, style: AppTextStyles.bodySmall),
      ),
    );
  }
}

// ── 노드 타입 행 ──────────────────────────────────────
class _NodeTypeRow extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _NodeTypeRow({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.inter(fontSize: 13)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count개',
            style: AppTextStyles.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Claude AI 심층 분석 카드 ──────────────────────────
class _AiAnalysisCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final svc = AiAnalysisService();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    color: Color(0xFF7C3AED), size: 18),
                const SizedBox(width: 8),
                Text('Claude AI 심층 분석', style: AppTextStyles.heading3),
              ],
            ),
            const SizedBox(height: 16),
            if (svc.loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      CircularProgressIndicator(strokeWidth: 2),
                      SizedBox(height: 12),
                      Text('AI가 분석 중입니다...'),
                    ],
                  ),
                ),
              )
            else if (svc.error != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      svc.error!,
                      style: AppTextStyles.inter(
                          fontSize: 13, color: const Color(0xFFDC2626)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _AnalyzeButton(label: '다시 시도'),
                ],
              )
            else if (svc.result != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      svc.result!,
                      style: AppTextStyles.inter(fontSize: 14, height: 1.6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _AnalyzeButton(label: '다시 분석'),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Claude AI가 내 오답 패턴을 분석하고\n맞춤형 학습 전략을 제안해드립니다.',
                    style: AppTextStyles.inter(
                        fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  _AnalyzeButton(label: 'AI 분석 시작'),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _AnalyzeButton extends StatelessWidget {
  final String label;
  const _AnalyzeButton({required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => AiAnalysisService().analyze(),
        icon: const Icon(Icons.auto_awesome_rounded, size: 16),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7C3AED),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── 통계 행 ───────────────────────────────────────────
class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
