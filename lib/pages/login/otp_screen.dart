import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../Utilities/components/gradient_bt.dart';
import '../../Utilities/functions/firebase/phone_sign_in.dart';

class OTPScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;

  const OTPScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final List<TextEditingController> controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> focusNodes = List.generate(6, (index) => FocusNode());
  String otpCode = '';
  bool isLoading = false;

  Future<void> _verifyOTP() async {
    if (otpCode.length != 6) return;

    setState(() => isLoading = true);

    try {
      await verifyOTP(
        verificationId: widget.verificationId,
        otp: otpCode,
        phoneNumber: widget.phoneNumber,
      );

      // If successful, show success message
      Get.snackbar(
        'Success',
        'Phone number verified successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );


    } catch (e) {
      Get.snackbar(
        'Error',
        'Invalid OTP. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _resendOTP() async {
    setState(() => isLoading = true);
    try {
      await verifyPhoneNumber(widget.phoneNumber);
      Get.snackbar(
        'Success',
        'OTP resent successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to resend OTP. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.6,
          colors: [
            Color(0xFFDDCFAF),
            Color(0xFFFFFFFF),
          ],
          stops: [0.08, 0.80],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(flex: 1),

                // Title
                Text(
                  'OTP Verification',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: Get.height * 0.05,
                    fontFamily: GoogleFonts.leagueSpartan(
                      fontWeight: FontWeight.bold,
                    ).fontFamily,
                  ),
                ),

                // Subtitle
                const Text(
                  'We Are Sending you an OTP to Verify your Phone Number',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 8),

                // Phone Number with Edit Option
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Row(
                    children: [
                      Text(
                        'Edit ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        widget.phoneNumber,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // OTP Input Fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return Container(
                      width: 50,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: controllers[index].text.isNotEmpty
                              ? Colors.blue
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: TextField(
                        controller: controllers[index],
                        focusNode: focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          counterText: '',
                          hintText: 'X',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 24,
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) {
                          setState(() {
                            if (value.isNotEmpty && index < 5) {
                              focusNodes[index + 1].requestFocus();
                            } else if (value.isEmpty && index > 0) {
                              focusNodes[index - 1].requestFocus();
                            }

                            // Update OTP code
                            otpCode = controllers.map((c) => c.text).join();
                          });
                        },
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 12),

                // Didn't Receive Code
                Center(
                  child: TextButton(
                    onPressed: isLoading ? null : _resendOTP,
                    child: Text(
                      "Didn't Receive the Code?",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                GestureDetector(
                  onTap: otpCode.length == 6 && !isLoading ? _verifyOTP : null,
                  child: GradientBG(
                    height: 56,
                    width: double.infinity,
                    child: Center(
                      child: Text(
                        'Verify',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    for (var focusNode in focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }
}