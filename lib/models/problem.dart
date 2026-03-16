class TreeNode {
  final String type; // given, formula, derive, calculate, answer
  final List<String> items;
  final String? detail; // 클릭 시 펼쳐지는 상세 설명

  const TreeNode({required this.type, required this.items, this.detail});

  factory TreeNode.fromJson(Map<String, dynamic> json) => TreeNode(
        type: json['type'] as String,
        items: List<String>.from(json['items'] as List),
        detail: json['detail'] as String?,
      );

  String get typeLabel {
    switch (type) {
      case 'given':     return '📌 주어진 조건';
      case 'formula':   return '📐 적용 공식';
      case 'derive':    return '🔍 유도 조건';
      case 'calculate': return '🔢 계산 과정';
      case 'answer':    return '✅ 정답';
      default:          return type;
    }
  }

  String get typeEmoji {
    switch (type) {
      case 'given':     return '📌';
      case 'formula':   return '📐';
      case 'derive':    return '🔍';
      case 'calculate': return '🔢';
      case 'answer':    return '✅';
      default:          return '•';
    }
  }
}

class Concept {
  final String title;
  final String analogy;
  final List<String> explain;
  final String csatTip;
  final String ttsScript;

  const Concept({
    required this.title,
    required this.analogy,
    required this.explain,
    required this.csatTip,
    required this.ttsScript,
  });

  factory Concept.fromJson(Map<String, dynamic> json) => Concept(
        title:     json['title'] as String? ?? '',
        analogy:   json['analogy'] as String? ?? '',
        explain:   List<String>.from(json['explain'] as List? ?? []),
        csatTip:   json['csat_tip'] as String? ?? '',
        ttsScript: json['tts_script'] as String? ?? '',
      );
}

class Problem {
  final String id;
  final int year;
  final int no;
  final String problemText;
  final String problemType;
  final List<String> choices;
  final String answer;
  final String subject;
  final String unit;
  final List<String> concepts;
  final String difficulty;
  final int nodeDepth;
  final List<TreeNode> nodes;
  final String optimalPath;
  final String commonMistake;
  final List<String> hints;
  final Concept? concept;

  const Problem({
    required this.id,
    required this.year,
    required this.no,
    required this.problemText,
    required this.problemType,
    required this.choices,
    required this.answer,
    required this.subject,
    required this.unit,
    required this.concepts,
    required this.difficulty,
    required this.nodeDepth,
    required this.nodes,
    required this.optimalPath,
    required this.commonMistake,
    required this.hints,
    this.concept,
  });

  factory Problem.fromJson(Map<String, dynamic> json) => Problem(
        id:           json['id'] as String? ?? '',
        year:         json['year'] as int? ?? 0,
        no:           json['no'] as int? ?? 0,
        problemText:  json['problem_text'] as String? ?? '',
        problemType:  json['problem_type'] as String? ?? '단답형',
        choices:      List<String>.from(json['choices'] as List? ?? []),
        answer:       json['answer'] as String? ?? '',
        subject:      json['subject'] as String? ?? '',
        unit:         json['unit'] as String? ?? '',
        concepts:     List<String>.from(json['concepts'] as List? ?? []),
        difficulty:   json['difficulty'] as String? ?? '중',
        nodeDepth:    json['node_depth'] as int? ?? 0,
        nodes:        (json['nodes'] as List? ?? [])
                          .map((e) => TreeNode.fromJson(e as Map<String, dynamic>))
                          .toList(),
        optimalPath:  json['optimal_path'] as String? ?? '',
        commonMistake: json['common_mistake'] as String? ?? '',
        hints:        List<String>.from(json['hints'] as List? ?? []),
        concept:      json['concept'] != null
                          ? Concept.fromJson(json['concept'] as Map<String, dynamic>)
                          : null,
      );

  String get difficultyLabel {
    switch (difficulty) {
      case '상': return '킬러';
      case '중': return '준킬러';
      case '하': return '기본';
      default:   return difficulty;
    }
  }

  String get difficultyColor {
    switch (difficulty) {
      case '상': return 'red';
      case '중': return 'orange';
      case '하': return 'green';
      default:   return 'grey';
    }
  }
}
