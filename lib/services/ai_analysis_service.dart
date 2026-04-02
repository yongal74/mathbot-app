import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'wrong_note_service.dart';
import 'game_service.dart';

/// Claude API 기반 오답 패턴 AI 분석 서비스
///
/// 빌드 시 주입: --dart-define=ANTHROPIC_API_KEY=sk-ant-...
class AiAnalysisService extends ChangeNotifier {
  static final AiAnalysisService _instance = AiAnalysisService._();
  factory AiAnalysisService() => _instance;
  AiAnalysisService._();

  static const _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const _apiKey =
      String.fromEnvironment('ANTHROPIC_API_KEY', defaultValue: '');

  bool _loading = false;
  String? _result;
  String? _error;

  bool get loading => _loading;
  String? get result => _result;
  String? get error => _error;
  bool get hasApiKey => _apiKey.isNotEmpty;

  /// 오답 노트 + 학습 통계를 기반으로 AI 분석 요청
  Future<void> analyze() async {
    if (_apiKey.isEmpty) {
      _error = 'ANTHROPIC_API_KEY가 설정되지 않았습니다.';
      notifyListeners();
      return;
    }

    _loading = true;
    _error = null;
    _result = null;
    notifyListeners();

    try {
      final notes = WrongNoteService().all;
      final progress = GameService().progress;
      final unitWeakness = WrongNoteService().unitWeakness;

      // 분석 데이터 요약 생성
      final unitSummary = unitWeakness.entries
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final topUnits = unitSummary.take(5).map((e) => '${e.key}:${e.value}개').join(', ');

      final weakNodeTypes = <String, int>{};
      for (final note in notes) {
        for (final node in note.weakNodes) {
          weakNodeTypes[node] = (weakNodeTypes[node] ?? 0) + 1;
        }
      }
      final nodeStr = weakNodeTypes.entries
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topNodes = nodeStr.take(5).map((e) => '${e.key}:${e.value}회').join(', ');

      final difficultyMap = <String, int>{};
      for (final note in notes) {
        difficultyMap[note.difficulty] =
            (difficultyMap[note.difficulty] ?? 0) + 1;
      }
      final diffStr = difficultyMap.entries
          .map((e) => '${e.key}:${e.value}개')
          .join(', ');

      final prompt = '''
수능 수학 학습 데이터를 분석해주세요.

[학습 현황]
- 총 오답: ${notes.length}개
- 연속 학습: ${progress.streakDays}일
- 레벨: Lv.${progress.level.level} (총 ${progress.totalXp} XP)
- 완료 문제: ${progress.completedCount}문제

[약점 단원 Top 5]
$topUnits

[자주 막히는 노드 유형]
$topNodes

[난이도별 오답]
$diffStr

위 데이터를 바탕으로:
1. 핵심 약점 패턴 2-3가지를 구체적으로 설명해주세요
2. 맞춤형 학습 전략 3가지를 제안해주세요
3. 수능까지의 단기 집중 학습 계획을 제시해주세요

수능 수학 전문 튜터 입장에서 따뜻하고 구체적으로 조언해주세요. 500자 이내로 요약해주세요.''';

      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': _apiKey,
              'anthropic-version': '2023-06-01',
            },
            body: jsonEncode({
              'model': 'claude-haiku-4-5-20251001',
              'max_tokens': 1024,
              'messages': [
                {'role': 'user', 'content': prompt},
              ],
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('API 오류: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _result = (data['content'] as List).first['text'] as String;
    } catch (e) {
      _error = e.toString();
      debugPrint('[AiAnalysis] error: $e');
    }

    _loading = false;
    notifyListeners();
  }

  void clear() {
    _result = null;
    _error = null;
    notifyListeners();
  }
}
