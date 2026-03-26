import 'package:flutter_test/flutter_test.dart';
import 'package:mathbot_app/services/review_trigger_service.dart';

void main() {
  group('리뷰 트리거 로직 (TDD)', () {
    test('5번째 완료 시 리뷰 요청 필요', () {
      expect(ReviewTriggerService.shouldRequest(completedCount: 5, lastPromptedAt: 0), isTrue);
    });

    test('20번째 완료 시 리뷰 요청 필요', () {
      expect(ReviewTriggerService.shouldRequest(completedCount: 20, lastPromptedAt: 5), isTrue);
    });

    test('50번째 완료 시 리뷰 요청 필요', () {
      expect(ReviewTriggerService.shouldRequest(completedCount: 50, lastPromptedAt: 20), isTrue);
    });

    test('100번째 완료 시 리뷰 요청 필요', () {
      expect(ReviewTriggerService.shouldRequest(completedCount: 100, lastPromptedAt: 50), isTrue);
    });

    test('이미 5에서 프롬프트 했으면 6에서 false', () {
      expect(ReviewTriggerService.shouldRequest(completedCount: 6, lastPromptedAt: 5), isFalse);
    });

    test('0 완료 시 false', () {
      expect(ReviewTriggerService.shouldRequest(completedCount: 0, lastPromptedAt: 0), isFalse);
    });

    test('3 완료 시 false (마일스톤 아님)', () {
      expect(ReviewTriggerService.shouldRequest(completedCount: 3, lastPromptedAt: 0), isFalse);
    });

    test('밀스톤 목록: [5, 20, 50, 100]', () {
      expect(ReviewTriggerService.milestones, containsAllInOrder([5, 20, 50, 100]));
    });

    test('다음 마일스톤: 3 완료 → 5', () {
      expect(ReviewTriggerService.nextMilestone(3), 5);
    });

    test('다음 마일스톤: 5 완료 → 20', () {
      expect(ReviewTriggerService.nextMilestone(5), 20);
    });

    test('다음 마일스톤: 100 완료 이상 → null', () {
      expect(ReviewTriggerService.nextMilestone(100), isNull);
    });
  });
}
