import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart'; // ADD THIS IMPORT
import 'package:firebase_auth/firebase_auth.dart'; // ADD THIS IMPORT
import 'package:studyco_app/pages/carts/payment_after_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../controllers/cart/cart_controller.dart';
import '../../controllers/profile/profileController.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late Razorpay _razorpay;
  bool _isProcessingPayment = false;
  final UserProfileController profileController = Get.find<UserProfileController>();

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  // ADD: Store purchase in Firestore using Cloud Function
  Future<void> _storePurchaseInFirestore(
      PaymentSuccessResponse response,
      CartController cartController,
      ) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('No authenticated user found');
        return;
      }

      // Group materials by subject
      final Map<String, List<String>> materialsBySubject = {};

      for (final item in cartController.cartItems) {
        if (!materialsBySubject.containsKey(item.subject)) {
          materialsBySubject[item.subject] = [];
        }
        materialsBySubject[item.subject]!.add(item.materialId);
      }

      print('Storing purchases for ${materialsBySubject.length} subjects');

      // Call cloud function for each subject
      for (final entry in materialsBySubject.entries) {
        final subject = entry.key;
        final materialIds = entry.value;

        try {
          final callable = FirebaseFunctions.instance.httpsCallable(
            'storePurchaseAfterPaymentV2',
          );

          // FIXED: Ensure data is properly structured
          final requestData = <String, dynamic>{
            'userUid': currentUser.uid,
            'subject': subject,
            'materialIds': materialIds,
            'orderId': response.orderId ?? '',
            'paymentId': response.paymentId ?? '',
            'totalAmount': cartController.totalPrice,
          };

          print('Calling cloud function with data: $requestData');
          print('Data types:');
          print('userUid type: ${requestData['userUid'].runtimeType}');
          print('subject type: ${requestData['subject'].runtimeType}');
          print('materialIds type: ${requestData['materialIds'].runtimeType}');
          print('orderId type: ${requestData['orderId'].runtimeType}');

          final result = await callable.call(requestData);

          print('Purchase stored for $subject: ${result.data}');

        } catch (subjectError) {
          print('Error storing purchase for $subject: $subjectError');
        }
      }

      print('All purchases processed successfully');

    } catch (e) {
      print('Error in _storePurchaseInFirestore: $e');
    }
  }



  // UPDATED: Handle payment success with cloud function integration
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    setState(() {
      _isProcessingPayment = false;
    });

    print('Payment Success: \nPayment ID: ${response.paymentId}');
    print('Order ID: ${response.orderId}');
    print('Signature: ${response.signature}');

    final cartController = Get.find<CartController>();

    // Store purchase in Firestore using Cloud Function
    _storePurchaseInFirestore(response, cartController);

    cartController.clearCart();

    Get.to(()=>PurchaseSuccessPage(
      paymentId: response.paymentId ?? 'N/A',
      orderId: response.orderId ?? 'N/A',
    ));
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() {
      _isProcessingPayment = false;
    });
    Get.snackbar("Payment failed", "Your payment attempt was unsuccessful. please try again",icon: Icon(Icons.error_outline_rounded,color: Colors.white,),backgroundColor: Colors.red,colorText: Colors.white);

    print('Payment Error: ${response.code} - ${response.message}');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() {
      _isProcessingPayment = false;
    });

    Get.snackbar(
      'External Wallet',
      'Selected wallet: ${response.walletName}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );

    print('External Wallet: ${response.walletName}');
  }

  Future<String?> _createOrder(double amount) async {
    try {
      final dio = Dio();

      // Razorpay credentials
      final keyId = dotenv.env['RAZORPAY_KEY_ID'] ?? '';
      final keySecret = dotenv.env['RAZORPAY_KEY_SECRET'] ?? '';
      final credentials = base64Encode(utf8.encode('$keyId:$keySecret'));

      // Order data matching Razorpay API format
      final orderData = {
        'amount': (amount * 100).toInt(), // Amount in paise
        'currency': 'INR',
        'receipt': 'receipt_${DateTime.now().millisecondsSinceEpoch}',
        'notes': {
          'user_id': profileController.deviceId.value,
          'user_email': profileController.email.value,
          'app_name': 'studyco',
        }
      };

      final response = await dio.post(
        'https://api.razorpay.com/v1/orders',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Basic $credentials',
          },
        ),
        data: orderData,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        print('Order created successfully:');
        print('Order ID: ${data['id']}');
        print('Amount: ${data['amount']}');
        print('Currency: ${data['currency']}');
        print('Status: ${data['status']}');
        print('Receipt: ${data['receipt']}');
        print('Created at: ${data['created_at']}');

        return data['id']; // Return the order ID
      } else {
        print('Error creating order: ${response.data}');
        return null;
      }
    } on DioException catch (e) {
      print('Dio Error creating order: ${e.message}');
      print('Response data: ${e.response?.data}');
      print('Status code: ${e.response?.statusCode}');

      // Handle specific error cases
      if (e.response?.statusCode == 401) {
        print('Authentication failed. Please check your Razorpay credentials.');
      } else if (e.response?.statusCode == 400) {
        print('Bad request. Please check the order data format.');
      }

      return null;
    } catch (e) {
      print('General Error creating order: ${e.toString()}');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final CartController cartController = Get.find<CartController>();

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topLeft,
          radius: 1.6,
          colors: [Color(0xFFDDCFAF), Color(0xFFFFFFFF)],
          stops: [0.05, 0.80],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Get.back(),
          ),
          title: Obx(() => Text(
            'My Cart (${cartController.cartItemCount})',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          )),
          actions: [
            Obx(() => cartController.cartItemCount > 0
                ? IconButton(
              icon: Icon(Icons.delete_sweep, color: Colors.red),
              onPressed: () => _showClearCartDialog(cartController),
            )
                : SizedBox.shrink()),
          ],
        ),
        body: SafeArea(
          child: Obx(() {
            if (cartController.cartItemCount == 0) {
              return _buildEmptyCart();
            }

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: cartController.cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartController.cartItems[index];
                      return _buildCartItem(item, cartController);
                    },
                  ),
                ),

                _buildCartSummary(cartController),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'Your Cart is Empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add some materials to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFFBB00),
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Text(
              'Browse Materials',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item, CartController cartController) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: item.thumbnail,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: Icon(Icons.image, color: Colors.grey[600]),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: Icon(_getTypeIcon(item.type), color: Colors.grey[600]),
                  ),
                ),
              ),
            ),

            SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFFFFBB00),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.subject,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.type,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${item.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFBB00),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showRemoveDialog(item, cartController),
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummary(CartController cartController) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Items:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${cartController.cartItemCount}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFBB00),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '₹${cartController.totalPrice.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFBB00),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isProcessingPayment ? null : () => _proceedToCheckout(cartController),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFFBB00),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isProcessingPayment
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Processing...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payment, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Proceed to Buy',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRemoveDialog(CartItem item, CartController cartController) {
    Get.dialog(
      AlertDialog(
        title: Text('Remove Item'),
        content: Text('Remove "${item.title}" from cart?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              cartController.removeFromCart(item.materialId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog(CartController cartController) {
    Get.dialog(
      AlertDialog(
        title: Text('Clear Cart'),
        content: Text('Remove all items from cart?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              cartController.clearCart();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _proceedToCheckout(CartController cartController) async {
    setState(() {
      _isProcessingPayment = true;
    });

    try {
      final totalAmount = cartController.totalPrice;

      // Create order first
      final orderId = await _createOrder(totalAmount);

      if (orderId == null) {
        setState(() {
          _isProcessingPayment = false;
        });
        Get.snackbar(
          'Error',
          'Failed to create order. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Open Razorpay checkout with order ID
      var options = {
        'key': dotenv.env['RAZORPAY_KEY_ID'] ?? '',
        'amount': (totalAmount * 100).toInt(),
        'name': 'studyco.',
        'description': 'Purchase of ${cartController.cartItemCount} study materials from studyco.',
        'order_id': orderId,
        'prefill': {
          'contact': profileController.number.value,
          'email': profileController.email.value,
        },
        'external': {
          'wallets': ['paytm']
        },
        'theme': {
          'color': '#1E90FF'
        },
      };
      print(profileController.number.value);
      _razorpay.open(options);
    } catch (e) {
      setState(() {
        _isProcessingPayment = false;
      });

      Get.snackbar(
        'Error',
        'Payment initialization failed: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );

      print('Payment error: ${e.toString()}');
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'video':
        return Icons.video_library;
      case 'audio':
        return Icons.audiotrack;
      default:
        return Icons.description;
    }
  }
}
