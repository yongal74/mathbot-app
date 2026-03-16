import 'package:flutter_test/flutter_test.dart';
import 'package:mathbot_app/models/user_progress.dart';

void main() {
  group('XP 계산 테스트', () {
    test('힌트 0개 + 기본 난이도 = 300 XP', () {
      final gain = XpGain.calculate(hintsUsed: 0, difficulty: '중', streakDays: 0);
      expect(gain.amount, 300);
    });

    test('힌트 0개 + 킬러(상) = 600 XP (×2)', () {
      final gain = XpGain.calculate(hintsUsed: 0, difficulty: '상', streakDays: 0);
      expect(gain.amount, 600);
    });

    test('힌트 3개 = 50 XP', () {
      final gain = XpGain.calculate(hintsUsed: 3, difficulty: '중', streakDays: 0);
      expect(gain.amount, 50);
    });

    test('7일 스트릭 = ×1.5 배율', () {
      final gain = XpGain.calculate(hintsUsed: 0, difficulty: '중', streakDays: 7);
      expect(gain.amount, 450); // 300 × 1.5
    });

    test('개념-先 모드 = 20 XP', () {
      final gain = XpGain.calculate(hintsUsed: 0, difficulty: '중', streakDays: 0, conceptMode: true);
      expect(gain.amount, 20);
    });
  });

  group('레벨 시스템 테스트', () {
    test('0 XP = Lv.1 입문자', () {
      final level = UserLevel.fromXp(0);
      expect(level.level, 1);
      expect(level.title, '입문자');
    });

    test('2000 XP = Lv.2 관찰자', () {
      final level = UserLevel.fromXp(2000);
      expect(level.level, 2);
    });

    test('5000 XP = Lv.3 수련생 (문제-先 모드 해제)', () {
      final level = UserLevel.fromXp(5000);
      expect(level.level, 3);
      expect(level.unlocks, '문제-先 모드');
    });

    test('40000 XP = Lv.6 만점자', () {
      final level = UserLevel.fromXp(40000);
      expect(level.level, 6);
    });

    test('레벨 진행률 계산', () {
      // 2000~5000 구간에서 3500 XP = 50%
      final progress = UserLevel.progressToNext(3500);
      expect(progress, closeTo(0.5, 0.01));
    });
  });
}
