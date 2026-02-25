import 'dart:async';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// A singleton service to manage all in-app purchase logic
class InAppPurchaseService extends GetxController {
  static InAppPurchaseService get instance => Get.find();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  // Keep track of available products and loading status
  final RxBool storeIsAvailable = false.obs;
  final RxBool isStoreLoading = true.obs;
  final RxList<ProductDetails> products = <ProductDetails>[].obs;
  final RxList<PurchaseDetails> purchases = <PurchaseDetails>[].obs;

  String? _currentPurchaseSubject;

  @override
  void onInit() {
    super.onInit();
    final Stream<List<PurchaseDetails>> purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      // Handle errors here.
      print("Purchase stream error: $error");
    });

    initStoreInfo();
  }

  @override
  void onClose() {
    _subscription.cancel();
    super.onClose();
  }

  // Initialize the store and load products
  Future<void> initStoreInfo() async {
    isStoreLoading.value = true;
    final bool isAvailable = await _inAppPurchase.isAvailable();
    storeIsAvailable.value = isAvailable;

    if (!isAvailable) {
      isStoreLoading.value = false;
      print("In-app purchases not available.");
      return;
    }

    // TODO: Replace this with your actual product IDs from Google Play Console
    const Set<String> _kProductIds = <String>{
      'your_product_id_1',
      'your_product_id_2',
      'another_premium_material',
    };

    final ProductDetailsResponse productDetailResponse =
    await _inAppPurchase.queryProductDetails(_kProductIds);

    if (productDetailResponse.error != null) {
      print("Failed to load products: ${productDetailResponse.error!.message}");
      isStoreLoading.value = false;
      return;
    }

    if (productDetailResponse.productDetails.isEmpty) {
      print("No products found.");
    }

    products.assignAll(productDetailResponse.productDetails);
    isStoreLoading.value = false;
  }

  // ADDED: Set context before initiating a purchase
  void setPurchaseContext(String subject) {
    _currentPurchaseSubject = subject;
  }

  // Trigger the purchase flow for a specific product
  Future<void> buyProduct(ProductDetails productDetails) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
    await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
  }

  // Handle updates from the purchase stream
  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
      } else {
        if (Get.isDialogOpen ?? false) Get.back(); // Close any pending dialog

        if (purchaseDetails.status == PurchaseStatus.error) {
          _handleError(purchaseDetails.error!);
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          // UPDATED: Call the new handler
          _handleSuccessfulPurchase(purchaseDetails);
        }
      }

      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  void _handleError(IAPError error) {
    Get.snackbar(
      'Purchase Error',
      error.message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  // UPDATED: This method now contains the same logic as your cart page
  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('No authenticated user found');
        Get.snackbar('Error', 'You must be logged in to make a purchase.');
        return;
      }

      if (_currentPurchaseSubject == null) {
        print('Error: Purchase context (subject) not set.');
        Get.snackbar('Error', 'An internal error occurred. Please try again.');
        return;
      }

      // Find the product details to get the price
      final product = products.firstWhere((p) => p.id == purchaseDetails.productID);

      final callable = FirebaseFunctions.instance.httpsCallable('storePurchaseAfterPaymentV2');

      final requestData = <String, dynamic>{
        'userUid': currentUser.uid,
        'subject': _currentPurchaseSubject,
        'materialIds': [purchaseDetails.productID], // The ID of the purchased item
        'orderId': purchaseDetails.purchaseID ?? '', // Using purchaseID as the order identifier
        'paymentId': purchaseDetails.purchaseID ?? '', // And as the payment identifier
        'totalAmount': product.rawPrice, // The price from the product details
      };

      print('Calling cloud function with data: $requestData');
      await callable.call(requestData);

      Get.snackbar(
        'Purchase Successful!',
        'You now have access to the material.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

    } catch (e) {
      print('Error storing purchase via cloud function: $e');
      Get.snackbar(
        'Purchase Error',
        'There was an issue verifying your purchase. Please contact support.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      // Clear the context after processing
      _currentPurchaseSubject = null;
    }
  }
}
