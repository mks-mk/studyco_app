import 'package:cloud_firestore/cloud_firestore.dart';
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
  final Uri emailLaunchUri = Uri(
    scheme: 'mailto',
    path: 'studyco.eduonline@gmail.com',
    queryParameters: {
      'subject': 'Feedback for studyco. App',
      'body': 'Dear StudyCo Team,\n\n',
    },
  );

  try {
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(
        emailLaunchUri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      await _showNoEmailClientDialog();
    }
  } catch (e) {
    await _showErrorDialog(e);
  }
}

Future<void> _showNoEmailClientDialog() async {
  await Get.defaultDialog(
    title: 'No Email Client',
    middleText: 'Please install an email app or contact us at support@yourdomain.com',
    textConfirm: 'OK',
    onConfirm: () => Get.back(),
  );
}

Future<void> _showErrorDialog(Object e) async {
  await Get.defaultDialog(
    title: 'Error',
    middleText: 'Could not send feedback: ${e.toString()}',
    textConfirm: 'OK',
    onConfirm: () => Get.back(),
  );
}