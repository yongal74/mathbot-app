import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 구독 상품 ID
class ProductIds {
  static const String pro     = 'mathbot_pro_monthly';
  static const String premium = 'mathbot_premium_monthly';
  static const Set<String> all = {pro, premium};
}

/// Firebase Cloud Functions 검증 서버
class _VerifyServer {
  static const String baseUrl = String.fromEnvironment(
    'VERIFY_SERVER_URL',
    defaultValue: 'https://asia-northeast3-mathbot-csat-tree.cloudfunctions.net',
  );
  static const String apiKey = String.fromEnvironment(
    'VERIFY_API_KEY',
    defaultValue: 'YOUR_API_KEY_HERE',
  );
}

enum PlanTier { free, pro, premium }

class PurchaseService extends ChangeNotifier {
  static final PurchaseService _instance = PurchaseService._();
  factory PurchaseService() => _instance;
  PurchaseService._();

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

  Future<void> init() async {
    // 웹에서는 IAP 미지원 — SharedPreferences 로드만 하고 종료
    await _loadTierFromPrefs();
    if (kIsWeb) return;

    try {
      _available = await InAppPurchase.instance.isAvailable();
    } catch (_) {
      _available = false;
    }
    if (!_available) return;

    _sub = InAppPurchase.instance.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (e) { _error = e.toString(); notifyListeners(); },
    );
    await _loadProducts();
    await InAppPurchase.instance.restorePurchases();
  }

  Future<void> _loadProducts() async {
    try {
      final resp = await InAppPurchase.instance.queryProductDetails(ProductIds.all);
      _products = resp.productDetails;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> buy(String productId) async {
    if (kIsWeb || !_available) return;
    final product = _products.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw Exception('상품을 찾을 수 없습니다: $productId'),
    );
    _loading = true;
    _error = null;
    notifyListeners();
    final param = PurchaseParam(productDetails: product);
    await InAppPurchase.instance.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restore() async {
    if (kIsWeb || !_available) return;
    _loading = true;
    _error = null;
    notifyListeners();
    await InAppPurchase.instance.restorePurchases();
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        _loading = true;
        notifyListeners();
      } else if (purchase.status == PurchaseStatus.purchased ||
                 purchase.status == PurchaseStatus.restored) {
        final valid = await _verifyPurchase(purchase);
        if (valid) await _deliverProduct(purchase);
        if (purchase.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(purchase);
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

  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    if (kDebugMode) return true;
    try {
      final resp = await http.post(
        Uri.parse(
          // iOS vs Android 구분은 verificationData.source로
          purchase.verificationData.source == 'app_store'
              ? '${_VerifyServer.baseUrl}/verifyApple'
              : '${_VerifyServer.baseUrl}/verifyGoogle',
        ),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _VerifyServer.apiKey,
        },
        body: jsonEncode({
          'receiptData': purchase.verificationData.serverVerificationData,
          'purchaseToken': purchase.verificationData.serverVerificationData,
          'productId': purchase.productID,
        }),
      );
      if (resp.statusCode != 200) return false;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return data['valid'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _deliverProduct(PurchaseDetails purchase) async {
    final tier = purchase.productID == ProductIds.premium
        ? PlanTier.premium : PlanTier.pro;
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
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('plan_tier');
      _tier = PlanTier.values.firstWhere(
        (t) => t.name == saved,
        orElse: () => PlanTier.free,
      );
    } catch (_) {}
  }

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

extension PurchaseCheck on PurchaseService {
  bool canAccessConcepts()       => isPro;
  bool canAccessPractice()       => isPro;
  bool canUseUnlimitedNotes()    => isPro;
  bool canUseTts()               => isPro;
  bool canUseCamera()            => isPro;
  int  cameraLimit()             => isPremium ? 100 : (isPro ? 20 : 0);
  bool canAccessWeaknessReport() => isPro;
}
