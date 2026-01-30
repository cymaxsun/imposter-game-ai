import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'dart:io';

class SubscriptionService extends ChangeNotifier {
  static final SubscriptionService _instance = SubscriptionService._internal();

  factory SubscriptionService() {
    return _instance;
  }

  SubscriptionService._internal();

  bool _isPremium = false;
  bool get isPremium => _isPremium;

  bool _isInitialized = false;

  static const String entitlementId = 'Imposter Game Pro';

  Future<void> init() async {
    String apiKey;
    if (Platform.isIOS) {
      // Use test key in debug mode, production key in release
      apiKey = kDebugMode
          ? 'test_eznKKnrUwxKWPRoNFFMyZBlWAPK'
          : 'appl_YOUR_PRODUCTION_KEY_HERE'; // TODO: Replace with production key
    } else {
      throw UnsupportedError('Platform not supported');
    }         

    await Purchases.configure(PurchasesConfiguration(apiKey));
    _isInitialized = true;
    await checkEntitlement();
  }

  Future<void> checkEntitlement() async {
    if (!_isInitialized) return;
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      _isPremium =
          customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint("Error checking entitlement: $e");
    }
  }

  Future<bool> purchasePremium({required PackageType packageType}) async {
    if (!_isInitialized) {
      debugPrint("SubscriptionService not initialized");
      throw Exception("Service not initialized");
    }

    try {
      debugPrint("Fetching offerings...");
      final offerings = await Purchases.getOfferings();
      debugPrint(
        "Offerings fetched: ${offerings.current?.availablePackages.length ?? 0}",
      );

      if (offerings.current != null &&
          offerings.current!.availablePackages.isNotEmpty) {
        final packages = offerings.current!.availablePackages;
        final package = packages.firstWhere(
          (candidate) => candidate.packageType == packageType,
          orElse: () => packages.first,
        );
        debugPrint("Purchasing package: ${package.identifier}");

        final PurchaseResult result = await Purchases.purchase(
          PurchaseParams.package(package),
        );

        _isPremium =
            result.customerInfo.entitlements.all[entitlementId]?.isActive ??
            false;

        debugPrint("Purchase successful. Premium status: $_isPremium");
        notifyListeners();
        return _isPremium;
      } else {
        debugPrint("No offerings available");
        throw Exception("No packages available for purchase");
      }
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint("User cancelled purchase");
        return false;
      }
      debugPrint("Purchase PlatformException: $e");
      throw Exception("Purchase failed: ${e.message}");
    } catch (e) {
      debugPrint("Error purchasing premium: $e");
      throw Exception("Purchase failed: $e");
    }
  }

  Future<void> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      _isPremium =
          customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint("Error restoring purchases: $e");
    }
  }
}
