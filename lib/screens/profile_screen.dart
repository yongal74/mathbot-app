import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../models/user_progress.dart';
import '../services/game_service.dart';
import '../services/wrong_note_service.dart';
import '../services/notification_service.dart';
import '../widgets/notification_settings_dialog.dart';
import 'wrong_note_screen.dart';
import 'paywall_screen.dart';
import 'legal_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GameService(),
      builder: (context, _) {
        final progress = GameService().progress;
        final level = progress.level;
        final earnedBadges = AchievementBadge.all
            .where((b) => progress.earnedBadgeIds.contains(b.id))
            .toList();
        final lockedBadges = AchievementBadge.all
            .where((b) => !progress.earnedBadgeIds.contains(b.id))
            .toList();

        return Scaffold(
          backgroundColor: AppColors.pageBackground,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 헤더 ─────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Text('내 성장', style: AppTextStyles.heading1),
                  ),

                  const SizedBox(height: 20),

                  // ── XP 카드 ───────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
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
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'LEVEL ${level.level}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                level.title,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${progress.totalXp} XP',
                            style: GoogleFonts.inter(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress.levelProgress,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.25),
                              valueColor:
                                  const AlwaysStoppedAnimation(Colors.white),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '다음 레벨까지',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                              Text(
                                '${(progress.levelProgress * 100).round()}%',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── 스탯 카드 ─────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _StatCard(
                          emoji: '🔥',
                          label: '스트릭',
                          value: '${progress.streakDays}일',
                          color: const Color(0xFFEF4444),
                          bg: const Color(0xFFFEE2E2),
                        ),
                        const SizedBox(width: 10),
                        _StatCard(
                          emoji: '✅',
                          label: '완료 문제',
                          value: '${progress.completedCount}',
                          color: const Color(0xFF16A34A),
                          bg: const Color(0xFFDCFCE7),
                        ),
                        const SizedBox(width: 10),
                        _StatCard(
                          emoji: '🏅',
                          label: '배지',
                          value:
                              '${earnedBadges.length}/${AchievementBadge.all.length}',
                          color: const Color(0xFFD97706),
                          bg: const Color(0xFFFEF3C7),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── 오답노트 ──────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: ListenableBuilder(
                      listenable: WrongNoteService(),
                      builder: (context, _) {
                        final count = WrongNoteService().all.length;
                        return GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WrongNoteScreen())),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Icon(Icons.bookmark_rounded, color: AppColors.primary, size: 22),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('오답노트', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                    Text(count == 0 ? '저장된 문제가 없어요' : '$count문제 저장됨', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 20),
                            ]),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── 알림 설정 ─────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: ListenableBuilder(
                      listenable: NotificationService(),
                      builder: (context, _) {
                        final svc = NotificationService();
                        return GestureDetector(
                          onTap: () => showNotificationSettings(context),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: svc.enabled
                                      ? AppColors.primaryLight
                                      : AppColors.surfaceHover,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.notifications_active_rounded,
                                  color: svc.enabled
                                      ? AppColors.primary
                                      : AppColors.textTertiary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('학습 리마인더',
                                        style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary)),
                                    Text(
                                      svc.enabled
                                          ? '매일 ${svc.timeLabel} 알림 설정됨'
                                          : '탭하여 알림 설정',
                                      style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded,
                                  color: AppColors.textTertiary, size: 20),
                            ]),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── PRO 업그레이드 ────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const PaywallScreen())),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFFD97706)],
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(children: [
                          const Text('👑', style: TextStyle(fontSize: 28)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('PRO / PREMIUM',
                                    style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white)),
                                Text('사진 분석 · TTS · 무제한 오답노트',
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.85))),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('보기',
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ),
                        ]),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── 레벨 로드맵 ───────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                    child: Text('레벨 로드맵', style: AppTextStyles.heading3),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: UserLevel.levels
                          .map((l) => _LevelRow(
                                levelInfo: l,
                                current: level,
                                totalXp: progress.totalXp,
                              ))
                          .toList(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── 획득 배지 ─────────────────────────
                  if (earnedBadges.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                      child: Text('획득한 배지', style: AppTextStyles.heading3),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _BadgeGrid(badges: earnedBadges, locked: false),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── 도전 배지 ─────────────────────────
                  if (lockedBadges.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                      child: Text('도전 배지', style: AppTextStyles.heading3),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _BadgeGrid(badges: lockedBadges, locked: true),
                    ),
                  ],

                  // ── 약관 / 법률 ──────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Column(
                      children: [
                        _LegalTile(
                          label: '개인정보처리방침',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LegalScreen(
                                  type: LegalType.privacy),
                            ),
                          ),
                        ),
                        _LegalTile(
                          label: '이용약관',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LegalScreen(
                                  type: LegalType.terms),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

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

class _LegalTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _LegalTile({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          children: [
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary)),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color color;
  final Color bg;

  const _StatCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                color: color.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelRow extends StatelessWidget {
  final UserLevel levelInfo;
  final UserLevel current;
  final int totalXp;

  const _LevelRow(
      {required this.levelInfo,
      required this.current,
      required this.totalXp});

  @override
  Widget build(BuildContext context) {
    final isUnlocked = levelInfo.level <= current.level;
    final isCurrent = levelInfo.level == current.level;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCurrent ? AppColors.primaryLight : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent
              ? AppColors.primary
              : isUnlocked
                  ? AppColors.borderMedium
                  : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isUnlocked ? AppColors.primaryMedium : AppColors.border,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                isUnlocked ? '✓' : '${levelInfo.level}',
                style: GoogleFonts.inter(
                  color: isUnlocked ? AppColors.primary : AppColors.textTertiary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Lv.${levelInfo.level} ${levelInfo.title}',
                      style: GoogleFonts.inter(
                        color: isUnlocked
                            ? AppColors.textPrimary
                            : AppColors.textTertiary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '현재',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '🔓 ${levelInfo.unlocks}',
                  style: GoogleFonts.inter(
                    color: isUnlocked
                        ? AppColors.primary
                        : AppColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${levelInfo.xpRequired} XP',
            style: GoogleFonts.inter(
              color: isUnlocked
                  ? AppColors.textSecondary
                  : AppColors.textTertiary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeGrid extends StatelessWidget {
  final List<AchievementBadge> badges;
  final bool locked;

  const _BadgeGrid({required this.badges, required this.locked});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: badges.map((b) => _BadgeTile(badge: b, locked: locked)).toList(),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final AchievementBadge badge;
  final bool locked;

  const _BadgeTile({required this.badge, required this.locked});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            '${badge.emoji} ${badge.name}',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            badge.description,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                '확인',
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: locked ? AppColors.surface : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: locked ? AppColors.border : AppColors.primaryMedium,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              locked ? '🔒' : badge.emoji,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(height: 4),
            Text(
              locked ? '?' : badge.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: GoogleFonts.inter(
                color:
                    locked ? AppColors.textTertiary : AppColors.textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
