import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'analytics_service.dart';
import 'auth_service.dart';

/// RevenueCat 상품 ID
class ProductIds {
  static const String proMonthly      = 'mathbot_pro_monthly';
  static const String premiumMonthly  = 'mathbot_premium_monthly';
  static const String proYearly       = 'mathbot_pro_yearly';
  static const String premiumYearly   = 'mathbot_premium_yearly';

  // RevenueCat Entitlement ID
  static const String entitlementPro     = 'pro';
  static const String entitlementPremium = 'premium';

  static const Map<String, int> yearlyPrices = {
    'mathbot_pro_yearly':     65000,
    'mathbot_premium_yearly': 99000,
  };

  static int yearlyToMonthlyEquivalent(String productId) {
    return ((yearlyPrices[productId] ?? 0) / 12).round();
  }

  static int yearlySavingsPercent(String productId) {
    final monthlyPrice = productId == proYearly ? 9900 : 15900;
    final yearlyPrice = yearlyPrices[productId] ?? 0;
    if (yearlyPrice == 0) return 0;
    return (((monthlyPrice * 12 - yearlyPrice) / (monthlyPrice * 12)) * 100).round();
  }
}

enum PlanTier { free, pro, premium }

class PurchaseService extends ChangeNotifier {
  static final PurchaseService _instance = PurchaseService._();
  factory PurchaseService() => _instance;
  PurchaseService._();

  // RevenueCat API 키 (빌드 시 주입)
  // --dart-define=RC_APPLE_KEY=appl_xxx   (iOS)
  // --dart-define=RC_GOOGLE_KEY=goog_xxx  (Android)
  static const _rcAppleKey  = String.fromEnvironment('RC_APPLE_KEY',  defaultValue: '');
  static const _rcGoogleKey = String.fromEnvironment('RC_GOOGLE_KEY', defaultValue: '');

  PlanTier _tier = PlanTier.free;
  bool _loading = false;
  String? _error;
  List<Package> _packages = [];

  // 관리자 이메일 — 항상 PRO 전체 기능 사용 가능
  static const _adminEmails = ['aiwx2035@gmail.com'];
  static bool _isAdmin() {
    final email = AuthService().user?.email ?? '';
    return _adminEmails.contains(email);
  }

  PlanTier get tier    => _isAdmin() ? PlanTier.premium : _tier;
  bool get loading     => _loading;
  String? get error    => _error;
  bool get isPro       => _isAdmin() || _tier == PlanTier.pro || _tier == PlanTier.premium;
  bool get isPremium   => _isAdmin() || _tier == PlanTier.premium;
  List<Package> get packages => _packages;

  Future<void> init() async {
    // 웹: RevenueCat 미지원 → SharedPreferences 로드만
    await _loadTierFromPrefs();
    if (kIsWeb) return;

    final apiKey = defaultTargetPlatform == TargetPlatform.iOS
        ? _rcAppleKey
        : _rcGoogleKey;

    if (apiKey.isEmpty) {
      debugPrint('[Purchase] RevenueCat API key not set — using prefs only');
      return;
    }

    try {
      await Purchases.setLogLevel(LogLevel.warn);
      final config = PurchasesConfiguration(apiKey);
      await Purchases.configure(config);
      await _syncWithRevenueCat();
      _loadOfferings();
    } catch (e) {
      debugPrint('[Purchase] RevenueCat init error: $e');
    }
  }

  Future<void> _syncWithRevenueCat() async {
    try {
      final info = await Purchases.getCustomerInfo();
      _applyEntitlements(info);
    } catch (e) {
      debugPrint('[Purchase] sync error: $e');
    }
  }

  Future<void> _loadOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current != null) {
        _packages = current.availablePackages;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[Purchase] loadOfferings error: $e');
    }
  }

  /// 구매
  Future<void> buy(Package package) async {
    if (kIsWeb) return;
    _loading = true;
    _error = null;
    notifyListeners();

    AnalyticsService().purchaseStarted(package.storeProduct.identifier);

    try {
      final result = await Purchases.purchasePackage(package);
      _applyEntitlements(result);
      AnalyticsService().purchaseCompleted(
        package.storeProduct.identifier,
        plan: _tier.name,
      );
    } on PurchasesErrorCode catch (e) {
      if (e != PurchasesErrorCode.purchaseCancelledError) {
        _error = e.toString();
        AnalyticsService().purchaseFailed(
          package.storeProduct.identifier,
          reason: e.toString(),
        );
      }
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  /// 구매 복원
  Future<void> restore() async {
    if (kIsWeb) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final info = await Purchases.restorePurchases();
      _applyEntitlements(info);
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  void _applyEntitlements(CustomerInfo info) {
    final entitlements = info.entitlements.active;
    PlanTier newTier = PlanTier.free;
    if (entitlements.containsKey(ProductIds.entitlementPremium)) {
      newTier = PlanTier.premium;
    } else if (entitlements.containsKey(ProductIds.entitlementPro)) {
      newTier = PlanTier.pro;
    }
    _saveTier(newTier);
  }

  Future<void> _saveTier(PlanTier tier) async {
    _tier = tier;
    _loading = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('plan_tier', tier.name);
    AnalyticsService().setUserProperties(plan: tier.name);
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

  /// 무료 체험 가능 여부
  static Future<bool> checkFreeTrialAvailable() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('free_trial_used') ?? false);
  }

  static Future<void> startFreeTrial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('free_trial_used', true);
    await prefs.setString('free_trial_start', DateTime.now().toIso8601String());
    AnalyticsService().freeTrialStarted();
  }

  static Future<int> trialDaysRemaining() async {
    final prefs = await SharedPreferences.getInstance();
    final startStr = prefs.getString('free_trial_start');
    if (startStr == null) return 7;
    final start = DateTime.parse(startStr);
    final elapsed = DateTime.now().difference(start).inDays;
    return (7 - elapsed).clamp(0, 7);
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
