import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';
import '../../pages/carts/cart_page.dart';

class CartController extends GetxController {
  static CartController get instance => Get.find();

  final _storage = GetStorage();
  static const String _cartKey = 'cart_items';

  // Observable cart items
  var cartItems = <CartItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadCartFromStorage();
  }

  // Load cart from storage
  void loadCartFromStorage() {
    try {
      final cartData = _storage.read(_cartKey);
      if (cartData != null) {
        final List<dynamic> cartList = cartData;
        cartItems.value = cartList.map((item) => CartItem.fromMap(item)).toList();
      }
    } catch (e) {
      print('Error loading cart: $e');
    }
  }

  // Save cart to storage
  void saveCartToStorage() {
    try {
      final cartData = cartItems.map((item) => item.toMap()).toList();
      _storage.write(_cartKey, cartData);
    } catch (e) {
      print('Error saving cart: $e');
    }
  }

  // Add item to cart
  void addToCart({
    required String materialId,
    required String title,
    required String subject,
    required double price,
    required String thumbnail,
    required String type,
  }) {
    // Check if item already exists
    if (isInCart(materialId)) {
      Get.snackbar(
        'Already in Cart',
        '$title is already in your cart',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: Duration(seconds: 2),
      );
      return;
    }

    final cartItem = CartItem(
      materialId: materialId,
      title: title,
      subject: subject,
      price: price,
      thumbnail: thumbnail,
      type: type,
      addedAt: DateTime.now(),
    );

    cartItems.add(cartItem);
    saveCartToStorage();

    Get.snackbar(
      'Added to Cart',
      '$title added to cart successfully',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: Duration(seconds: 2),
      mainButton: TextButton(
        onPressed: () => Get.to(() => CartPage()),
        child: Text('View Cart', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  // Remove item from cart
  void removeFromCart(String materialId) {
    cartItems.removeWhere((item) => item.materialId == materialId);
    saveCartToStorage();

    Get.snackbar(
      'Removed',
      'Item removed from cart',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: Duration(seconds: 2),
    );
  }

  // Check if item is in cart
  bool isInCart(String materialId) {
    return cartItems.any((item) => item.materialId == materialId);
  }

  // Get cart item count
  int get cartItemCount => cartItems.length;

  // Get total price
  double get totalPrice => cartItems.fold(0.0, (sum, item) => sum + item.price);

  // Clear cart
  void clearCart() {
    cartItems.clear();
    saveCartToStorage();

    Get.snackbar(
      'Cart Cleared',
      'All items removed from cart',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
  }

  // Get cart item by ID
  CartItem? getCartItem(String materialId) {
    try {
      return cartItems.firstWhere((item) => item.materialId == materialId);
    } catch (e) {
      return null;
    }
  }
}

// Cart Item Model
class CartItem {
  final String materialId;
  final String title;
  final String subject;
  final double price;
  final String thumbnail;
  final String type;
  final DateTime addedAt;

  CartItem({
    required this.materialId,
    required this.title,
    required this.subject,
    required this.price,
    required this.thumbnail,
    required this.type,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'materialId': materialId,
      'title': title,
      'subject': subject,
      'price': price,
      'thumbnail': thumbnail,
      'type': type,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      materialId: map['materialId'] ?? '',
      title: map['title'] ?? '',
      subject: map['subject'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      thumbnail: map['thumbnail'] ?? '',
      type: map['type'] ?? '',
      addedAt: DateTime.parse(map['addedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
