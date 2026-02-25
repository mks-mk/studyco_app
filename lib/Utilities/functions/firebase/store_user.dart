import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_storage/get_storage.dart';
import '../deviceid.dart';

Future<void> addUser({
  required String name,
  required String number,
  required String email,
  required String profile,
  required String uid,
  required bool isNew,
}) async {
  try {
    if (isNew) {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': name,
        'number': number,
        'profile': profile,
        'email': email,
        'joined': FieldValue.serverTimestamp(),
        'deviceId': await getDeviceId(),
        'isRestricted': false,
        'education': {
          'class': 'not provided',
          'course': 'not provided',
          'stream': 'not provided',
        },
      });
    } else {
      try {
        final DocumentSnapshot doc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (doc.exists) {

          final data = doc.data() as Map<String, dynamic>;
          if (data.containsKey('education')) {
            final educationData = data['education'] as Map<String, dynamic>;
            if(educationData['class'] == 1){
              GetStorage().write(
                'class',
                "${educationData['course']}_A",
              );
              GetStorage().write('sem', "S${educationData['class']}");
            }else{
              GetStorage().write(
                'class',
                "${educationData['course']}_${educationData['stream']}",
              );
              GetStorage().write('sem', "S${educationData['class']}");
            }
          }
        }
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'joined': FieldValue.serverTimestamp(),
          'deviceId': await getDeviceId(),
        });
      } catch (e) {
        print('Error fetching education: $e');
      }
    }
    print('User added');
  } catch (e) {
    print('Error adding user: $e');
  }
}
