import 'dart:convert';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;

/// TTS 서비스
///
/// Priority:
///   1. OpenAI TTS (tts-1-hd) — 거의 사람 수준, 한국어 최고 품질
///      빌드 시 --dart-define=OPENAI_API_KEY=sk-...
///   2. flutter_tts (기기 내장) — 키 없을 때 자동 폴백
///
/// 속도: 0.5× ~ 2.0× (탭하여 순환)
class TtsService extends ChangeNotifier {
  static final TtsService _instance = TtsService._();
  factory TtsService() => _instance;
  TtsService._();

  // OpenAI API 키 (빌드 시 주입)
  static const _openAiKey =
      String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
  static bool get _hasOpenAiKey => _openAiKey.isNotEmpty;

  // OpenAI TTS 설정
  static const _model = 'tts-1-hd';
  static const _voice = 'nova'; // nova: 자연스럽고 따뜻한 여성 목소리 (한국어 최적)

  final AudioPlayer _player = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();

  bool _isPlaying = false;
  double _speed = 1.0;
  String? _currentText;

  bool get isPlaying => _isPlaying;
  double get speed => _speed;

  static const _speedSteps = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  String get speedLabel {
    if (_speed <= 0.62) return '0.5×';
    if (_speed <= 0.87) return '0.75×';
    if (_speed <= 1.12) return '1×';
    if (_speed <= 1.37) return '1.25×';
    if (_speed <= 1.75) return '1.5×';
    return '2×';
  }

  Future<void> init() async {
    // audioplayers 이벤트
    _player.onPlayerComplete.listen((_) {
      _isPlaying = false;
      _currentText = null;
      notifyListeners();
    });
    _player.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.stopped) {
        _isPlaying = false;
        _currentText = null;
        notifyListeners();
      }
    });

    // flutter_tts 폴백 초기화
    await _flutterTts.setLanguage('ko-KR');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    _flutterTts.setCompletionHandler(() {
      _isPlaying = false;
      _currentText = null;
      notifyListeners();
    });
  }

  Future<void> speak(String text) async {
    if (_isPlaying) await stop();

    _currentText = text;
    _isPlaying = true;
    notifyListeners();

    if (_hasOpenAiKey) {
      await _speakOpenAi(text);
    } else {
      await _speakFallback(text);
    }
  }

  Future<void> _speakOpenAi(String text) async {
    try {
      final response = await http
          .post(
            Uri.parse('https://api.openai.com/v1/audio/speech'),
            headers: {
              'Authorization': 'Bearer $_openAiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': _model,
              'input': text,
              'voice': _voice,
              'speed': _speed.clamp(0.25, 4.0),
              'response_format': 'mp3',
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        await _player.play(BytesSource(bytes));
        // 상태는 onPlayerComplete에서 처리됨
      } else {
        debugPrint('[TTS] OpenAI error ${response.statusCode}: ${response.body}');
        await _speakFallback(text);
      }
    } catch (e) {
      debugPrint('[TTS] OpenAI exception: $e');
      await _speakFallback(text);
    }
  }

  Future<void> _speakFallback(String text) async {
    await _flutterTts.setSpeechRate(_speed * 0.5);
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _player.stop();
    await _flutterTts.stop();
    _isPlaying = false;
    _currentText = null;
    notifyListeners();
  }

  /// 속도 단계 순환 탭
  Future<void> cycleSpeed() async {
    final idx = _speedSteps.indexWhere((s) => (_speed - s).abs() < 0.1);
    final next = _speedSteps[(idx + 1) % _speedSteps.length];
    _speed = next;
    notifyListeners();
  }

  Future<void> setSpeed(double speed) async {
    _speed = speed.clamp(0.5, 2.0);
    notifyListeners();
  }

  bool isReadingText(String text) => _isPlaying && _currentText == text;
}
