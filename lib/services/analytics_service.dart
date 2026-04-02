import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

/// Analytics Service — Firebase Analytics + PostHog CDP 동시 전송
///
/// 이벤트는 두 곳에 모두 기록됨:
///   - Firebase Analytics: 기기/크래시 로그, Google 기반 퍼널
///   - PostHog: Solo Factory OS 동일 프로젝트 → 크로스 앱 유저 분석
///
/// 빌드 시 주입:
///   --dart-define=POSTHOG_KEY=phc_xxx
///   --dart-define=POSTHOG_HOST=https://us.i.posthog.com  (기본값)
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._();
  factory AnalyticsService() => _instance;
  AnalyticsService._();

  static const _posthogKey =
      String.fromEnvironment('POSTHOG_KEY', defaultValue: '');
  static const _posthogHost =
      String.fromEnvironment('POSTHOG_HOST', defaultValue: 'https://us.i.posthog.com');

  FirebaseAnalytics? _fa;
  bool _posthogReady = false;

  Future<void> init() async {
    // Firebase Analytics
    try {
      _fa = FirebaseAnalytics.instance;
    } catch (e) {
      debugPrint('[Analytics] Firebase init failed: $e');
    }

    // PostHog (키 있을 때만)
    if (_posthogKey.isNotEmpty) {
      try {
        final config = PostHogConfig(_posthogKey)..host = _posthogHost;
        await Posthog().setup(config);
        _posthogReady = true;
      } catch (e) {
        debugPrint('[Analytics] PostHog init failed: $e');
      }
    }
  }

  /// 유저 식별 (로그인 시 or 앱 시작 시)
  Future<void> identify(String userId, {Map<String, Object>? properties}) async {
    try {
      await _fa?.setUserId(id: userId);
      if (_posthogReady) {
        await Posthog().identify(
          userId: userId,
          userProperties: properties,
        );
      }
    } catch (e) {
      debugPrint('[Analytics] identify error: $e');
    }
  }

  /// 유저 프로퍼티 설정 (플랜, 레벨 등)
  Future<void> setUserProperties({
    String? plan,
    int? level,
    int? totalXp,
    int? streak,
    int? problemsSolved,
  }) async {
    try {
      if (plan != null) await _fa?.setUserProperty(name: 'plan', value: plan);
      if (level != null) await _fa?.setUserProperty(name: 'level', value: level.toString());
      if (_posthogReady) {
        final props = <String, Object>{};
        if (plan != null) props['plan'] = plan;
        if (level != null) props['level'] = level;
        if (totalXp != null) props['total_xp'] = totalXp;
        if (streak != null) props['streak'] = streak;
        if (problemsSolved != null) props['problems_solved'] = problemsSolved;
        if (props.isNotEmpty) {
          await Posthog().capture(
            eventName: r'$set',
            properties: {r'$set': props},
          );
        }
      }
    } catch (e) {
      debugPrint('[Analytics] setUserProperties error: $e');
    }
  }

  // ─────────────────────────────────────────
  // 문제 풀이 이벤트
  // ─────────────────────────────────────────

  Future<void> problemViewed(String problemId, {
    required int year,
    required String unit,
    required String difficulty,
  }) => _track('problem_viewed', {
    'problem_id': problemId,
    'year': year,
    'unit': unit,
    'difficulty': difficulty,
    'app': 'mathbot',
  });

  Future<void> treeCompleted(String problemId, {
    required int hintsUsed,
    required String mode,
    required int xpEarned,
  }) => _track('tree_completed', {
    'problem_id': problemId,
    'hints_used': hintsUsed,
    'mode': mode,
    'xp_earned': xpEarned,
    'app': 'mathbot',
  });

  Future<void> hintUsed(String problemId, {required int hintLevel}) =>
      _track('hint_used', {
        'problem_id': problemId,
        'hint_level': hintLevel,
        'app': 'mathbot',
      });

  Future<void> wrongNoteAdded(String problemId) =>
      _track('wrong_note_added', {'problem_id': problemId, 'app': 'mathbot'});

  Future<void> conceptViewed(String conceptTitle) =>
      _track('concept_viewed', {'concept_title': conceptTitle, 'app': 'mathbot'});

  Future<void> cameraUsed() =>
      _track('camera_used', {'app': 'mathbot'});

  // ─────────────────────────────────────────
  // 게임 이벤트
  // ─────────────────────────────────────────

  Future<void> xpEarned(int amount, {required String source}) =>
      _track('xp_earned', {'amount': amount, 'source': source, 'app': 'mathbot'});

  Future<void> levelUp(int newLevel) =>
      _track('level_up', {'new_level': newLevel, 'app': 'mathbot'});

  Future<void> streakUpdated(int days) =>
      _track('streak_updated', {'days': days, 'app': 'mathbot'});

  // ─────────────────────────────────────────
  // 결제 퍼널 이벤트
  // ─────────────────────────────────────────

  Future<void> paywallShown({required String trigger}) =>
      _track('paywall_shown', {'trigger': trigger, 'app': 'mathbot'});

  Future<void> freeTrialStarted() =>
      _track('free_trial_started', {'app': 'mathbot'});

  Future<void> purchaseStarted(String productId) =>
      _track('purchase_started', {'product_id': productId, 'app': 'mathbot'});

  Future<void> purchaseCompleted(String productId, {required String plan}) =>
      _track('purchase_completed', {
        'product_id': productId,
        'plan': plan,
        'app': 'mathbot',
      });

  Future<void> purchaseFailed(String productId, {required String reason}) =>
      _track('purchase_failed', {
        'product_id': productId,
        'reason': reason,
        'app': 'mathbot',
      });

  // ─────────────────────────────────────────
  // 화면 조회
  // ─────────────────────────────────────────

  Future<void> screenViewed(String screenName) async {
    try {
      await _fa?.logScreenView(screenName: screenName);
      if (_posthogReady) {
        await Posthog().screen(screenName: screenName);
      }
    } catch (e) {
      debugPrint('[Analytics] screenViewed error: $e');
    }
  }

  // ─────────────────────────────────────────
  // 내부 공통 트래킹
  // ─────────────────────────────────────────

  Future<void> _track(String event, Map<String, Object> params) async {
    try {
      // Firebase Analytics (String 값만 허용)
      final faParams = params.map((k, v) => MapEntry(k, v.toString()));
      await _fa?.logEvent(name: event, parameters: faParams);

      // PostHog
      if (_posthogReady) {
        await Posthog().capture(eventName: event, properties: params);
      }
    } catch (e) {
      debugPrint('[Analytics] track($event) error: $e');
    }
  }
}
