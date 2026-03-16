/// 오답노트 — Phase 1: SharedPreferences 로컬 저장
/// Phase 2: Firebase Firestore로 마이그레이션 예정
class WrongNote {
  final String problemId;
  final int year;
  final int no;
  final String unit;
  final String difficulty;
  final DateTime savedAt;
  final String memo; // 학생 메모
  final int reviewCount; // 복습 횟수

  const WrongNote({
    required this.problemId,
    required this.year,
    required this.no,
    required this.unit,
    required this.difficulty,
    required this.savedAt,
    this.memo = '',
    this.reviewCount = 0,
  });

  WrongNote copyWith({String? memo, int? reviewCount}) => WrongNote(
        problemId: problemId,
        year: year,
        no: no,
        unit: unit,
        difficulty: difficulty,
        savedAt: savedAt,
        memo: memo ?? this.memo,
        reviewCount: reviewCount ?? this.reviewCount,
      );

  Map<String, dynamic> toJson() => {
        'problemId': problemId,
        'year': year,
        'no': no,
        'unit': unit,
        'difficulty': difficulty,
        'savedAt': savedAt.toIso8601String(),
        'memo': memo,
        'reviewCount': reviewCount,
      };

  factory WrongNote.fromJson(Map<String, dynamic> json) => WrongNote(
        problemId: json['problemId'] as String,
        year: json['year'] as int,
        no: json['no'] as int,
        unit: json['unit'] as String,
        difficulty: json['difficulty'] as String,
        savedAt: DateTime.parse(json['savedAt'] as String),
        memo: json['memo'] as String? ?? '',
        reviewCount: json['reviewCount'] as int? ?? 0,
      );
}
