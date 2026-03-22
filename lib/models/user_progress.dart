/// Phase 2 게임 레이어 — XP / 레벨 / 스트릭 / 배지

class UserLevel {
  final int level;
  final String title;
  final int xpRequired;
  final String unlocks;

  const UserLevel({
    required this.level,
    required this.title,
    required this.xpRequired,
    required this.unlocks,
  });

  static const List<UserLevel> levels = [
    UserLevel(level: 1, title: '입문자',  xpRequired: 0,      unlocks: '개념-先 모드'),
    UserLevel(level: 2, title: '관찰자',  xpRequired: 2000,   unlocks: '단원별 필터 + 약점 지도'),
    UserLevel(level: 3, title: '수련생',  xpRequired: 5000,   unlocks: '문제-先 모드'),
    UserLevel(level: 4, title: '풀이자',  xpRequired: 10000,  unlocks: '속도 모드 타이머'),
    UserLevel(level: 5, title: '수능러',  xpRequired: 20000,  unlocks: '연도별 정렬 모드'),
    UserLevel(level: 6, title: '만점자',  xpRequired: 40000,  unlocks: '선생님 모드'),
  ];

  static UserLevel fromXp(int xp) {
    UserLevel current = levels.first;
    for (final l in levels) {
      if (xp >= l.xpRequired) current = l;
    }
    return current;
  }

  static UserLevel? nextLevel(int xp) {
    final idx = fromXp(xp).level;
    if (idx >= levels.length) return null;
    return levels[idx]; // levels is 0-indexed but level starts at 1
  }

  static double progressToNext(int xp) {
    final cur = fromXp(xp);
    final next = nextLevel(xp);
    if (next == null) return 1.0;
    final range = next.xpRequired - cur.xpRequired;
    final earned = xp - cur.xpRequired;
    return (earned / range).clamp(0.0, 1.0);
  }
}

class XpGain {
  final int amount;
  final String reason;

  const XpGain({required this.amount, required this.reason});

  /// XP 계산: 힌트 수 + 난이도 + 스트릭 반영
  static XpGain calculate({
    required int hintsUsed,
    required String difficulty,
    required int streakDays,
    bool conceptMode = false,
  }) {
    int base;
    String reason;

    if (conceptMode) {
      base = 20;
      reason = '개념-先 완료';
    } else {
      switch (hintsUsed) {
        case 0:  base = 300; reason = '힌트 0개 완료 🏆'; break;
        case 1:  base = 200; reason = '힌트 1개 사용'; break;
        case 2:  base = 100; reason = '힌트 2개 사용'; break;
        default: base = 50;  reason = '힌트 3개 사용'; break;
      }
    }

    // 난이도 배율
    if (difficulty == '상') {
      base = (base * 2).round();
      reason += ' × 킬러 2배';
    }

    // 스트릭 배율
    if (streakDays >= 7) {
      base = (base * 1.5).round();
      reason += ' × 스트릭 1.5배';
    }

    return XpGain(amount: base, reason: reason);
  }
}

class AchievementBadge {
  final String id;
  final String emoji;
  final String name;
  final String description;
  final bool earned;

  const AchievementBadge({
    required this.id,
    required this.emoji,
    required this.name,
    required this.description,
    this.earned = false,
  });

  static const List<AchievementBadge> all = [
    AchievementBadge(id: 'first_tree',    emoji: '🌱', name: '첫 트리',      description: '첫 번째 조건분해트리 완료'),
    AchievementBadge(id: 'no_hint',       emoji: '🎯', name: '무힌트 달인',   description: '힌트 없이 킬러 문제 풀기'),
    AchievementBadge(id: 'streak_7',      emoji: '🔥', name: '7일 연속',     description: '7일 연속 학습'),
    AchievementBadge(id: 'streak_30',     emoji: '💎', name: '30일 연속',    description: '30일 연속 학습'),
    AchievementBadge(id: 'unit_complete', emoji: '🏆', name: '단원 완주',     description: '단원 전체 개념 완주'),
    AchievementBadge(id: 'camera_first',  emoji: '📸', name: '카메라 분석가', description: '첫 번째 문제 촬영 분석'),
    AchievementBadge(id: 'killer_10',     emoji: '💀', name: '킬러 사냥꾼',  description: '킬러 문제 10개 완료'),
    AchievementBadge(id: 'all_750',       emoji: '🚀', name: '수능 마스터',  description: '750문제 전체 1바퀴 완주'),
  ];
}

class UserProgress {
  final int totalXp;
  final int streakDays;
  final DateTime? lastStudyDate;
  final Set<String> completedProblemIds;
  final Set<String> earnedBadgeIds;
  final Map<String, int> unitCompletionCount; // unit → 완료 문제 수
  final int killerCompletedCount; // difficulty '상' 완료 수 (킬러 배지용)

  const UserProgress({
    this.totalXp = 0,
    this.streakDays = 0,
    this.lastStudyDate,
    this.completedProblemIds = const {},
    this.earnedBadgeIds = const {},
    this.unitCompletionCount = const {},
    this.killerCompletedCount = 0,
  });

  UserLevel get level => UserLevel.fromXp(totalXp);
  double get levelProgress => UserLevel.progressToNext(totalXp);
  int get completedCount => completedProblemIds.length;

  UserProgress copyWith({
    int? totalXp,
    int? streakDays,
    DateTime? lastStudyDate,
    Set<String>? completedProblemIds,
    Set<String>? earnedBadgeIds,
    Map<String, int>? unitCompletionCount,
    int? killerCompletedCount,
  }) =>
      UserProgress(
        totalXp: totalXp ?? this.totalXp,
        streakDays: streakDays ?? this.streakDays,
        lastStudyDate: lastStudyDate ?? this.lastStudyDate,
        completedProblemIds: completedProblemIds ?? this.completedProblemIds,
        earnedBadgeIds: earnedBadgeIds ?? this.earnedBadgeIds,
        unitCompletionCount: unitCompletionCount ?? this.unitCompletionCount,
        killerCompletedCount: killerCompletedCount ?? this.killerCompletedCount,
      );

  Map<String, dynamic> toJson() => {
        'totalXp': totalXp,
        'streakDays': streakDays,
        'lastStudyDate': lastStudyDate?.toIso8601String(),
        'completedProblemIds': completedProblemIds.toList(),
        'earnedBadgeIds': earnedBadgeIds.toList(),
        'unitCompletionCount': unitCompletionCount,
        'killerCompletedCount': killerCompletedCount,
      };

  factory UserProgress.fromJson(Map<String, dynamic> json) => UserProgress(
        totalXp: json['totalXp'] as int? ?? 0,
        streakDays: json['streakDays'] as int? ?? 0,
        lastStudyDate: json['lastStudyDate'] != null
            ? DateTime.parse(json['lastStudyDate'] as String)
            : null,
        completedProblemIds:
            Set<String>.from(json['completedProblemIds'] as List? ?? []),
        earnedBadgeIds:
            Set<String>.from(json['earnedBadgeIds'] as List? ?? []),
        unitCompletionCount:
            Map<String, int>.from(json['unitCompletionCount'] as Map? ?? {}),
        killerCompletedCount: json['killerCompletedCount'] as int? ?? 0,
      );
}
