import 'package:flutter_test/flutter_test.dart';
import 'package:mathbot_app/models/user_progress.dart';

void main() {
  group('XP 계산 (TDD)', () {
    test('힌트 0개 + 중간 난이도 = 300 XP', () {
      final gain = XpGain.calculate(hintsUsed: 0, difficulty: '중', streakDays: 0);
      expect(gain.amount, 300);
    });

    test('힌트 0개 + 킬러(상) = 600 XP (×2 배율)', () {
      final gain = XpGain.calculate(hintsUsed: 0, difficulty: '상', streakDays: 0);
      expect(gain.amount, 600);
    });

    test('힌트 1개 = 200 XP', () {
      final gain = XpGain.calculate(hintsUsed: 1, difficulty: '중', streakDays: 0);
      expect(gain.amount, 200);
    });

    test('힌트 2개 = 100 XP', () {
      final gain = XpGain.calculate(hintsUsed: 2, difficulty: '중', streakDays: 0);
      expect(gain.amount, 100);
    });

    test('힌트 3개 이상 = 50 XP', () {
      final gain = XpGain.calculate(hintsUsed: 3, difficulty: '중', streakDays: 0);
      expect(gain.amount, 50);
    });

    test('7일 스트릭 = ×1.5 배율', () {
      final gain = XpGain.calculate(hintsUsed: 0, difficulty: '중', streakDays: 7);
      expect(gain.amount, 450); // 300 × 1.5
    });

    test('킬러 + 스트릭 = 300 × 2 × 1.5 = 900 XP', () {
      final gain = XpGain.calculate(hintsUsed: 0, difficulty: '상', streakDays: 7);
      expect(gain.amount, 900);
    });

    test('개념-先 모드 = 20 XP (난이도/스트릭 무관)', () {
      final gain = XpGain.calculate(
          hintsUsed: 0, difficulty: '상', streakDays: 30, conceptMode: true);
      expect(gain.amount, 20);
    });
  });

  group('레벨 시스템 (TDD)', () {
    test('0 XP = Lv.1 입문자', () {
      final level = UserLevel.fromXp(0);
      expect(level.level, 1);
      expect(level.title, '입문자');
    });

    test('1999 XP = 아직 Lv.1', () {
      expect(UserLevel.fromXp(1999).level, 1);
    });

    test('2000 XP = Lv.2 관찰자', () {
      final level = UserLevel.fromXp(2000);
      expect(level.level, 2);
      expect(level.title, '관찰자');
    });

    test('5000 XP = Lv.3 수련생 (문제-先 모드 해제)', () {
      final level = UserLevel.fromXp(5000);
      expect(level.level, 3);
      expect(level.unlocks, '문제-先 모드');
    });

    test('40000 XP = Lv.6 만점자 (최고 레벨)', () {
      final level = UserLevel.fromXp(40000);
      expect(level.level, 6);
      expect(level.title, '만점자');
    });

    test('레벨 진행률: 3500 XP = Lv2~3 구간 50%', () {
      // Lv2: 2000, Lv3: 5000 → 구간 3000, 1500 진행 = 50%
      final progress = UserLevel.progressToNext(3500);
      expect(progress, closeTo(0.5, 0.01));
    });

    test('최고 레벨 이상 = 진행률 1.0', () {
      final progress = UserLevel.progressToNext(99999);
      expect(progress, 1.0);
    });
  });

  group('UserProgress 상태 (TDD)', () {
    test('초기 상태 XP=0, 스트릭=0', () {
      const p = UserProgress();
      expect(p.totalXp, 0);
      expect(p.streakDays, 0);
      expect(p.completedCount, 0);
    });

    test('JSON 직렬화/역직렬화 동일성', () {
      const p = UserProgress(totalXp: 1500, streakDays: 5);
      final restored = UserProgress.fromJson(p.toJson());
      expect(restored.totalXp, 1500);
      expect(restored.streakDays, 5);
    });
  });
}
