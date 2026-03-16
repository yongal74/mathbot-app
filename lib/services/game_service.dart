import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_progress.dart';
import '../models/problem.dart';

class GameService extends ChangeNotifier {
  static final GameService _instance = GameService._();
  factory GameService() => _instance;
  GameService._();

  UserProgress _progress = const UserProgress();
  UserProgress get progress => _progress;

  static const _key = 'user_progress';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      _progress = UserProgress.fromJson(json.decode(raw) as Map<String, dynamic>);
    }
    _updateStreak();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(_progress.toJson()));
  }

  void _updateStreak() {
    final last = _progress.lastStudyDate;
    if (last == null) return;
    final today = DateTime.now();
    final diff = today.difference(last).inDays;
    if (diff == 0) return; // 오늘 이미 학습함
    if (diff == 1) return; // 어제 학습 → 스트릭 유지
    // 2일 이상 공백 → 스트릭 리셋
    _progress = _progress.copyWith(streakDays: 0);
  }

  /// 문제 완료 처리 → XP 획득 + 배지 체크
  Future<XpResult> completeProblem({
    required Problem problem,
    required int hintsUsed,
    bool conceptMode = false,
  }) async {
    final xpGain = XpGain.calculate(
      hintsUsed: hintsUsed,
      difficulty: problem.difficulty,
      streakDays: _progress.streakDays,
      conceptMode: conceptMode,
    );

    final prevLevel = _progress.level;
    final newXp = _progress.totalXp + xpGain.amount;
    final newCompleted = {..._progress.completedProblemIds, problem.id};

    // 스트릭 업데이트
    final today = DateTime.now();
    final last = _progress.lastStudyDate;
    int newStreak = _progress.streakDays;
    if (last == null || today.difference(last).inDays >= 1) {
      newStreak += 1;
    }

    // 단원 완료 카운트
    final unitMap = Map<String, int>.from(_progress.unitCompletionCount);
    unitMap[problem.unit] = (unitMap[problem.unit] ?? 0) + 1;

    _progress = _progress.copyWith(
      totalXp: newXp,
      streakDays: newStreak,
      lastStudyDate: today,
      completedProblemIds: newCompleted,
      unitCompletionCount: unitMap,
    );

    // 배지 체크
    final newBadges = _checkBadges(problem, hintsUsed, newStreak);
    if (newBadges.isNotEmpty) {
      _progress = _progress.copyWith(
        earnedBadgeIds: {..._progress.earnedBadgeIds, ...newBadges.map((b) => b.id)},
      );
    }

    final leveledUp = _progress.level.level > prevLevel.level;
    await _save();
    notifyListeners();

    return XpResult(
      xpGain: xpGain,
      leveledUp: leveledUp,
      newLevel: leveledUp ? _progress.level : null,
      newBadges: newBadges,
      newStreak: newStreak,
    );
  }

  List<AchievementBadge> _checkBadges(Problem problem, int hintsUsed, int streak) {
    final earned = <AchievementBadge>[];
    final existing = _progress.earnedBadgeIds;
    final completed = _progress.completedProblemIds;

    // 첫 트리
    if (!existing.contains('first_tree') && completed.isEmpty) {
      earned.add(AchievementBadge.all.firstWhere((b) => b.id == 'first_tree'));
    }
    // 무힌트 킬러
    if (!existing.contains('no_hint') && hintsUsed == 0 && problem.difficulty == '상') {
      earned.add(AchievementBadge.all.firstWhere((b) => b.id == 'no_hint'));
    }
    // 스트릭
    if (!existing.contains('streak_7') && streak >= 7) {
      earned.add(AchievementBadge.all.firstWhere((b) => b.id == 'streak_7'));
    }
    if (!existing.contains('streak_30') && streak >= 30) {
      earned.add(AchievementBadge.all.firstWhere((b) => b.id == 'streak_30'));
    }
    // 카메라 분석가
    if (!existing.contains('camera_first') && problem.id.startsWith('camera_')) {
      earned.add(AchievementBadge.all.firstWhere((b) => b.id == 'camera_first'));
    }
    // 킬러 10개
    final killerCount = completed.length; // 실제론 킬러만 필터링 필요
    if (!existing.contains('killer_10') && problem.difficulty == '상' && killerCount >= 9) {
      earned.add(AchievementBadge.all.firstWhere((b) => b.id == 'killer_10'));
    }

    return earned;
  }

  bool isProblemCompleted(String problemId) =>
      _progress.completedProblemIds.contains(problemId);
}

class XpResult {
  final XpGain xpGain;
  final bool leveledUp;
  final UserLevel? newLevel;
  final List<AchievementBadge> newBadges;
  final int newStreak;

  const XpResult({
    required this.xpGain,
    required this.leveledUp,
    this.newLevel,
    required this.newBadges,
    required this.newStreak,
  });
}
