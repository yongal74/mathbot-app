import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;

/// TTS 서비스
///
/// - Naver Clova Voice API (자연스러운 한국어)
///   빌드 시 환경변수: CLOVA_CLIENT_ID, CLOVA_CLIENT_SECRET
/// - 미제공 시 flutter_tts (브라우저/기기 내장) 폴백
/// - 속도 조절: 0.5 ~ 2.0 (1.0 = 기본)
class TtsService extends ChangeNotifier {
  static final TtsService _instance = TtsService._();
  factory TtsService() => _instance;
  TtsService._();

  // Naver Clova Voice API 키 (빌드 환경변수로 주입)
  static const _clientId =
      String.fromEnvironment('CLOVA_CLIENT_ID', defaultValue: '');
  static const _clientSecret =
      String.fromEnvironment('CLOVA_CLIENT_SECRET', defaultValue: '');

  static bool get _hasClovaKey =>
      _clientId.isNotEmpty && _clientSecret.isNotEmpty;

  final FlutterTts _tts = FlutterTts();
  bool _isPlaying = false;
  double _speed = 1.0; // 0.5 ~ 2.0
  String? _currentText;

  bool get isPlaying => _isPlaying;
  double get speed => _speed;

  // 속도 라벨
  String get speedLabel {
    if (_speed <= 0.6) return '0.5×';
    if (_speed <= 0.85) return '0.75×';
    if (_speed <= 1.1) return '1×';
    if (_speed <= 1.35) return '1.25×';
    if (_speed <= 1.6) return '1.5×';
    return '2×';
  }

  Future<void> init() async {
    await _tts.setLanguage('ko-KR');
    await _tts.setSpeechRate(_speed * 0.5); // flutter_tts는 0~1 범위
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

    if (_hasClovaKey) {
      await _speakClova(text);
    } else {
      await _tts.speak(text);
    }
  }

  Future<void> _speakClova(String text) async {
    try {
      // Clova speed: -5(느림) ~ 5(빠름), 0=기본
      // _speed 1.0 → clovaSpeed 0, _speed 0.5 → -4, _speed 2.0 → 4
      final clovaSpeed = ((_speed - 1.0) * 4).round().clamp(-5, 5);
      final speaker = 'nara'; // 자연스러운 여성 목소리 (nara_call, nsihyun 등)

      final response = await http.post(
        Uri.parse(
            'https://naveropenapi.apigw.ntruss.com/tts-premium/v1/tts'),
        headers: {
          'X-NCP-APIGW-API-KEY-ID': _clientId,
          'X-NCP-APIGW-API-KEY': _clientSecret,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body:
            'speaker=$speaker&volume=0&speed=$clovaSpeed&pitch=0&format=mp3&text=${Uri.encodeComponent(text)}',
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Web: blob URL로 오디오 재생
        if (kIsWeb) {
          await _playBytesWeb(response.bodyBytes);
        } else {
          // Mobile: 임시 파일 저장 후 재생 (flutter_tts 대신 audioplayers 추가 시)
          // 현재는 flutter_tts 폴백
          _isPlaying = false;
          _currentText = null;
          notifyListeners();
          await _tts.speak(text);
        }
      } else {
        debugPrint('[TTS] Clova API error: ${response.statusCode}');
        await _tts.speak(text);
      }
    } catch (e) {
      debugPrint('[TTS] Clova error: $e');
      _isPlaying = false;
      _currentText = null;
      notifyListeners();
      await _tts.speak(text);
    }
  }

  /// Web 환경에서 오디오 bytes 재생 (JS interop)
  Future<void> _playBytesWeb(Uint8List bytes) async {
    if (!kIsWeb) return;
    try {
      // dart:html은 deprecated이므로 패키지 없이 간단히 처리
      // audioplayers 패키지 없이 flutter_tts 폴백
      _isPlaying = false;
      _currentText = null;
      notifyListeners();
      // Web에서 클로바 바이트 직접 재생은 audioplayers 패키지 필요
      // 현재는 TTS 폴백
      await _tts.speak(_currentText ?? '');
    } catch (e) {
      debugPrint('[TTS] Web audio error: $e');
    }
  }

  Future<void> stop() async {
    await _tts.stop();
    _isPlaying = false;
    _currentText = null;
    notifyListeners();
  }

  Future<void> setSpeed(double speed) async {
    _speed = speed.clamp(0.5, 2.0);
    // flutter_tts 업데이트 (클로바는 speak 시 적용)
    await _tts.setSpeechRate(_speed * 0.5);
    notifyListeners();
  }

  bool isReadingText(String text) => _isPlaying && _currentText == text;
}
