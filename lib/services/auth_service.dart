import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// 소셜 로그인 서비스
///
/// 전략: 소셜 인증 → 프로필 로컬 저장 (SharedPreferences)
/// 추후 Firebase Auth 또는 백엔드 연동 가능
class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;
  AuthService._();

  static const _prefKey = 'auth_user';

  AuthUser? _user;
  bool _loading = false;

  AuthUser? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get loading => _loading;

  /// 앱 시작 시 저장된 로그인 정보 복원
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_prefKey);
      if (json != null) {
        _user = AuthUser.fromJson(jsonDecode(json) as Map<String, dynamic>);
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Google 로그인
  Future<AuthUser?> signInWithGoogle() async {
    _loading = true;
    notifyListeners();
    try {
      final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      final account = await googleSignIn.signIn();
      if (account == null) {
        _loading = false;
        notifyListeners();
        return null;
      }
      final u = AuthUser(
        uid: account.id,
        name: account.displayName ?? '사용자',
        email: account.email,
        photoUrl: account.photoUrl,
        provider: 'google',
      );
      await _save(u);
      return u;
    } catch (e) {
      debugPrint('[Auth] Google sign-in error: $e');
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Apple 로그인 (iOS/macOS/Web)
  Future<AuthUser?> signInWithApple() async {
    _loading = true;
    notifyListeners();
    try {
      final cred = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final name = [
            cred.givenName,
            cred.familyName,
          ].where((s) => s != null && s.isNotEmpty).join(' ')
          .trim();
      final u = AuthUser(
        uid: cred.userIdentifier ?? 'apple_user',
        name: name.isEmpty ? 'Apple 사용자' : name,
        email: cred.email ?? '',
        photoUrl: null,
        provider: 'apple',
      );
      await _save(u);
      return u;
    } catch (e) {
      debugPrint('[Auth] Apple sign-in error: $e');
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// 게스트 모드
  Future<void> continueAsGuest() async {
    final u = AuthUser(
      uid: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      name: '게스트',
      email: '',
      photoUrl: null,
      provider: 'guest',
    );
    await _save(u);
  }

  Future<void> signOut() async {
    try {
      if (_user?.provider == 'google') {
        await GoogleSignIn().signOut();
      }
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
    _user = null;
    notifyListeners();
  }

  Future<void> _save(AuthUser u) async {
    _user = u;
    _loading = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, jsonEncode(u.toJson()));
    notifyListeners();
  }

  /// Apple Sign-In 지원 여부 (iOS/macOS/Web)
  static Future<bool> get isAppleSignInAvailable async {
    if (kIsWeb) return false; // 웹은 Apple 미지원
    try {
      return await SignInWithApple.isAvailable();
    } catch (_) {
      return false;
    }
  }
}

class AuthUser {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String provider; // 'google' | 'apple' | 'guest'

  const AuthUser({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.provider,
  });

  bool get isGuest => provider == 'guest';

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'provider': provider,
      };

  factory AuthUser.fromJson(Map<String, dynamic> j) => AuthUser(
        uid: j['uid'] as String,
        name: j['name'] as String,
        email: j['email'] as String,
        photoUrl: j['photoUrl'] as String?,
        provider: j['provider'] as String,
      );
}
