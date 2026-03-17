import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 학습 리마인더 알림 서비스
///
/// - SharedPreferences에 설정 저장
/// - 앱 오픈 시 당일 알림 여부 확인
/// - Web: 브라우저 Notification API 사용 (권한 요청 필요)
/// - Mobile: 향후 flutter_local_notifications 연동 예정
class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  static const _keyEnabled = 'notif_enabled';
  static const _keyHour = 'notif_hour';
  static const _keyMinute = 'notif_minute';
  static const _keyLastShown = 'notif_last_shown';

  bool _enabled = false;
  int _hour = 20; // 오후 8시 기본
  int _minute = 0;

  bool get enabled => _enabled;
  int get hour => _hour;
  int get minute => _minute;

  String get timeLabel {
    final h = _hour.toString().padLeft(2, '0');
    final m = _minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_keyEnabled) ?? false;
    _hour = prefs.getInt(_keyHour) ?? 20;
    _minute = prefs.getInt(_keyMinute) ?? 0;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, value);
    notifyListeners();
  }

  Future<void> setTime(int hour, int minute) async {
    _hour = hour;
    _minute = minute;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyHour, hour);
    await prefs.setInt(_keyMinute, minute);
    notifyListeners();
  }

  /// 앱 오픈 시 오늘 알림을 보여줄 시간인지 확인
  Future<bool> shouldShowReminder() async {
    if (!_enabled) return false;
    final now = DateTime.now();
    if (now.hour != _hour || now.minute != _minute) return false;

    final prefs = await SharedPreferences.getInstance();
    final lastShown = prefs.getString(_keyLastShown);
    final todayKey = '${now.year}-${now.month}-${now.day}';
    if (lastShown == todayKey) return false;

    await prefs.setString(_keyLastShown, todayKey);
    return true;
  }

  /// 웹 브라우저 알림 권한 요청 (kIsWeb 체크 후 호출)
  Future<void> requestWebPermission() async {
    if (!kIsWeb) return;
    // 웹 브라우저 Notification API는 JS 인터롭으로 처리
    // 실제 운영 환경에서는 service worker + Push API 연동
    debugPrint('[NotificationService] Web notification permission requested');
  }
}
