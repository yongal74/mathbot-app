import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;

/// TTS 서비스
///
/// Priority:
///   1. Naver Clova Voice — 원어민 수준 한국어 (모바일)
///      빌드 시 --dart-define=NAVER_CLIENT_ID=xxx --dart-define=NAVER_CLIENT_SECRET=yyy
///   2. flutter_tts (기기 내장) — 웹 또는 키 없을 때 자동 폴백
///
/// 속도: 0.5× ~ 2.0× (탭하여 순환)
class TtsService extends ChangeNotifier {
  static final TtsService _instance = TtsService._();
  factory TtsService() => _instance;
  TtsService._();

  // Naver Clova Voice API 키 (빌드 시 주입)
  static const _naverId =
      String.fromEnvironment('NAVER_CLIENT_ID', defaultValue: '');
  static const _naverSecret =
      String.fromEnvironment('NAVER_CLIENT_SECRET', defaultValue: '');
  static bool get _hasNaverKey => _naverId.isNotEmpty && _naverSecret.isNotEmpty;

  // Naver Clova Voice 설정
  // speaker 옵션: nara(표준여성), nminyoung(사랑스러운), nyejin(발랄한), jinho(표준남성)
  static const _speaker = 'nara';
  static const _naverApiUrl = 'https://openapi.naver.com/v1/tts';

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

  /// flutter_speed(0.5~2.0) → Naver speed(-5~5)
  int get _naverSpeed {
    if (_speed < 1.0) {
      // 0.5 → -5, 1.0 → 0
      return ((_speed - 0.5) / 0.5 * 5 - 5).round().clamp(-5, 5);
    } else {
      // 1.0 → 0, 2.0 → 5
      return ((_speed - 1.0) / 1.0 * 5).round().clamp(-5, 5);
    }
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

    // 웹은 CORS 이슈로 Naver API 직접 호출 불가 → flutter_tts 사용
    if (!kIsWeb && _hasNaverKey) {
      await _speakNaver(text);
    } else {
      await _speakFallback(text);
    }
  }

  Future<void> _speakNaver(String text) async {
    try {
      final body = Uri.encodeFull(
        'speaker=$_speaker&volume=0&speed=$_naverSpeed&pitch=0&format=mp3&text=$text',
      );
      final response = await http
          .post(
            Uri.parse(_naverApiUrl),
            headers: {
              'X-Naver-Client-Id': _naverId,
              'X-Naver-Client-Secret': _naverSecret,
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        await _player.play(BytesSource(response.bodyBytes));
        // 상태는 onPlayerComplete에서 처리됨
      } else {
        debugPrint('[TTS] Naver error ${response.statusCode}: ${response.body}');
        await _speakFallback(text);
      }
    } catch (e) {
      debugPrint('[TTS] Naver exception: $e');
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
