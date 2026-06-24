import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'dart:async';
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

class _OTPScreenState extends State<OTPScreen> with CodeAutoFill {
  final List<TextEditingController> controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> focusNodes = List.generate(6, (index) => FocusNode());
  String otpCode = '';
  bool isLoading = false;

  // Timer variables
  Timer? _timer;
  int _countdown = 59;
  bool _canResendOTP = false;

  // ✅ Auto-fill variables
  String? _appSignature;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _initializeAutoFill();
  }

  // ✅ Initialize auto-fill functionality
  Future<void> _initializeAutoFill() async {
    try {
      // Get app signature
      _appSignature = await SmsAutoFill().getAppSignature;
      print('App Signature: $_appSignature');

      // Start listening for SMS
      await _startListeningForSMS();
    } catch (e) {
      print('Error initializing auto-fill: $e');
    }
  }

  // ✅ Start listening for SMS
  Future<void> _startListeningForSMS() async {
    try {
      setState(() => _isListening = true);

      await SmsAutoFill().listenForCode();
      print('Started listening for SMS');

      Get.snackbar(
        'Auto-Fill Ready',
        'Waiting for SMS to auto-fill OTP...',
        backgroundColor: Colors.blue.shade100,
        colorText: Colors.blue.shade800,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
        icon: Icon(Icons.sms, color: Colors.blue.shade600),
      );
    } catch (e) {
      print('Error starting SMS listener: $e');
      setState(() => _isListening = false);
    }
  }

  // ✅ Handle auto-filled code
  @override
  void codeUpdated() {
    if (code != null && code!.length == 6) {
      print('Auto-filled code: $code');
      _fillOTPFields(code!);

      Get.snackbar(
        'Auto-Fill Success',
        'OTP auto-filled successfully!',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
        icon: Icon(Icons.check_circle, color: Colors.green.shade600),
      );

      // Auto-verify after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && otpCode.length == 6) {
          _verifyOTP();
        }
      });
    }
  }

  // ✅ Fill OTP fields with auto-detected code
  void _fillOTPFields(String code) {
    for (int i = 0; i < 6 && i < code.length; i++) {
      controllers[i].text = code[i];
    }
    setState(() {
      otpCode = code;
    });
  }

  // ✅ Clear OTP fields
  void _clearOTPFields() {
    for (var controller in controllers) {
      controller.clear();
    }
    setState(() {
      otpCode = '';
    });
  }

  // Start countdown timer
  void _startTimer() {
    setState(() {
      _countdown = 59;
      _canResendOTP = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_countdown > 0) {
            _countdown--;
          } else {
            _canResendOTP = true;
            _timer?.cancel();
          }
        });
      }
    });
  }

  Future<void> _verifyOTP() async {
    if (otpCode.length != 6) return;

    setState(() => isLoading = true);

    try {
      await verifyOTP(
        verificationId: widget.verificationId,
        otp: otpCode,
        phoneNumber: widget.phoneNumber,
      );

      // Stop listening for SMS after successful verification
      SmsAutoFill().unregisterListener();

      Get.snackbar(
        'Success',
        'Phone number verified successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );

    } catch (e) {
      Get.snackbar(
        'Error',
        'Invalid OTP. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _resendOTP() async {
    if (!_canResendOTP || isLoading) return;

    setState(() => isLoading = true);

    try {
      await verifyPhoneNumber(widget.phoneNumber);

      // Clear existing OTP and restart listening
      _clearOTPFields();
      await _startListeningForSMS();

      // Restart timer after successful resend
      _startTimer();

      Get.snackbar(
        'Success',
        'OTP resent successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to resend OTP. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
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

                // Subtitle with auto-fill indicator
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'We Are Sending you an OTP to Verify your Phone Number',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // ✅ Auto-fill status indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isListening ? Colors.blue.shade50 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isListening ? Colors.blue.shade200 : Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isListening ? Icons.sms : Icons.sms_failed,
                            size: 12,
                            color: _isListening ? Colors.blue.shade600 : Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isListening ? 'Auto-fill active' : 'Auto-fill inactive',
                            style: TextStyle(
                              fontSize: 10,
                              color: _isListening ? Colors.blue.shade600 : Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                        // ✅ Glow effect when auto-filling
                        boxShadow: controllers[index].text.isNotEmpty
                            ? [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                            : [],
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


                const SizedBox(height: 18),

                // Enhanced Resend OTP Section with Timer
                Center(
                  child: Column(
                    children: [
                      if (!_canResendOTP)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Resend OTP in ${_countdown}s',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (_canResendOTP)
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: isLoading ? null : _resendOTP,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue.shade400,
                                      Colors.blue.shade600,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isLoading)
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    else
                                      Icon(
                                        Icons.refresh,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isLoading ? 'Sending...' : 'Resend OTP',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Enhanced Verify Button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: GestureDetector(
                    onTap: otpCode.length == 6 && !isLoading ? _verifyOTP : null,
                    child: Container(
                      height: 56,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: otpCode.length == 6 && !isLoading
                            ? LinearGradient(
                          colors: [
                            Color(0xFFDDCFAF),
                            Color(0xFFBFA76F),
                          ],
                        )
                            : LinearGradient(
                          colors: [
                            Colors.grey.shade300,
                            Colors.grey.shade400,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: otpCode.length == 6 && !isLoading
                            ? [
                          BoxShadow(
                            color: Color(0xFFDDCFAF).withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                            : [],
                      ),
                      child: Center(
                        child: isLoading
                            ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                            : Text(
                          'Verify',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: otpCode.length == 6 ? Colors.white : Colors.grey.shade600,
                          ),
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
    // ✅ Clean up auto-fill and timer
    _timer?.cancel();
    SmsAutoFill().unregisterListener();

    for (var controller in controllers) {
      controller.dispose();
    }
    for (var focusNode in focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }
}
