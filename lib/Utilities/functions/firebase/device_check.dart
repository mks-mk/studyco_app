import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../deviceid.dart';

Future<bool> deviceCheck({required String userId}) async {
  String? iDeviceId = await getDeviceId();
  try {
    DocumentSnapshot doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (doc.exists) {
      if (doc.get('deviceId') == iDeviceId) {
        return true;
      } else {
        return false;
      }
    } else {
      print('Document does not exist');
      return false;
    }
  } catch (e) {
    print('Error checking device: $e');
  }
  return false;
}

Future<bool> isBanned() async {
  User? user = FirebaseAuth.instance.currentUser;
  try {
    DocumentSnapshot doc =
        await FirebaseFirestore.instance.collection('users').doc(user?.uid).get();

    if (doc.exists) {
      if (doc.get('isRestricted') == true) {
        return true;
      } else {
        return false;
      }
    } else {
      print('Document does not exist');
      return false;
    }
  } catch (e) {
    print('Error checking device: $e');
  }
  return false;
}

Future<void> devicePunch({required bool isNew}) async {
  try {
    String? iDeviceId = await getDeviceId();
    if (isNew) {
      await FirebaseFirestore.instance
          .collection('deviceCheck')
          .doc(iDeviceId)
          .set({
        'LastLogin': FieldValue.serverTimestamp(),
        'isRestricted': false,
      });
    }else{
      await FirebaseFirestore.instance
          .collection('deviceCheck')
          .doc(iDeviceId)
          .update({
        'LastLogin': FieldValue.serverTimestamp(),
      });
    }
    print('Device punched with $iDeviceId');
  } catch (e) {
    print('Error punching device: $e');
  }
  return;
}
