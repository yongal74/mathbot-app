import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mathbot_app/services/purchase_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('연간 플랜 상품 ID (TDD)', () {
    test('ProductIds.all에 연간 플랜 4개 포함', () {
      expect(ProductIds.all.contains('mathbot_pro_monthly'), isTrue);
      expect(ProductIds.all.contains('mathbot_premium_monthly'), isTrue);
      expect(ProductIds.all.contains('mathbot_pro_yearly'), isTrue);
      expect(ProductIds.all.contains('mathbot_premium_yearly'), isTrue);
    });

    test('연간 Pro 월 환산가 = 65,000/12 ≈ 5,417원', () {
      expect(ProductIds.yearlyToMonthlyEquivalent(ProductIds.proYearly), 5417);
    });

    test('연간 Premium 월 환산가 = 99,000/12 = 8,250원', () {
      expect(ProductIds.yearlyToMonthlyEquivalent(ProductIds.premiumYearly), 8250);
    });

    test('연간 Pro 절약율 ≥ 30%', () {
      final savings = ProductIds.yearlySavingsPercent(ProductIds.proYearly);
      expect(savings, greaterThanOrEqualTo(30));
    });
  });

  group('무료 체험 로직 (TDD)', () {
    test('처음 사용 시 hasFreeTrialAvailable = true', () async {
      SharedPreferences.setMockInitialValues({});
      final available = await PurchaseService.checkFreeTrialAvailable();
      expect(available, isTrue);
    });

    test('체험 사용 후 hasFreeTrialAvailable = false', () async {
      SharedPreferences.setMockInitialValues({
        'free_trial_used': true,
      });
      final available = await PurchaseService.checkFreeTrialAvailable();
      expect(available, isFalse);
    });

    test('체험 시작 후 daysRemaining = 7', () async {
      final now = DateTime.now();
      SharedPreferences.setMockInitialValues({
        'free_trial_start': now.toIso8601String(),
      });
      final remaining = await PurchaseService.trialDaysRemaining();
      expect(remaining, 7);
    });

    test('체험 8일 경과 시 daysRemaining = 0', () async {
      final past = DateTime.now().subtract(const Duration(days: 8));
      SharedPreferences.setMockInitialValues({
        'free_trial_start': past.toIso8601String(),
      });
      final remaining = await PurchaseService.trialDaysRemaining();
      expect(remaining, 0);
    });
  });
}
