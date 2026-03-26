import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 인앱 리뷰 트리거 — 순수 로직은 static 메서드로 분리해 TDD 가능
class ReviewTriggerService {
  static const List<int> milestones = [5, 20, 50, 100];

  /// 리뷰 요청이 필요한지 판단 (순수 함수 — 테스트 가능)
  static bool shouldRequest({
    required int completedCount,
    required int lastPromptedAt,
  }) {
    if (completedCount == 0) return false;
    for (final m in milestones) {
      if (completedCount >= m && lastPromptedAt < m) return true;
    }
    return false;
  }

  /// 다음 마일스톤 반환 (없으면 null)
  static int? nextMilestone(int completedCount) {
    for (final m in milestones) {
      if (completedCount < m) return m;
    }
    return null;
  }

  /// 실제 인앱 리뷰 요청 (Flutter 플러그인 사용)
  static Future<void> maybeRequestReview(int completedCount) async {
    if (kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastPromptedAt = prefs.getInt('review_last_prompted_at') ?? 0;
      if (!shouldRequest(completedCount: completedCount, lastPromptedAt: lastPromptedAt)) return;

      final inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
        await prefs.setInt('review_last_prompted_at', completedCount);
      }
    } catch (_) {
      // 리뷰 요청 실패는 무시 (사용자 경험에 영향 없어야 함)
    }
  }
}
