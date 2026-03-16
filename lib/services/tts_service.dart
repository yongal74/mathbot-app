import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Phase 1: flutter_tts (기기 내장)
/// Phase 2: ElevenLabs API로 교체 예정 — 인터페이스 동일하게 유지
class TtsService extends ChangeNotifier {
  static final TtsService _instance = TtsService._();
  factory TtsService() => _instance;
  TtsService._();

  final FlutterTts _tts = FlutterTts();
  bool _isPlaying = false;
  double _speed = 1.0;
  String? _currentText;

  bool get isPlaying => _isPlaying;
  double get speed => _speed;

  Future<void> init() async {
    await _tts.setLanguage('ko-KR');
    await _tts.setSpeechRate(_speed);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setCompletionHandler(() {
      _isPlaying = false;
      _currentText = null;
      notifyListeners();
    });

    _tts.setCancelHandler(() {
      _isPlaying = false;
      notifyListeners();
    });
  }

  Future<void> speak(String text) async {
    if (_isPlaying) await stop();
    _currentText = text;
    _isPlaying = true;
    notifyListeners();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
    _isPlaying = false;
    _currentText = null;
    notifyListeners();
  }

  Future<void> setSpeed(double speed) async {
    _speed = speed.clamp(0.5, 2.0);
    await _tts.setSpeechRate(_speed);
    notifyListeners();
  }

  bool isReadingText(String text) => _isPlaying && _currentText == text;
}
