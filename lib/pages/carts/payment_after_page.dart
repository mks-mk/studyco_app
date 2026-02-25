import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/navController.dart';
import '../home/home_screen.dart';

class PurchaseSuccessPage extends StatefulWidget {
  final String paymentId;
  final String orderId;

  const PurchaseSuccessPage({
    super.key,
    required this.paymentId,
    required this.orderId,
  });

  @override
  State<PurchaseSuccessPage> createState() => _PurchaseSuccessPageState();
}

class _PurchaseSuccessPageState extends State<PurchaseSuccessPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final NavbarController navbarController = Get.put(NavbarController());


  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Animated Checkmark Icon
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.shade50,
                  ),
                  child: Image.asset("assets/images/tick_mark.png",height: 80,width: 80,)
                ),
              ),
              const SizedBox(height: 32),
              // Success Message
              const Text(
                'Payment Successful!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E232C),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your materials have been added to your account and are ready for you to explore.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 40),
              // Purchase Details Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Payment ID:', widget.paymentId),
                    const Divider(height: 24),
                    _buildDetailRow('Order ID:', widget.orderId),
                  ],
                ),
              ),
              const Spacer(),
              // Action Buttons
              ElevatedButton(
                onPressed: () {
                  navbarController.selectedIndex.value = 1;
             Get.to(() => HomeScreen());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Go to My Materials', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  // Navigate back to the main home screen
                  Get.back(); // Pop this success page
                  Get.back(); // Pop the checkout page
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: const Text('Back to Home', style: TextStyle(fontSize: 16, color: Colors.black87)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E232C),
            ),
          ),
        ),
      ],
    );
  }
}