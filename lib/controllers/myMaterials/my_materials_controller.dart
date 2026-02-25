import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyMaterialsController extends GetxController {
  // Observable map to store myMaterials data as arrays
  final RxMap<String, List<String>> myMaterials = <String, List<String>>{}.obs;
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
          // Convert to proper format: Map<String, List<String>>
          final Map<String, List<String>> convertedMaterials = {};

          myMaterialsData.forEach((subject, materialData) {
            if (materialData is List) {
              // Already an array - convert to List<String>
              convertedMaterials[subject] = List<String>.from(materialData);
              print('Subject $subject: Found array with ${materialData.length} materials');
            } else if (materialData is Map) {
              // Convert from old map format {id: id} to array [id]
              convertedMaterials[subject] = List<String>.from(materialData.keys);
              print('Subject $subject: Converted map to array with ${materialData.keys.length} materials');
            } else {
              // Unknown format, create empty array
              convertedMaterials[subject] = <String>[];
              print('Subject $subject: Unknown format, created empty array');
            }
          });

          myMaterials.value = convertedMaterials;
          print('MyMaterials loaded successfully:');
          myMaterials.forEach((subject, materials) {
            print('  $subject: ${materials.length} materials - $materials');
          });
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

  /// Get purchased materials for a specific subject as List<String>
  List<String> getMaterialsBySubject(String subject) {
    final materials = myMaterials[subject] ?? [];
    print('Getting materials for $subject: $materials');
    return materials;
  }

  /// Get all purchased material IDs for a specific subject (alias for getMaterialsBySubject)
  List<String> getMaterialIdsBySubject(String subject) {
    return getMaterialsBySubject(subject);
  }

  /// Check if a specific material is purchased
  bool isMaterialPurchased(String subject, String materialId) {
    final subjectMaterials = myMaterials[subject];
    if (subjectMaterials == null) {
      print('No materials found for subject: $subject');
      return false;
    }

    final isPurchased = subjectMaterials.contains(materialId);
    print('Checking if $materialId is purchased in $subject: $isPurchased');
    return isPurchased;
  }

  /// Get all purchased subjects
  List<String> getPurchasedSubjects() {
    final subjects = myMaterials.keys.toList();
    print('Purchased subjects: $subjects');
    return subjects;
  }

  /// Get total count of purchased materials across all subjects
  int getTotalPurchasedCount() {
    int total = 0;
    for (final subjectMaterials in myMaterials.values) {
      total += subjectMaterials.length;
    }
    print('Total purchased materials count: $total');
    return total;
  }

  /// Get count of purchased materials for a specific subject
  int getPurchasedCountBySubject(String subject) {
    final subjectMaterials = myMaterials[subject] ?? [];
    final count = subjectMaterials.length;
    print('Purchased materials count for $subject: $count');
    return count;
  }

  /// Add a material to purchased list (for local updates)
  void addPurchasedMaterial(String subject, String materialId) {
    if (!myMaterials.containsKey(subject)) {
      myMaterials[subject] = <String>[];
    }

    if (!myMaterials[subject]!.contains(materialId)) {
      myMaterials[subject]!.add(materialId);
      print('Added $materialId to $subject locally');
    }
  }

  /// Add multiple materials to purchased list (for local updates)
  void addPurchasedMaterials(String subject, List<String> materialIds) {
    if (!myMaterials.containsKey(subject)) {
      myMaterials[subject] = <String>[];
    }

    for (final materialId in materialIds) {
      if (!myMaterials[subject]!.contains(materialId)) {
        myMaterials[subject]!.add(materialId);
      }
    }
    print('Added ${materialIds.length} materials to $subject locally');
  }

  /// Remove a material from purchased list (for local updates)
  void removePurchasedMaterial(String subject, String materialId) {
    if (myMaterials.containsKey(subject)) {
      myMaterials[subject]!.remove(materialId);
      print('Removed $materialId from $subject locally');

      // Remove subject if no materials left
      if (myMaterials[subject]!.isEmpty) {
        myMaterials.remove(subject);
        print('Removed empty subject: $subject');
      }
    }
  }

  /// Refresh myMaterials data
  Future<void> refreshMyMaterials() async {
    print('Refreshing myMaterials...');
    await fetchMyMaterials();
  }

  /// Listen to real-time updates of myMaterials
  void startMyMaterialsListener() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    print('Starting myMaterials real-time listener...');

    FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .snapshots()
        .listen((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final myMaterialsData = data['myMaterials'] as Map<String, dynamic>?;

        if (myMaterialsData != null) {
          final Map<String, List<String>> convertedMaterials = {};

          myMaterialsData.forEach((subject, materialData) {
            if (materialData is List) {
              convertedMaterials[subject] = List<String>.from(materialData);
            } else if (materialData is Map) {
              convertedMaterials[subject] = List<String>.from(materialData.keys);
            } else {
              convertedMaterials[subject] = <String>[];
            }
          });

          myMaterials.value = convertedMaterials;
          print('MyMaterials updated via listener');
        } else {
          myMaterials.clear();
          print('MyMaterials cleared via listener');
        }
      }
    }, onError: (error) {
      errorMessage.value = 'MyMaterials listener error: ${error.toString()}';
      print('MyMaterials listener error: $error');
    });
  }

  /// Check if user has any purchased materials
  bool get hasPurchasedMaterials => myMaterials.isNotEmpty;

  /// Get purchased materials in a flat list format with subject info
  List<Map<String, String>> getFlatPurchasedMaterials() {
    final List<Map<String, String>> flatList = [];

    for (final entry in myMaterials.entries) {
      final subject = entry.key;
      final materialIds = entry.value;

      for (final materialId in materialIds) {
        flatList.add({
          'subject': subject,
          'materialId': materialId,
        });
      }
    }

    print('Flat purchased materials list: ${flatList.length} items');
    return flatList;
  }

  /// Get purchased materials grouped by subject with counts
  Map<String, int> getPurchasedMaterialsCounts() {
    final Map<String, int> counts = {};

    myMaterials.forEach((subject, materials) {
      counts[subject] = materials.length;
    });

    return counts;
  }

  /// Check if any materials are purchased for a subject
  bool hasAnyPurchasedMaterials(String subject) {
    final materials = myMaterials[subject];
    return materials != null && materials.isNotEmpty;
  }

  /// Get purchased materials for multiple subjects
  Map<String, List<String>> getPurchasedMaterialsForSubjects(List<String> subjects) {
    final Map<String, List<String>> result = {};

    for (final subject in subjects) {
      if (myMaterials.containsKey(subject)) {
        result[subject] = myMaterials[subject]!;
      }
    }

    return result;
  }

  /// Clear all myMaterials data (for logout)
  void clearMyMaterials() {
    myMaterials.clear();
    errorMessage.value = '';
    print('MyMaterials cleared');
  }

  /// Debug method to print current state
  void debugPrintState() {
    print('=== MyMaterials Controller Debug ===');
    print('Is Loading: ${isLoading.value}');
    print('Error Message: ${errorMessage.value}');
    print('Has Materials: $hasPurchasedMaterials');
    print('Total Count: $getTotalPurchasedCount');
    print('Subjects: ${getPurchasedSubjects()}');

    myMaterials.forEach((subject, materials) {
      print('$subject (${materials.length}): $materials');
    });
    print('=====================================');
  }
}
