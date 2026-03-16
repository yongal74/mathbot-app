import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../models/user_progress.dart';

/// 문제 완료 시 XP 획득 애니메이션 오버레이
class XpBadgeOverlay extends StatefulWidget {
  final XpGain xpGain;
  final bool leveledUp;
  final UserLevel? newLevel;
  final List<AchievementBadge> newBadges;
  final VoidCallback onDone;

  const XpBadgeOverlay({
    super.key,
    required this.xpGain,
    required this.leveledUp,
    this.newLevel,
    required this.newBadges,
    required this.onDone,
  });

  @override
  State<XpBadgeOverlay> createState() => _XpBadgeOverlayState();
}

class _XpBadgeOverlayState extends State<XpBadgeOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    Future.delayed(const Duration(seconds: 2), widget.onDone);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.primaryMedium, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // XP 획득
                  Text(
                    '+${widget.xpGain.amount} XP',
                    style: GoogleFonts.inter(
                      color: AppColors.primary,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.xpGain.reason,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),

                  // 레벨업
                  if (widget.leveledUp && widget.newLevel != null) ...[
                    const SizedBox(height: 20),
                    Divider(color: AppColors.borderMedium),
                    const SizedBox(height: 16),
                    Text(
                      '🎉 레벨 업!',
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lv.${widget.newLevel!.level} ${widget.newLevel!.title}',
                      style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '🔓 ${widget.newLevel!.unlocks} 해제!',
                      style: GoogleFonts.inter(
                        color: AppColors.teal,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],

                  // 새 배지
                  if (widget.newBadges.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Divider(color: AppColors.borderMedium),
                    const SizedBox(height: 12),
                    Text(
                      '새 배지 획득!',
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      children: widget.newBadges
                          .map((b) => Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(b.emoji,
                                      style: const TextStyle(fontSize: 32)),
                                  const SizedBox(height: 4),
                                  Text(
                                    b.name,
                                    style: GoogleFonts.inter(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 홈/프로필에서 보여주는 XP 바
class XpProgressBar extends StatelessWidget {
  final int totalXp;

  const XpProgressBar({super.key, required this.totalXp});

  @override
  Widget build(BuildContext context) {
    final level = UserLevel.fromXp(totalXp);
    final next = UserLevel.nextLevel(totalXp);
    final progress = UserLevel.progressToNext(totalXp);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lv.${level.level} ${level.title}',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '$totalXp XP',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              if (next != null)
                Text(
                  '→ Lv.${next.level}',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          if (next != null) ...[
            const SizedBox(height: 6),
            Text(
              '다음 레벨까지 ${next.xpRequired - totalXp} XP',
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
