import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// 인증 서비스 — SecureStorage + Firebase Auth 완전 연동
///
/// 보안 원칙:
///  - 민감 정보(uid, email, token) → FlutterSecureStorage (AES-256 암호화)
///  - Firebase Auth 세션 기반 자동 토큰 갱신
///  - Google/Apple → Firebase credential로 통합 관리
class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;
  AuthService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  static const _userKey = 'auth_user_v2';

  final _firebaseAuth = FirebaseAuth.instance;

  AuthUser? _user;
  bool _loading = false;

  AuthUser? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get loading => _loading;

  /// 앱 시작 시 Firebase Auth 상태 + 로컬 캐시 복원
  Future<void> load() async {
    try {
      // Firebase 세션 우선
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null) {
        await firebaseUser.reload(); // 토큰 갱신
        _user = AuthUser.fromFirebase(firebaseUser);
        notifyListeners();
        return;
      }
      // 게스트 모드: 로컬 캐시에서 복원
      final json = await _storage.read(key: _userKey);
      if (json != null) {
        final decoded = jsonDecode(json) as Map<String, dynamic>;
        if (decoded['provider'] == 'guest') {
          _user = AuthUser.fromJson(decoded);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('[Auth] load error: $e');
    }
  }

  /// Google 로그인 → Firebase Auth 연동
  Future<AuthUser?> signInWithGoogle() async {
    _setLoading(true);
    try {
      final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      final account = await googleSignIn.signIn();
      if (account == null) { _setLoading(false); return null; }

      final googleAuth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final firebaseUser = userCredential.user!;

      final u = AuthUser.fromFirebase(firebaseUser,
          provider: 'google', photoUrl: account.photoUrl);
      await _saveLocal(u);
      return u;
    } catch (e) {
      debugPrint('[Auth] Google sign-in error: $e');
      _setLoading(false);
      rethrow;
    }
  }

  /// Apple 로그인 → Firebase Auth 연동 (iOS/macOS)
  Future<AuthUser?> signInWithApple() async {
    _setLoading(true);
    try {
      final cred = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: cred.identityToken,
        accessToken: cred.authorizationCode,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(oauthCredential);
      final firebaseUser = userCredential.user!;

      final displayName = [cred.givenName, cred.familyName]
          .where((s) => s != null && s.isNotEmpty)
          .join(' ')
          .trim();

      if (displayName.isNotEmpty &&
          (firebaseUser.displayName == null ||
              firebaseUser.displayName!.isEmpty)) {
        await firebaseUser.updateDisplayName(displayName);
      }

      final u = AuthUser.fromFirebase(
        await _firebaseAuth.currentUser!..reload() == null
            ? firebaseUser
            : _firebaseAuth.currentUser!,
        provider: 'apple',
      );
      await _saveLocal(u);
      return u;
    } catch (e) {
      debugPrint('[Auth] Apple sign-in error: $e');
      _setLoading(false);
      rethrow;
    }
  }

  /// 게스트 모드 (SecureStorage에만 저장)
  Future<void> continueAsGuest() async {
    final u = AuthUser(
      uid: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      name: '게스트',
      email: '',
      photoUrl: null,
      provider: 'guest',
    );
    await _saveLocal(u);
  }

  Future<void> signOut() async {
    try {
      if (_user?.provider == 'google') {
        await GoogleSignIn().signOut();
      }
      await _firebaseAuth.signOut();
    } catch (_) {}
    await _storage.delete(key: _userKey);
    _user = null;
    notifyListeners();
  }

  Future<void> _saveLocal(AuthUser u) async {
    _user = u;
    _loading = false;
    // 게스트는 SecureStorage, 소셜 로그인은 Firebase 세션이 주 저장소
    if (u.isGuest) {
      await _storage.write(key: _userKey, value: jsonEncode(u.toJson()));
    }
    notifyListeners();
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  static Future<bool> get isAppleSignInAvailable async {
    if (kIsWeb) return false;
    try {
      return await SignInWithApple.isAvailable();
    } catch (_) {
      return false;
    }
  }
}

// ── 사용자 모델 ────────────────────────────────────────────────
class AuthUser {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String provider;

  const AuthUser({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.provider,
  });

  bool get isGuest => provider == 'guest';

  factory AuthUser.fromFirebase(
    User firebaseUser, {
    String provider = 'google',
    String? photoUrl,
  }) =>
      AuthUser(
        uid: firebaseUser.uid,
        name: firebaseUser.displayName ?? '사용자',
        email: firebaseUser.email ?? '',
        photoUrl: photoUrl ?? firebaseUser.photoURL,
        provider: provider,
      );

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
