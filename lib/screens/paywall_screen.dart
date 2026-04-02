import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../services/purchase_service.dart';

class PaywallScreen extends StatefulWidget {
  final String? lockedFeature;
  const PaywallScreen({super.key, this.lockedFeature});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  String _selected = 'pro'; // 'free', 'pro', 'premium'
  bool _purchasing = false;
  bool _isYearly = false;

  @override
  void initState() {
    super.initState();
    // 구매/복원 성공 시 자동으로 화면 닫기
    PurchaseService().addListener(_onPurchaseChanged);
  }

  @override
  void dispose() {
    PurchaseService().removeListener(_onPurchaseChanged);
    super.dispose();
  }

  void _onPurchaseChanged() {
    final svc = PurchaseService();
    if (svc.isPro && mounted && _purchasing) {
      setState(() => _purchasing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('구독이 활성화되었습니다! 🎉')),
      );
      Navigator.pop(context);
    }
    if (svc.error != null && mounted) {
      setState(() => _purchasing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('결제 오류: ${svc.error}')),
      );
    }
  }

  Future<void> _onPurchase() async {
    if (_selected == 'free') {
      Navigator.pop(context);
      return;
    }
    final svc = PurchaseService();
    final packages = svc.packages;
    if (packages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('결제 서비스를 사용할 수 없습니다.')),
      );
      return;
    }
    // 선택된 플랜에 맞는 RevenueCat Package 찾기
    final targetId = _selected == 'premium'
        ? (_isYearly ? ProductIds.premiumYearly : ProductIds.premiumMonthly)
        : (_isYearly ? ProductIds.proYearly : ProductIds.proMonthly);
    final package = packages.where((p) => p.storeProduct.identifier == targetId).firstOrNull;
    if (package == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('상품 정보를 불러올 수 없습니다.')),
      );
      return;
    }
    setState(() => _purchasing = true);
    try {
      await svc.buy(package);
      // 실제 완료는 _onPurchaseChanged()에서 처리
    } catch (e) {
      if (mounted) {
        setState(() => _purchasing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('결제 오류: $e')),
        );
      }
    }
  }

  Future<void> _onRestore() async {
    setState(() => _purchasing = true);
    try {
      await PurchaseService().restore();
      // 복원 결과는 _onPurchaseChanged()에서 처리 (purchase stream)
      // 복원할 구매가 없는 경우 3초 후 로딩 해제
      await Future.delayed(const Duration(seconds: 4));
      if (mounted && _purchasing) {
        setState(() => _purchasing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('복원할 구매 내역이 없습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _purchasing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('복원 오류: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
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

              // 왕관 + 타이틀
              const SizedBox(height: 8),
              const Text('👑', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 10),
              Text(
                '플랜 선택',
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
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
                    '${widget.lockedFeature}은 PRO 이상 전용입니다',
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

              const SizedBox(height: 24),

              // 월간/연간 토글
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('월간', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: !_isYearly ? AppColors.textPrimary : AppColors.textTertiary)),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => setState(() => _isYearly = !_isYearly),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 52, height: 28,
                        decoration: BoxDecoration(
                          color: _isYearly ? AppColors.primary : AppColors.border,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 200),
                          alignment: _isYearly ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.all(3),
                            width: 22, height: 22,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Row(children: [
                      Text('연간', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: _isYearly ? AppColors.textPrimary : AppColors.textTertiary)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFF16A34A), borderRadius: BorderRadius.circular(20)),
                        child: Text('2개월 무료!', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 플랜 카드 3개
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selected = 'free'),
                        child: _PlanCard(
                          emoji: '🎒',
                          label: '무료',
                          price: '0원',
                          sub: '영원히 무료',
                          selected: _selected == 'free',
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selected = 'pro'),
                        child: _PlanCard(
                          emoji: '⭐',
                          label: 'PRO',
                          price: _isYearly ? '65,000원' : '9,900원',
                          sub: _isYearly ? '년 · 월 5,417원' : '월 · 사진 20회',
                          selected: _selected == 'pro',
                          color: AppColors.primary,
                          badge: '인기',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selected = 'premium'),
                        child: _PlanCard(
                          emoji: '💎',
                          label: 'PREMIUM',
                          price: _isYearly ? '99,000원' : '15,900원',
                          sub: _isYearly ? '년 · 월 8,250원' : '월 · 사진 100회',
                          selected: _selected == 'premium',
                          color: const Color(0xFFD97706),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 기능 비교표
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      // 헤더
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            const Expanded(child: SizedBox()),
                            _ColLabel('무료', const Color(0xFF6B7280)),
                            const SizedBox(width: 4),
                            _ColLabel('PRO', AppColors.primary),
                            const SizedBox(width: 4),
                            _ColLabel('PREM', const Color(0xFFD97706)),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      const SizedBox(height: 4),
                      _FeatureRow3('기출 750문제 전체', true, true, true),
                      _FeatureRow3('조건분해트리 25년치', true, true, true),
                      _FeatureRow3('개념 핵심원리 + 수능레이더', false, true, true),
                      _FeatureRow3('연습문제 중/상 난이도', false, true, true),
                      _FeatureRow3('오답노트 무제한', '5개', true, true),
                      _FeatureRow3('TTS 음성 개념 설명', false, true, true),
                      _FeatureRow3('사진 업로드 문제 분석', false, '20회/월', '100회/월'),
                      _FeatureRow3('약점 단원 분석 리포트', false, true, true),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 소셜 프루프
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '현재 2,000+ 명이 MathBot으로 수능 수학 학습 중',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textTertiary),
                ),
              ),
              const SizedBox(height: 12),

              // CTA 버튼
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _purchasing ? null : _onPurchase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selected == 'premium'
                          ? const Color(0xFFD97706)
                          : _selected == 'pro'
                              ? AppColors.primary
                              : AppColors.textSecondary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _purchasing
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(
                            _selected == 'free'
                                ? '무료로 계속하기'
                                : _selected == 'pro'
                                    ? (_isYearly ? 'PRO 시작 (65,000원/년)' : 'PRO 시작 (9,900원/월)')
                                    : (_isYearly ? 'PREMIUM 시작 (99,000원/년)' : 'PREMIUM 시작 (15,900원/월)'),
                            style: GoogleFonts.inter(
                                fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 10),
              Text(
                '언제든지 취소 가능 · 자동 갱신 · Apple/Google 구독',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textTertiary),
              ),
              const SizedBox(height: 8),
              // 구매 복원 버튼
              TextButton(
                onPressed: _purchasing ? null : _onRestore,
                child: Text(
                  '이전 구매 복원',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// 컬럼 레이블
class _ColLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _ColLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 38,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
              fontSize: 10, fontWeight: FontWeight.w700, color: color),
        ),
      );
}

// 기능 비교 행 (3열)
class _FeatureRow3 extends StatelessWidget {
  final String text;
  final dynamic free; // bool or String
  final dynamic pro;
  final dynamic premium;
  const _FeatureRow3(this.text, this.free, this.pro, this.premium);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(text,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary)),
          ),
          _Cell(free, const Color(0xFF6B7280)),
          const SizedBox(width: 4),
          _Cell(pro, AppColors.primary),
          const SizedBox(width: 4),
          _Cell(premium, const Color(0xFFD97706)),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final dynamic value;
  final Color color;
  const _Cell(this.value, this.color);

  @override
  Widget build(BuildContext context) {
    if (value == false) {
      return SizedBox(
          width: 38,
          child: Center(
              child: Icon(Icons.remove, size: 14, color: AppColors.textTertiary)));
    } else if (value == true) {
      return SizedBox(
          width: 38,
          child: Center(child: Icon(Icons.check_rounded, size: 16, color: color)));
    } else {
      return SizedBox(
        width: 38,
        child: Text(
          value.toString(),
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color),
        ),
      );
    }
  }
}

class _PlanCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String price;
  final String sub;
  final bool selected;
  final Color color;
  final String? badge;

  const _PlanCard({
    required this.emoji,
    required this.label,
    required this.price,
    required this.sub,
    required this.selected,
    required this.color,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: selected ? color.withValues(alpha:0.08) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? color : AppColors.borderMedium,
          width: selected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              if (badge != null) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(badge!,
                      style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected ? color : AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(price,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: selected ? color : AppColors.textPrimary)),
          Text(sub,
              style: GoogleFonts.inter(
                  fontSize: 10, color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}
