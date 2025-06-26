import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../models/subject_model.dart';

class MyNotesController extends GetxController {
  final RxList<SubjectModel> myNotes = <SubjectModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  GetStorage storage = GetStorage();

  @override
  void onInit() {
    super.onInit();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      String? collection = storage.read('class');
      String? semester = storage.read('sem');
      String currentClass = "${collection}_$semester"; //BTech_A_1
      User? user = FirebaseAuth.instance.currentUser;

      // Validate required data
      if (collection == null || semester == null) {
        throw Exception('Class or semester information not found in storage');
      }

      final DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user?.uid).collection(currentClass).doc()
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;

        if (data.containsKey('MyNotes')) {
          final subjectsData = data['MyNotes'];

          // Clear existing subjects
          myNotes.clear();

          if (subjectsData is List) {
            // Handle array format
            for (var subjectData in subjectsData) {
              if (subjectData is Map<String, dynamic>) {
                myNotes.add(SubjectModel.fromMap(subjectData));
              }
            }
          } else if (subjectsData is Map<String, dynamic>) {
            // Handle object format with numbered keys
            subjectsData.forEach((key, value) {
              if (value is Map<String, dynamic>) {
                myNotes.add(SubjectModel.fromMap(value));
              }
            });
          }

          print('Successfully fetched ${myNotes.length} subjects');
        } else {
          throw Exception('No subjects field found in document');
        }
      } else {
        throw Exception('Document does not exist for class: $collection, semester: $semester');
      }
    } catch (e) {
      errorMessage.value = e.toString();
      print('Error fetching subjects: $e');

      // Show error to user
      Get.snackbar(
        'Error',
        'Failed to load subjects: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Refresh subjects
  Future<void> refreshSubjects() async {
    await fetchData();
  }

  // Get subject by name
  SubjectModel? getSubjectByName(String name) {
    try {
      return myNotes.firstWhere(
            (subject) => subject.subjectName.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  // Search subjects
  List<SubjectModel> searchSubjects(String query) {
    if (query.isEmpty) return myNotes.toList();

    return myNotes.where((subject) =>
        subject.subjectName.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
}

