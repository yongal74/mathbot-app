import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 구독 상품 ID — App Store Connect / Google Play Console에서 동일하게 설정
class ProductIds {
  static const String pro     = 'mathbot_pro_monthly';     // 9,900원/월
  static const String premium = 'mathbot_premium_monthly'; // 15,900원/월

  static const Set<String> all = {pro, premium};
}

/// Firebase Cloud Functions 검증 서버 설정
/// firebase deploy --only functions 배포 후 생성되는 URL 입력
class _VerifyServer {
  // Firebase Functions URL — 서울 리전 (asia-northeast3)
  // 형식: https://asia-northeast3-{project-id}.cloudfunctions.net
  static const String baseUrl = String.fromEnvironment(
    'VERIFY_SERVER_URL',
    defaultValue: 'https://asia-northeast3-mathbot-csat-tree.cloudfunctions.net',
  );
  // firebase functions:config:set app.api_key="xxx" 에서 설정한 값
  static const String apiKey = String.fromEnvironment(
    'VERIFY_API_KEY',
    defaultValue: 'YOUR_API_KEY_HERE',
  );
}

/// 구독 등급
enum PlanTier { free, pro, premium }

class PurchaseService extends ChangeNotifier {
  static final PurchaseService _instance = PurchaseService._();
  factory PurchaseService() => _instance;
  PurchaseService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  PlanTier _tier = PlanTier.free;
  bool _available = false;
  bool _loading = false;
  String? _error;

  List<ProductDetails> _products = [];

  PlanTier get tier => _tier;
  bool get available => _available;
  bool get loading => _loading;
  String? get error => _error;
  List<ProductDetails> get products => _products;

  bool get isPro     => _tier == PlanTier.pro || _tier == PlanTier.premium;
  bool get isPremium => _tier == PlanTier.premium;

  /// 앱 시작 시 호출
  Future<void> init() async {
    await _loadTierFromPrefs();
    try {
      _available = await _iap.isAvailable();
    } catch (_) {
      _available = false;
    }
    if (!_available) return;

    _sub = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (e) { _error = e.toString(); notifyListeners(); },
    );

    await _loadProducts();
    await _restorePurchases();
  }

  Future<void> _loadProducts() async {
    final resp = await _iap.queryProductDetails(ProductIds.all);
    _products = resp.productDetails;
    notifyListeners();
  }

  Future<void> _restorePurchases() async {
    await _iap.restorePurchases();
  }

  /// 구매 시작
  Future<void> buy(String productId) async {
    final product = _products.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw Exception('상품을 찾을 수 없습니다: $productId'),
    );
    _loading = true;
    _error = null;
    notifyListeners();

    final param = PurchaseParam(productDetails: product);
    // 구독은 buyNonConsumable (iOS) / subscription (Android) 동일하게 처리
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restore() async {
    _loading = true;
    _error = null;
    notifyListeners();
    await _iap.restorePurchases();
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        _loading = true;
        notifyListeners();
      } else if (purchase.status == PurchaseStatus.purchased ||
                 purchase.status == PurchaseStatus.restored) {
        final valid = await _verifyPurchase(purchase);
        if (valid) {
          await _deliverProduct(purchase);
        }
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      } else if (purchase.status == PurchaseStatus.error) {
        _error = purchase.error?.message ?? '결제 오류가 발생했습니다';
        _loading = false;
        notifyListeners();
      } else if (purchase.status == PurchaseStatus.canceled) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  /// 서버사이드 영수증 검증 (Apple IAP / Google Play)
  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    // 개발 중에는 클라이언트 신뢰 (디버그 모드)
    if (kDebugMode) return true;

    try {
      if (purchase is AppStorePurchaseDetails) {
        return await _verifyApple(purchase);
      } else if (purchase is GooglePlayPurchaseDetails) {
        return await _verifyGoogle(purchase);
      }
      return false;
    } catch (e) {
      debugPrint('[PurchaseService] 검증 오류: $e');
      // 네트워크 오류 시 일시적으로 허용 (로컬에서 만료 체크)
      return false;
    }
  }

  Future<bool> _verifyApple(AppStorePurchaseDetails purchase) async {
    // iOS StoreKit에서 verificationResult로 영수증 데이터 접근
    final skPayment = purchase.skPaymentTransaction;
    if (skPayment == null) return false;

    // transactionReceipt는 deprecated — 서버는 최신 receipt를
    // SKReceiptRefreshRequest로 받아야 함. 현재는 transactionIdentifier 전송
    final resp = await http.post(
      Uri.parse('${_VerifyServer.baseUrl}/verifyApple'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _VerifyServer.apiKey,
      },
      body: jsonEncode({
        'receiptData': purchase.verificationData.serverVerificationData,
        'productId': purchase.productID,
      }),
    );

    if (resp.statusCode != 200) return false;
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return data['valid'] == true;
  }

  Future<bool> _verifyGoogle(GooglePlayPurchaseDetails purchase) async {
    final resp = await http.post(
      Uri.parse('${_VerifyServer.baseUrl}/verifyGoogle'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _VerifyServer.apiKey,
      },
      body: jsonEncode({
        'purchaseToken': purchase.verificationData.serverVerificationData,
        'productId': purchase.productID,
      }),
    );

    if (resp.statusCode != 200) return false;
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return data['valid'] == true;
  }

  Future<void> _deliverProduct(PurchaseDetails purchase) async {
    final tier = purchase.productID == ProductIds.premium
        ? PlanTier.premium
        : PlanTier.pro;
    await _saveTier(tier);
  }

  Future<void> _saveTier(PlanTier tier) async {
    _tier = tier;
    _loading = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('plan_tier', tier.name);
    notifyListeners();
  }

  Future<void> _loadTierFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('plan_tier');
    _tier = PlanTier.values.firstWhere(
      (t) => t.name == saved,
      orElse: () => PlanTier.free,
    );
  }

  /// 개발/테스트용: 플랜 강제 설정
  Future<void> debugSetTier(PlanTier tier) async {
    if (!kDebugMode) return;
    await _saveTier(tier);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

/// 기능별 접근 제어
extension PurchaseCheck on PurchaseService {
  bool canAccessConcepts()      => isPro;
  bool canAccessPractice()      => isPro;
  bool canUseUnlimitedNotes()   => isPro;
  bool canUseTts()              => isPro;
  bool canUseCamera()           => isPro;
  int  cameraLimit()            => isPremium ? 100 : (isPro ? 20 : 0);
  bool canAccessWeaknessReport()=> isPro;
}
