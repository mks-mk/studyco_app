import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> contactUs() async {
  final DocumentSnapshot doc = await FirebaseFirestore.instance.collection('settings').doc('strings').get();
  String url = doc["contact"] == null || doc["contact"] == "" ? "https://wa.me/+917025977832?text=Hello studyco." : doc["contact"];
  if (await canLaunchUrl(Uri.parse(url))) {
    await launchUrl(
        Uri.parse(url),
      mode: LaunchMode.externalApplication
    );
  } else {
    throw "Could not launch $url";
  }
}

Future<void> sendFeedback() async {
  try {
    final DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('settings')
        .doc('strings')
        .get();

    final String emailAddress = doc["mail"] == null || doc["mail"] == ""
        ? "studyco.eduonline@gmail.com"
        : doc["mail"];

    // Fix: Properly encode both subject and body to avoid + symbols
    final String subject = Uri.encodeComponent("Feedback for studyco. App");
    final String body = Uri.encodeComponent('Dear StudyCo Team,\n\nPlease describe your feedback here:\n\n');

    // Create mailto URL manually to ensure proper encoding
    final String mailtoUrl = 'mailto:$emailAddress?subject=$subject&body=$body';
    final Uri emailLaunchUri = Uri.parse(mailtoUrl);

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(
        emailLaunchUri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      await _showNoEmailClientDialog(emailAddress);
    }
  } catch (e) {
    print('Error fetching email settings: $e');
    await _showErrorDialog(e);
  }
}

Future<void> _showNoEmailClientDialog(String emailAddress) async {
  await Get.defaultDialog(
    title: 'No Email Client',
    middleText: 'Please install an email app or contact us at $emailAddress',
    textConfirm: 'Copy Email',
    textCancel: 'OK',
    onConfirm: () {
      // Copy email to clipboard
      Clipboard.setData(ClipboardData(text: emailAddress));
      Get.back();
      Get.snackbar(
        'Copied',
        'Email address copied to clipboard',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    },
    onCancel: () => Get.back(),
  );
}

Future<void> _showErrorDialog(Object e) async {
  await Get.defaultDialog(
    title: 'Error',
    middleText: 'Could not send feedback. Please try again later.\n\nError: ${e.toString()}',
    textConfirm: 'Retry',
    textCancel: 'Cancel',
    onConfirm: () {
      Get.back();
      sendFeedback(); // Retry the operation
    },
    onCancel: () => Get.back(),
  );
}

// Alternative method if the above still causes issues
Future<void> sendFeedbackAlternative() async {
  try {
    final DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('settings')
        .doc('strings')
        .get();

    final String emailAddress = doc["mail"] == null || doc["mail"] == ""
        ? "studyco.eduonline@gmail.com"
        : doc["mail"];

    // Method 2: Use Uri constructor but fix encoding afterwards
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: emailAddress,
      queryParameters: {
        'subject': 'Feedback for studyco. App',
        'body': 'Dear StudyCo Team,\n\nPlease describe your feedback here:\n\n',
      },
    );

    // Fix the + symbol issue by replacing with %20
    String emailUrl = emailLaunchUri.toString();
    emailUrl = emailUrl.replaceAll('+', '%20');
    final Uri fixedUri = Uri.parse(emailUrl);

    if (await canLaunchUrl(fixedUri)) {
      await launchUrl(
        fixedUri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      await _showNoEmailClientDialog(emailAddress);
    }
  } catch (e) {
    print('Error fetching email settings: $e');
    await _showErrorDialog(e);
  }
}
