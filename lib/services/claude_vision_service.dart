import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/problem.dart';

/// 카메라로 찍은 수학 문제 이미지를 Claude Vision으로 분석하여
/// 조건분해트리를 생성합니다.
class ClaudeVisionService {
  static const _apiUrl = 'https://api.anthropic.com/v1/messages';

  // TODO: 실제 배포 시 환경변수 또는 백엔드 프록시로 대체
  static const _apiKey = String.fromEnvironment('ANTHROPIC_API_KEY');

  /// Web/Mobile 공통: bytes 직접 전달
  Future<Problem> analyzeImageBytes(Uint8List bytes) async {
    final base64Image = base64Encode(bytes);
    return _analyze(base64Image);
  }

  Future<Problem> _analyze(String base64Image) async {

    if (_apiKey.isEmpty) {
      throw Exception('ANTHROPIC_API_KEY가 설정되지 않았습니다.\n빌드 시 --dart-define=ANTHROPIC_API_KEY=... 를 사용하세요.');
    }
    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': 'claude-sonnet-4-6',
        'max_tokens': 8000,
        'system': _systemPrompt,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'image',
                'source': {
                  'type': 'base64',
                  'media_type': 'image/jpeg',
                  'data': base64Image,
                },
              },
              {
                'type': 'text',
                'text': '이 수학 문제를 조건분해트리로 분석해주세요. JSON만 반환하세요.',
              },
            ],
          },
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('API 오류: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final text = (data['content'] as List).first['text'] as String;

    // JSON 추출
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}') + 1;
    if (start < 0) throw Exception('JSON 파싱 실패');

    final treeJson = jsonDecode(text.substring(start, end)) as Map<String, dynamic>;

    // 카메라 촬영 문제는 임시 Problem 객체로 반환
    return Problem(
      id: 'camera_${DateTime.now().millisecondsSinceEpoch}',
      year: DateTime.now().year,
      no: 0,
      problemText: '촬영한 문제',
      problemType: '단답형',
      choices: [],
      answer: (treeJson['nodes'] as List?)
              ?.firstWhere((n) => n['type'] == 'answer', orElse: () => {'items': ['?']})['items']
              ?.first ?? '?',
      subject: '수학',
      unit: '분석 중',
      concepts: [],
      difficulty: '중',
      nodeDepth: treeJson['node_depth'] as int? ?? 3,
      nodes: (treeJson['nodes'] as List? ?? [])
          .map((e) => TreeNode.fromJson(e as Map<String, dynamic>))
          .toList(),
      optimalPath: treeJson['optimal_path'] as String? ?? '',
      commonMistake: treeJson['common_mistake'] as String? ?? '',
      hints: List<String>.from(treeJson['hints'] as List? ?? []),
      concept: treeJson['concept'] != null
          ? Concept.fromJson(treeJson['concept'] as Map<String, dynamic>)
          : null,
    );
  }

  static const _systemPrompt = '''당신은 수능 수학 조건분해트리 전문 분석가입니다.
이미지의 수학 문제를 5노드 조건분해트리로 분해하세요.

JSON 형식으로만 응답:
{
  "nodes": [
    {"type": "given",     "items": ["조건1", "조건2"]},
    {"type": "formula",   "items": ["공식명: 내용"]},
    {"type": "derive",    "items": ["→ [맥락] [목표]: [방법]"]},
    {"type": "calculate", "items": ["단계1 수식/계산"]},
    {"type": "answer",    "items": ["정답: N"]}
  ],
  "node_depth": 3,
  "optimal_path": "주어진조건 → 핵심공식 → 핵심유도 → 정답 (30자 이내)",
  "common_mistake": "학생들이 가장 많이 하는 실수",
  "hints": ["힌트1", "힌트2", "힌트3"],
  "concept": {
    "title": "핵심 개념명",
    "analogy": "일상 비유 1줄",
    "explain": ["개념 설명1", "언제 쓰는지", "왜 중요한지"],
    "csat_tip": "수능 출제 패턴 꿀팁",
    "tts_script": "선생님 구어체 설명 스크립트"
  }
}''';
}
