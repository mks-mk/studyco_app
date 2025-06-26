import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyMaterialsController extends GetxController {
  // Observable map to store myMaterials data
  final RxMap<String, Map<String, dynamic>> myMaterials = <String, Map<String, dynamic>>{}.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchMyMaterials();
  }

  /// Fetch myMaterials from user document in Firestore
  Future<void> fetchMyMaterials() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        errorMessage.value = 'User not authenticated';
        return;
      }

      print('Fetching myMaterials for user: ${currentUser.uid}');

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final myMaterialsData = data['myMaterials'] as Map<String, dynamic>?;

        if (myMaterialsData != null) {
          // Convert to proper format: Map<String, Map<String, dynamic>>
          myMaterials.value = myMaterialsData.map((subject, materialIds) {
            if (materialIds is Map<String, dynamic>) {
              return MapEntry(subject, materialIds);
            } else {
              return MapEntry(subject, <String, dynamic>{});
            }
          });

          print('MyMaterials loaded: ${myMaterials.keys.toList()}');
        } else {
          myMaterials.clear();
          print('No myMaterials found for user');
        }
      } else {
        errorMessage.value = 'User document does not exist';
        print('User document does not exist');
      }
    } catch (e) {
      errorMessage.value = 'Failed to fetch myMaterials: ${e.toString()}';
      print('Error fetching myMaterials: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Get purchased materials for a specific subject
  Map<String, dynamic> getMaterialsBySubject(String subject) {
    return myMaterials[subject] ?? {};
  }

  /// Get all purchased material IDs for a specific subject as a list
  List<String> getMaterialIdsBySubject(String subject) {
    final subjectMaterials = myMaterials[subject] ?? {};
    return subjectMaterials.keys.toList();
  }

  /// Check if a specific material is purchased
  bool isMaterialPurchased(String subject, String materialId) {
    final subjectMaterials = myMaterials[subject];
    if (subjectMaterials == null) return false;
    return subjectMaterials.containsKey(materialId);
  }

  /// Get all purchased subjects
  List<String> getPurchasedSubjects() {
    return myMaterials.keys.toList();
  }

  /// Get total count of purchased materials across all subjects
  int getTotalPurchasedCount() {
    int total = 0;
    for (final subjectMaterials in myMaterials.values) {
      total += subjectMaterials.length;
    }
    return total;
  }

  /// Get count of purchased materials for a specific subject
  int getPurchasedCountBySubject(String subject) {
    final subjectMaterials = myMaterials[subject] ?? {};
    return subjectMaterials.length;
  }

  /// Refresh myMaterials data
  Future<void> refreshMyMaterials() async {
    await fetchMyMaterials();
  }

  /// Listen to real-time updates of myMaterials
  void startMyMaterialsListener() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .snapshots()
        .listen((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final myMaterialsData = data['myMaterials'] as Map<String, dynamic>?;

        if (myMaterialsData != null) {
          myMaterials.value = myMaterialsData.map((subject, materialIds) {
            if (materialIds is Map<String, dynamic>) {
              return MapEntry(subject, materialIds);
            } else {
              return MapEntry(subject, <String, dynamic>{});
            }
          });
        } else {
          myMaterials.clear();
        }
      }
    }, onError: (error) {
      errorMessage.value = 'MyMaterials listener error: ${error.toString()}';
      print('MyMaterials listener error: $error');
    });
  }

  /// Check if user has any purchased materials
  bool get hasPurchasedMaterials => myMaterials.isNotEmpty;

  /// Get purchased materials in a flat list format
  List<Map<String, String>> getFlatPurchasedMaterials() {
    final List<Map<String, String>> flatList = [];

    for (final entry in myMaterials.entries) {
      final subject = entry.key;
      final materialIds = entry.value;

      for (final materialId in materialIds.keys) {
        flatList.add({
          'subject': subject,
          'materialId': materialId,
        });
      }
    }

    return flatList;
  }

  /// Clear all myMaterials data (for logout)
  void clearMyMaterials() {
    myMaterials.clear();
    errorMessage.value = '';
  }
}
