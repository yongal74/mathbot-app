import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

class PaywallScreen extends StatefulWidget {
  final String? lockedFeature;
  const PaywallScreen({super.key, this.lockedFeature});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _isAnnual = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header with close button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                            color: AppColors.surface, shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded,
                            size: 18, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),

              // Crown + Title
              const SizedBox(height: 8),
              const Text('👑', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              Text(
                'PRO 업그레이드',
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              if (widget.lockedFeature != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${widget.lockedFeature}은 PRO 전용입니다',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary),
                  ),
                )
              else
                Text(
                  '수능 수학 완전 정복 플랜',
                  style: GoogleFonts.inter(
                      fontSize: 15, color: AppColors.textSecondary),
                ),

              const SizedBox(height: 28),

              // Feature list
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Column(
                    children: [
                      _FeatureRow(
                          icon: '📚',
                          text: '수능 기출 750문제 전체 열람',
                          free: '전체 무료'),
                      _FeatureRow(
                          icon: '🌳',
                          text: '조건분해트리 25년치 완전 공개',
                          free: '전체 무료'),
                      _FeatureRow(
                          icon: '💡',
                          text: '개념 핵심 원리 + 수능 레이더',
                          free: false),
                      _FeatureRow(
                          icon: '✏️',
                          text: '연습문제 중/상 난이도',
                          free: '하 2문제만'),
                      _FeatureRow(
                          icon: '📌', text: '오답노트 무제한', free: '5개 제한'),
                      _FeatureRow(
                          icon: '🔊', text: 'TTS 음성 풀이', free: false),
                      _FeatureRow(
                          icon: '📊',
                          text: '약점 단원 분석 리포트',
                          free: false),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Plan toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isAnnual = false),
                        child: _PlanCard(
                          label: '월간',
                          price: '9,900원',
                          sub: '매월 갱신',
                          selected: !_isAnnual,
                          badge: null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isAnnual = true),
                        child: _PlanCard(
                          label: '연간',
                          price: '79,000원',
                          sub: '월 6,583원',
                          selected: _isAnnual,
                          badge: '33% 할인',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // CTA
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: connect to Apple IAP / Google Play
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('결제 시스템 준비 중입니다')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      _isAnnual
                          ? '연간 구독 시작 (79,000원/년)'
                          : '월간 구독 시작 (9,900원/월)',
                      style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text(
                  '무료로 계속하기',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textTertiary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '언제든지 취소 가능 · 자동 갱신',
                style:
                    GoogleFonts.inter(fontSize: 12, color: AppColors.textTertiary),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String icon;
  final String text;
  final dynamic free; // false = 완전 잠금, String = 제한 설명

  const _FeatureRow(
      {required this.icon, required this.text, required this.free});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (free == false)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'PRO',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            )
          else
            Text(
              free as String,
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.textTertiary),
            ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String label;
  final String price;
  final String sub;
  final bool selected;
  final String? badge;

  const _PlanCard({
    required this.label,
    required this.price,
    required this.sub,
    required this.selected,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryLight : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge!,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            price,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: selected ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
          Text(
            sub,
            style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}
