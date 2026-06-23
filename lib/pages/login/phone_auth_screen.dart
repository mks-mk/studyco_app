import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:studyco_app/Utilities/components/gradient_bt.dart';

import '../../Utilities/functions/firebase/phone_sign_in.dart';

class PhoneNumberAuthScreen extends StatefulWidget {
  const PhoneNumberAuthScreen({super.key});

  @override
  State<PhoneNumberAuthScreen> createState() => _PhoneNumberAuthScreenState();
}

class _PhoneNumberAuthScreenState extends State<PhoneNumberAuthScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController controller = TextEditingController();
  String initialCountry = 'IN';
  PhoneNumber number = PhoneNumber(isoCode: 'IN');
  bool agreedToTerms = true; 
  bool isLoading = false; // Added loading state

  Future<void> _submitPhoneNumber() async {
    if (!agreedToTerms) {
      Get.snackbar('Error', 'Please agree to terms and conditions');
      return;
    }

    if (!formKey.currentState!.validate()) {
      return;
    }

    if (number.phoneNumber == null || number.phoneNumber!.isEmpty) {
      Get.snackbar('Error', 'Please enter a valid phone number');
      return;
    }

    setState(() => isLoading = true);

    try {
      await verifyPhoneNumber(number.phoneNumber!); // Use the function from our auth service
    } catch (e) {
      if (mounted) {
        Get.snackbar('Error', 'Failed to send OTP. Please try again.');
      }
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
          center: Alignment.topLeft,
          radius: 1.6,
          colors: [
            Color(0xFFDDCFAF),
            Color(0xFFFFFFFF),
          ],
          stops: [0.05, 0.80],
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

                // Logo and Title
                Text(
                  'studyco.',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: Get.width * 0.16,
                    fontFamily: GoogleFonts.leagueSpartan(
                      fontWeight: FontWeight.w600,
                    ).fontFamily,
                  ),
                ),

                // Subtitle
                const Text(
                  'Please provide your phone number to\nContinue',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 30),

                // Phone Number Input
                Form(
                  key: formKey,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: InternationalPhoneNumberInput(
                      errorMessage: "Please enter a valid phone number !",
                      onInputChanged: (PhoneNumber number) {
                        this.number = number;
                      },
                      onInputValidated: (bool value) {
                        print('Phone number valid: $value');
                      },
                      textStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                      selectorConfig: SelectorConfig(
                        selectorType: PhoneInputSelectorType.DIALOG,
                        showFlags: true,
                        useEmoji: false,
                        leadingPadding: 0,
                        trailingSpace: false,
                      ),
                      ignoreBlank: false,
                      autoValidateMode: AutovalidateMode.disabled,
                      selectorTextStyle: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      initialValue: number,
                      textFieldController: controller,
                      formatInput: false,
                      keyboardType: const TextInputType.numberWithOptions(
                          signed: true, decimal: true),
                      inputDecoration: const InputDecoration(
                        hintText: '00XX-00XX',
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      onSaved: (PhoneNumber number) {
                        print('On Saved: $number');
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                // Terms and Conditions Checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: agreedToTerms,
                      onChanged: (bool? value) {
                        setState(() {
                          agreedToTerms = value ?? false;
                        });
                      },
                      activeColor: Colors.blue,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text(
                          'By Signing you agree our privacy and policy and Terms of use',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const Spacer(flex: 3),

                GestureDetector(
                  onTap: !isLoading ? _submitPhoneNumber : null,
                  child: GradientBG(
                    height: 56,
                    width: double.infinity,
                    child: Center(
                      child: isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : const Text(
                        'Submit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
    controller.dispose();
    super.dispose();
  }
}