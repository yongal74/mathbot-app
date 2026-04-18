import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// 매일 아침 7:00 AM 학습 리마인더 알림 서비스
///
/// - 싱글턴 패턴
/// - SharedPreferences에 'notification_enabled' 키로 ON/OFF 저장
/// - flutter_local_notifications으로 Android + iOS 모두 지원
/// - 매일 7:00 AM에 반복 알림 스케줄
class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  // ── 상수 ──────────────────────────────────────────────────
  static const _keyEnabled = 'notification_enabled'; // 요구사항 키명 그대로
  static const _keyHour = 'notif_hour';
  static const _keyMinute = 'notif_minute';

  static const int _notifId = 1001;
  static const String _channelId = 'daily_reminder';
  static const String _channelName = '눈수학 일일 리마인더';
  static const String _channelDesc = '매일 아침 오늘의 3문제를 알려드립니다';

  // ── 상태 ──────────────────────────────────────────────────
  bool _enabled = false;
  int _hour = 7; // 기본 아침 7시
  int _minute = 0;

  bool get isEnabled => _enabled;
  bool get enabled => _enabled;
  int get hour => _hour;
  int get minute => _minute;

  String get timeLabel {
    final h = _hour.toString().padLeft(2, '0');
    final m = _minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // ── 플러그인 인스턴스 ────────────────────────────────────
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ── 초기화 ────────────────────────────────────────────────

  /// main.dart에서 NotificationService().load() 호출 시 진입점
  Future<void> load() async {
    // SharedPreferences 읽기
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_keyEnabled) ?? false;
    _hour = prefs.getInt(_keyHour) ?? 7;
    _minute = prefs.getInt(_keyMinute) ?? 0;

    // 웹은 flutter_local_notifications 미지원 — 조용히 종료
    if (kIsWeb) {
      notifyListeners();
      return;
    }

    // timezone 데이터 초기화
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    } catch (_) {
      // 시스템 로컬 타임존 사용
    }

    // flutter_local_notifications 초기화
    await _initPlugin();

    // 저장된 설정에 따라 스케줄 복구
    if (_enabled) {
      await scheduleDailyNotification();
    }

    notifyListeners();
  }

  Future<void> _initPlugin() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false, // 권한은 별도로 명시적 요청
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  // ── 권한 요청 ─────────────────────────────────────────────

  /// iOS 알림 권한 요청 (설정 켤 때 호출)
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;

    // iOS
    final iosImpl = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosImpl != null) {
      final granted = await iosImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    // Android 13+ 정확한 알람 권한
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      // POST_NOTIFICATIONS 권한 요청 (Android 13+)
      final notifGranted =
          await androidImpl.requestNotificationsPermission() ?? false;
      // SCHEDULE_EXACT_ALARM 권한 요청 (Android 12+)
      final exactGranted =
          await androidImpl.requestExactAlarmsPermission() ?? false;
      return notifGranted && exactGranted;
    }

    return true;
  }

  // ── 스케줄링 ──────────────────────────────────────────────

  /// 매일 지정 시각(기본 07:00)에 반복 알림 등록
  Future<void> scheduleDailyNotification() async {
    if (kIsWeb) return;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final scheduledTime = _nextInstanceOfTime(_hour, _minute);

    await _plugin.zonedSchedule(
      _notifId,
      '📚 오늘의 3문제',
      '매일 3문제로 1등급! 오늘도 눈수학과 함께해요 👁',
      scheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // 매일 반복
    );

    debugPrint(
        '[NotificationService] 매일 ${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')} 알림 등록 완료');
  }

  /// 다음 지정 시각의 TZDateTime 계산
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    // 이미 지난 시각이면 내일로
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// 등록된 모든 알림 취소
  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
    debugPrint('[NotificationService] 모든 알림 취소');
  }

  // ── 설정 변경 ─────────────────────────────────────────────

  /// 알림 ON/OFF 전환 + 스케줄 동기화
  Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, value);

    if (!kIsWeb) {
      if (value) {
        // 권한 요청 후 스케줄 등록
        await requestPermission();
        await scheduleDailyNotification();
      } else {
        await cancelAll();
      }
    }

    notifyListeners();
  }

  /// 알림 시각 변경 (설정 화면에서 사용)
  Future<void> setTime(int hour, int minute) async {
    _hour = hour;
    _minute = minute;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyHour, hour);
    await prefs.setInt(_keyMinute, minute);

    // 켜진 상태면 새 시각으로 재등록
    if (_enabled && !kIsWeb) {
      await cancelAll();
      await scheduleDailyNotification();
    }

    notifyListeners();
  }
}
