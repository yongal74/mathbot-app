/// 오답노트 — 로컬 SharedPreferences 저장
class WrongNote {
  final String problemId;
  final int year;
  final int no;
  final String unit;
  final String difficulty;
  final DateTime savedAt;
  final String memo;
  final int reviewCount;
  final List<String> weakNodes; // 모르는 트리 노드 타입들

  const WrongNote({
    required this.problemId,
    required this.year,
    required this.no,
    required this.unit,
    required this.difficulty,
    required this.savedAt,
    this.memo = '',
    this.reviewCount = 0,
    this.weakNodes = const [],
  });

  WrongNote copyWith({String? memo, int? reviewCount, List<String>? weakNodes}) => WrongNote(
        problemId: problemId,
        year: year,
        no: no,
        unit: unit,
        difficulty: difficulty,
        savedAt: savedAt,
        memo: memo ?? this.memo,
        reviewCount: reviewCount ?? this.reviewCount,
        weakNodes: weakNodes ?? this.weakNodes,
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
        'weakNodes': weakNodes,
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
        weakNodes: List<String>.from(json['weakNodes'] as List? ?? []),
      );
}
