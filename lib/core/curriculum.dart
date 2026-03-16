import 'package:flutter/material.dart';
import 'theme.dart';

const List<String> kCurriculumOrder = [
  '공통수학1', '공통수학2', '대수', '미적분', '확통', '기하',
];

String getCurriculum(String unit) {
  if (unit.contains('미분') || unit.contains('적분') ||
      unit.contains('극한') || unit.contains('접선') ||
      unit.contains('넓이')) return '미적분';
  if (unit.contains('수열') || unit.contains('지수') ||
      unit.contains('로그')) return '대수';
  if (unit.contains('확률') || unit.contains('통계') ||
      unit.contains('조합') || unit.contains('경우')) return '확통';
  if (unit.contains('벡터') || unit.contains('기하') ||
      unit.contains('이차곡선') || unit.contains('공간')) return '기하';
  if (unit.contains('집합') || unit.contains('명제') ||
      unit.contains('도형')) return '공통수학2';
  if (unit.contains('다항') || unit.contains('방정식') ||
      unit.contains('부등식')) return '공통수학1';
  return '미적분';
}

Color curriculumColor(String c) {
  switch (c) {
    case '미적분':    return const Color(0xFFEC4899);
    case '대수':      return AppColors.primary;
    case '확통':      return AppColors.teal;
    case '기하':      return const Color(0xFFF59E0B);
    case '공통수학1':
    case '공통수학2': return const Color(0xFF6366F1);
    default:          return AppColors.primary;
  }
}

Color curriculumBg(String c) {
  switch (c) {
    case '미적분':    return const Color(0xFFFCE7F3);
    case '대수':      return AppColors.primaryMedium;
    case '확통':      return AppColors.tealMedium;
    case '기하':      return const Color(0xFFFEF3C7);
    case '공통수학1':
    case '공통수학2': return const Color(0xFFE0E7FF);
    default:          return AppColors.primaryMedium;
  }
}
