import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';
import '../main.dart';
import '../services/auth_service.dart';

class _OnboardingPage {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  const _OnboardingPage(
      {required this.emoji,
      required this.title,
      required this.subtitle,
      required this.color});
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  bool _appleAvailable = false;

  static const _pages = [
    _OnboardingPage(
      emoji: '🌳',
      title: '조건분해트리로\n수학을 정복하세요',
      subtitle: '문제의 조건 → 공식 → 계산 → 정답\n단계별로 쪼개면 어떤 문제도 풀립니다',
      color: AppColors.primary,
    ),
    _OnboardingPage(
      emoji: '📚',
      title: '수능 25년치\n750문제 완전 분석',
      subtitle: '2000~2024년 모든 수능 수학 문제\n조건분해트리로 한눈에 이해',
      color: Color(0xFF0EA5E9),
    ),
    _OnboardingPage(
      emoji: '💡',
      title: '150개 핵심 개념을\n직관적으로 이해',
      subtitle: '스토리로 이해 → 핵심 원리 → 수능 레이더\n개념부터 완벽하게 잡아드립니다',
      color: Color(0xFF10B981),
    ),
    _OnboardingPage(
      emoji: '📌',
      title: '오답노트로\n약점을 완전 극복',
      subtitle: '틀린 문제를 저장하고 반복 복습\n홈 화면에서 매일 추천해드립니다',
      color: Color(0xFFEF4444),
    ),
  ];

  // 마지막 페이지는 로그인 페이지 (인덱스 _pages.length)
  int get _totalPages => _pages.length + 1;
  bool get _isLoginPage => _page == _pages.length;

  @override
  void initState() {
    super.initState();
    AuthService.isAppleSignInAvailable.then((v) {
      if (mounted) setState(() => _appleAvailable = v);
    });
  }

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainTabScreen()),
      );
    }
  }

  void _next() {
    if (_page < _totalPages - 1) {
      _controller.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    }
  }

  Future<void> _googleLogin() async {
    try {
      final user = await AuthService().signInWithGoogle();
      if (user != null) await _complete();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google 로그인 실패: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _appleLogin() async {
    try {
      final user = await AuthService().signInWithApple();
      if (user != null) await _complete();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Apple 로그인 실패: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _guestLogin() async {
    await AuthService().continueAsGuest();
    await _complete();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _pages.length - 1; // 마지막 소개 페이지
    final accentColor = _isLoginPage
        ? AppColors.primary
        : _pages[_page < _pages.length ? _page : _pages.length - 1].color;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Stack(
        children: [
          // Page content
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: _totalPages,
            itemBuilder: (ctx, i) {
              if (i < _pages.length) return _buildPage(_pages[i]);
              return _buildLoginPage();
            },
          ),

          // Skip button (소개 페이지에서만)
          if (!_isLoginPage)
            Positioned(
              top: 52,
              right: 24,
              child: GestureDetector(
                onTap: () {
                  _controller.animateToPage(
                    _pages.length,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                },
                child: Text(
                  '건너뛰기',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          // Bottom controls (로그인 페이지가 아닐 때만)
          if (!_isLoginPage)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 48),
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dots (전체 페이지 수)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _totalPages,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _page ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _page ? accentColor : AppColors.border,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          isLast ? '로그인 / 시작하기 →' : '다음',
                          style: GoogleFonts.inter(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return Column(
      children: [
        Expanded(
          flex: 5,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [page.color, page.color.withValues(alpha: 0.85)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Text(page.emoji, style: const TextStyle(fontSize: 88)),
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      page.title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.25,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      page.subtitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.85),
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Expanded(flex: 2, child: SizedBox()),
      ],
    );
  }

  Widget _buildLoginPage() {
    final auth = AuthService();
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 48, 28, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo / 브랜드
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: Text('🌳', style: TextStyle(fontSize: 40)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '시작하기',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '로그인하면 여러 기기에서\n학습 기록을 동기화할 수 있어요',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // Google 로그인
              _SocialButton(
                icon: _GoogleIcon(),
                label: 'Google로 계속하기',
                onTap: auth.loading ? null : _googleLogin,
                backgroundColor: Colors.white,
                textColor: const Color(0xFF1F1F1F),
                borderColor: const Color(0xFFDDDDDD),
              ),
              const SizedBox(height: 12),

              // Apple 로그인 (iOS/macOS만)
              if (_appleAvailable) ...[
                _SocialButton(
                  icon: const Icon(Icons.apple, color: Colors.white, size: 22),
                  label: 'Apple로 계속하기',
                  onTap: auth.loading ? null : _appleLogin,
                  backgroundColor: const Color(0xFF000000),
                  textColor: Colors.white,
                ),
                const SizedBox(height: 12),
              ],

              // 카카오 (준비 중)
              _SocialButton(
                icon: const Text('💬', style: TextStyle(fontSize: 20)),
                label: '카카오로 계속하기',
                badge: '준비 중',
                onTap: null,
                backgroundColor: const Color(0xFFFEE500),
                textColor: const Color(0xFF3A1D1D),
              ),
              const SizedBox(height: 32),

              // 구분선
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '또는',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),

              // 게스트 시작
              GestureDetector(
                onTap: auth.loading ? null : _guestLogin,
                child: Text(
                  '로그인 없이 게스트로 시작',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '학습 기록이 이 기기에만 저장됩니다',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),

              if (auth.loading) ...[
                const SizedBox(height: 24),
                const CircularProgressIndicator(),
              ],

              const SizedBox(height: 24),

              // 약관 안내
              Text(
                '계속하면 이용약관 및 개인정보처리방침에 동의하는 것으로 간주합니다',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 소셜 로그인 버튼 ─────────────────────────────────
class _SocialButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final String? badge;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.backgroundColor,
    required this.textColor,
    this.badge,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null && badge == null ? 0.5 : 1.0,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: borderColor != null ? Border.all(color: borderColor!) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              if (badge != null)
                Positioned(
                  right: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge!,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Google 로고 아이콘 ────────────────────────────────
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Simplified Google G
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -0.3,
      4.0,
      false,
      paint..style = PaintingStyle.stroke ..strokeWidth = size.width * 0.22 ..color = const Color(0xFF4285F4),
    );
    // Right bar
    paint
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.5, size.height * 0.38, size.width * 0.46, size.height * 0.24),
      paint,
    );
    // Color arcs
    const colors = [
      Color(0xFF34A853), // green bottom
      Color(0xFFFBBC05), // yellow
      Color(0xFFEA4335), // red
    ];
    final sweeps = [1.1, 1.1, 0.9];
    final starts = [0.3, 1.4, 2.5];
    for (int i = 0; i < 3; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        starts[i],
        sweeps[i],
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.22
          ..color = colors[i],
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
