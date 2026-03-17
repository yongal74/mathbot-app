import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ────────────────────────────────────────────────
// Option C — Minimal Vibrant 디자인 시스템
// ────────────────────────────────────────────────

class AppColors {
  AppColors._();

  // 브랜드
  static const Color primary       = Color(0xFF8B5CF6); // 퍼플
  static const Color primaryLight  = Color(0xFFF3F0FF);
  static const Color primaryMedium = Color(0xFFEDE9FE);
  static const Color primaryDark   = Color(0xFF7C3AED);

  static const Color teal          = Color(0xFF14B8A6);
  static const Color tealLight     = Color(0xFFF0FDFA);
  static const Color tealMedium    = Color(0xFFCCFBF1);

  static const Color pink          = Color(0xFFF472B6);

  // 배경 / 서피스
  static const Color background    = Color(0xFFEDEDED); // 약간 짙은 회색 배경
  static const Color surface       = Color(0xFFFFFFFF); // 카드는 흰색으로 구분
  static const Color surfaceHover  = Color(0xFFF3F4F6);

  // 텍스트
  static const Color textPrimary   = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary  = Color(0xFF9CA3AF);

  // 구분선
  static const Color border        = Color(0xFFF0F0F0);
  static const Color borderMedium  = Color(0xFFE5E7EB);

  // 난이도
  static const Color diffHard      = Color(0xFFEF4444);
  static const Color diffHardBg    = Color(0xFFFEE2E2);
  static const Color diffMid       = Color(0xFFCA8A04);
  static const Color diffMidBg     = Color(0xFFFEF9C3);
  static const Color diffEasy      = Color(0xFF16A34A);
  static const Color diffEasyBg    = Color(0xFFDCFCE7);

  // 트리 노드
  static const Color nodeGivenBg      = Color(0xFFEFF6FF);
  static const Color nodeGivenBorder  = Color(0xFFBFDBFE);
  static const Color nodeGivenText    = Color(0xFF3B82F6);
  static const Color nodeGivenBody    = Color(0xFF1E3A5F);

  static const Color nodeFormulaBg     = Color(0xFFF5F3FF);
  static const Color nodeFormulaBorder = Color(0xFFDDD6FE);
  static const Color nodeFormulaText   = Color(0xFF8B5CF6);
  static const Color nodeFormulaBody   = Color(0xFF3B0764);

  static const Color nodeDeriveBg      = Color(0xFFFFF7ED);
  static const Color nodeDeriveBorder  = Color(0xFFFB923C);
  static const Color nodeDeriveText    = Color(0xFFEA580C);
  static const Color nodeDeriveBody    = Color(0xFF7C2D12);

  static const Color nodeCalcBg        = Color(0xFFF0FDF4);
  static const Color nodeCalcBorder    = Color(0xFFBBF7D0);
  static const Color nodeCalcText      = Color(0xFF16A34A);
  static const Color nodeCalcBody      = Color(0xFF14532D);

  static const Color nodeAnswerBg      = Color(0xFF8B5CF6);
  static const Color nodeAnswerText    = Color(0xFFDDD6FE);
  static const Color nodeAnswerBody    = Color(0xFFFFFFFF);
}

class AppTextStyles {
  AppTextStyles._();

  // 기본 Inter 텍스트 스타일 팩토리
  static TextStyle inter({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = AppColors.textPrimary,
    double? letterSpacing,
    double? height,
  }) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );

  // ── 자주 쓰는 스타일 ──────────────────────────

  // 앱 타이틀 / 큰 헤딩
  static TextStyle get heading1 => GoogleFonts.inter(
        fontSize: 28, fontWeight: FontWeight.w800,
        color: AppColors.textPrimary, letterSpacing: -0.8);

  static TextStyle get heading2 => GoogleFonts.inter(
        fontSize: 22, fontWeight: FontWeight.w800,
        color: AppColors.textPrimary, letterSpacing: -0.5);

  static TextStyle get heading3 => GoogleFonts.inter(
        fontSize: 18, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary, letterSpacing: -0.3);

  // 카드 제목
  static TextStyle get cardTitle => GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary, letterSpacing: -0.3);

  // 본문
  static TextStyle get body => GoogleFonts.inter(
        fontSize: 15, fontWeight: FontWeight.w400,
        color: AppColors.textPrimary, height: 1.6);

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w400,
        color: AppColors.textSecondary, height: 1.5);

  // 레이블 (배지, 태그)
  static TextStyle get label => GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w600,
        color: AppColors.textSecondary);

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w500,
        color: AppColors.textTertiary, letterSpacing: 0.5);

  // 메타 (연도, 번호 등)
  static TextStyle get meta => GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w400,
        color: AppColors.textSecondary, letterSpacing: 0.3);
}

// ── Material ThemeData ────────────────────────────────
ThemeData buildAppTheme() {
  final textTheme = GoogleFonts.interTextTheme();

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: GoogleFonts.inter().fontFamily,
    textTheme: textTheme,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      background: AppColors.background,
      surface: AppColors.surface,
      primary: AppColors.primary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 17, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.background,
      indicatorColor: AppColors.primaryMedium,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.primary, size: 22);
        }
        return const IconThemeData(color: AppColors.textTertiary, size: 22);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary);
        }
        return GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textTertiary);
      }),
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.border, thickness: 1, space: 0),
  );
}
