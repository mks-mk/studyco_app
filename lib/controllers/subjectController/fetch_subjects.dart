import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../models/subject_model.dart';

class SubjectController extends GetxController {
  final RxList<SubjectModel> subjects = <SubjectModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  GetStorage storage = GetStorage();

  @override
  void onInit() {
    super.onInit();
    fetchSubjects();
  }

  Future<void> fetchSubjects() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // ✅ Get and clean the stored values
      String? rawCollection = storage.read('class');
      String? rawSemester = storage.read('sem');

      print('Raw storage values - class: "$rawCollection", sem: "$rawSemester"');

      // ✅ Clean and validate the values
      String? collection = rawCollection?.toString().trim();
      String? semester = rawSemester?.toString().trim();

      // ✅ Remove any unwanted characters (like extra braces)
      if (collection != null) {
        collection = collection.replaceAll(RegExp(r'[{}]'), ''); // Remove { and }
        collection = collection.replaceAll(RegExp(r'\s+'), '_'); // Replace spaces with underscore
      }

      if (semester != null) {
        semester = semester.replaceAll(RegExp(r'[{}]'), ''); // Remove { and }
        semester = semester.trim();
      }

      print('Cleaned values - class: "$collection", sem: "$semester"');

      // Validate required data
      if (collection == null || collection.isEmpty) {
        throw Exception('Class information not found or invalid in storage');
      }

      if (semester == null || semester.isEmpty) {
        throw Exception('Semester information not found or invalid in storage');
      }

      print('Attempting to fetch from collection: "$collection", document: "$semester"');

      // ✅ Check if document exists first
      final DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection(collection)
          .doc(semester)
          .get();

      print('Document exists: ${doc.exists}');

      if (!doc.exists) {
        // ✅ List available documents for debugging
        await _listAvailableDocuments(collection);
        throw Exception('Document "$semester" does not exist in collection "$collection"');
      }

      final data = doc.data() as Map<String, dynamic>?;

      if (data == null) {
        throw Exception('Document data is null');
      }

      print('Document data keys: ${data.keys.toList()}');

      if (data.containsKey('Subjects')) {
        final subjectsData = data['Subjects'];
        print('Subjects data type: ${subjectsData.runtimeType}');

        // Clear existing subjects
        subjects.clear();

        if (subjectsData is List) {
          // Handle array format
          print('Processing subjects as List with ${subjectsData.length} items');
          for (int i = 0; i < subjectsData.length; i++) {
            final subjectData = subjectsData[i];
            if (subjectData is Map<String, dynamic>) {
              try {
                final subject = SubjectModel.fromMap(subjectData);
                subjects.add(subject);
                print('Added subject ${i + 1}: ${subject.subjectName}');
              } catch (e) {
                print('Error parsing subject at index $i: $e');
              }
            } else {
              print('Invalid subject data at index $i: ${subjectData.runtimeType}');
            }
          }
        } else if (subjectsData is Map<String, dynamic>) {
          // Handle object format with numbered keys
          print('Processing subjects as Map with ${subjectsData.length} items');
          subjectsData.forEach((key, value) {
            if (value is Map<String, dynamic>) {
              try {
                final subject = SubjectModel.fromMap(value);
                subjects.add(subject);
                print('Added subject "$key": ${subject.subjectName}');
              } catch (e) {
                print('Error parsing subject "$key": $e');
              }
            } else {
              print('Invalid subject data for key "$key": ${value.runtimeType}');
            }
          });
        } else {
          throw Exception('Subjects data is in unexpected format: ${subjectsData.runtimeType}');
        }

        print('Successfully fetched ${subjects.length} subjects');

        if (subjects.isEmpty) {
          Get.snackbar(
            'No Subjects',
            'No subjects found for $collection - $semester',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      } else {
        print('Available fields in document: ${data.keys.toList()}');
        throw Exception('No "Subjects" field found in document. Available fields: ${data.keys.join(", ")}');
      }
    } catch (e) {
      errorMessage.value = e.toString();
      print('Error fetching subjects: $e');

      // ✅ More user-friendly error messages
      String userMessage = 'Failed to load subjects';
      if (e.toString().contains('does not exist')) {
        userMessage = 'Course data not found. Please check your class and semester selection.';
      } else if (e.toString().contains('not found in storage')) {
        userMessage = 'Please select your class and semester first.';
      }

      Get.snackbar(
        'Error',
        userMessage,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ✅ Helper method to list available documents for debugging
  Future<void> _listAvailableDocuments(String collection) async {
    try {
      print('Listing available documents in collection: "$collection"');
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection(collection)
          .limit(10) // Limit to avoid too much output
          .get();

      if (snapshot.docs.isEmpty) {
        print('No documents found in collection "$collection"');

        // ✅ Also list available collections
        await _listAvailableCollections();
      } else {
        final docIds = snapshot.docs.map((doc) => doc.id).toList();
        print('Available documents: ${docIds.join(", ")}');
      }
    } catch (e) {
      print('Error listing documents: $e');
      await _listAvailableCollections();
    }
  }

  // ✅ Helper method to list available collections
  Future<void> _listAvailableCollections() async {
    try {
      // Note: This is a simplified approach. In production, you might want to
      // maintain a list of available collections in a separate document
      final List<String> commonCollections = [
        'BTech_A', 'BTech_B', 'BTech_C',
        'BCA_A', 'BCA_B',
        'MBA_A', 'MBA_B',
        'BSc_A', 'BSc_B'
      ];

      print('Checking common collection names...');
      for (String collectionName in commonCollections) {
        try {
          final snapshot = await FirebaseFirestore.instance
              .collection(collectionName)
              .limit(1)
              .get();
          if (snapshot.docs.isNotEmpty) {
            print('Found collection: "$collectionName"');
          }
        } catch (e) {
          // Collection doesn't exist, continue
        }
      }
    } catch (e) {
      print('Error checking collections: $e');
    }
  }

  // ✅ Method to validate and fix storage values
  Future<void> validateAndFixStorage() async {
    String? rawClass = storage.read('class');
    String? rawSem = storage.read('sem');

    if (rawClass != null) {
      String cleanClass = rawClass.toString().trim().replaceAll(RegExp(r'[{}]'), '');
      if (cleanClass != rawClass) {
        print('Fixing class value from "$rawClass" to "$cleanClass"');
        await storage.write('class', cleanClass);
      }
    }

    if (rawSem != null) {
      String cleanSem = rawSem.toString().trim().replaceAll(RegExp(r'[{}]'), '');
      if (cleanSem != rawSem) {
        print('Fixing semester value from "$rawSem" to "$cleanSem"');
        await storage.write('sem', cleanSem);
      }
    }
  }

  // ✅ Refresh subjects with storage validation
  Future<void> refreshSubjects() async {
    await validateAndFixStorage();
    await fetchSubjects();
  }

  // ✅ Method to manually set class and semester
  Future<void> setClassAndSemester(String className, String semester) async {
    await storage.write('class', className.trim());
    await storage.write('sem', semester.trim());
    print('Updated storage - class: "$className", semester: "$semester"');
    await fetchSubjects();
  }

  // Get subject by name
  SubjectModel? getSubjectByName(String name) {
    try {
      return subjects.firstWhere(
            (subject) => subject.subjectName.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      print('Subject not found: $name');
      return null;
    }
  }

  // Search subjects
  List<SubjectModel> searchSubjects(String query) {
    if (query.isEmpty) return subjects.toList();

    return subjects.where((subject) =>
        subject.subjectName.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  // ✅ Method to clear subjects and reset state
  void clearSubjects() {
    subjects.clear();
    errorMessage.value = '';
  }

  // ✅ Get current storage values for debugging
  Map<String, dynamic> getStorageInfo() {
    return {
      'class': storage.read('class'),
      'sem': storage.read('sem'),
      'hasClass': storage.hasData('class'),
      'hasSem': storage.hasData('sem'),
    };
  }
}
