import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../models/for_you_model.dart';

class ForYouController extends GetxController {
  final RxList<ForYouModel> forYouItems = <ForYouModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  GetStorage storage = GetStorage();

  @override
  void onInit() {
    super.onInit();
    fetchForYou();
  }

  Future<void> fetchForYou() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      String? className;

      if (storage.read('class').toString().contains("BTech")) {
        className = "BTech";
      } else {
        className = storage.read('class');
      }

      // Validate required data
      if (className == null) {
        throw Exception('Class information not found in storage');
      }

      final DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("For_YOU")
          .doc(className)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;

        if (data.containsKey('Enroll')) {
          final subjectsData = data['Enroll'];
          final List<ForYouModel> tempItems = [];

          if (subjectsData is List) {
            // Handle array format - store in reverse order
            for (var i = subjectsData.length - 1; i >= 0; i--) {
              if (subjectsData[i] is Map<String, dynamic>) {
                tempItems.add(ForYouModel.fromMap(subjectsData[i]));
              }
            }
          } else if (subjectsData is Map<String, dynamic>) {
            // Handle object format with numbered keys - reverse the order
            final keys = subjectsData.keys.toList()..sort((a, b) => b.compareTo(a));
            for (var key in keys) {
              if (subjectsData[key] is Map<String, dynamic>) {
                tempItems.add(ForYouModel.fromMap(subjectsData[key]));
              }
            }
          }

          // Update the observable list all at once
          forYouItems.assignAll(tempItems);

          print('Successfully fetched ${forYouItems.length} items in reverse order');
        } else {
          throw Exception('No Enroll field found in document');
        }
      } else {
        throw Exception('Document does not exist for class: $className');
      }
    } catch (e) {
      errorMessage.value = e.toString();
      print('Error fetching for you items: $e');

      Get.snackbar(
        'Error',
        'Failed to load for you items: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Refresh items
  Future<void> refreshForYou() async {
    await fetchForYou();
  }

  // Get item by name
  ForYouModel? getForYouByName(String name) {
    try {
      return forYouItems.firstWhere(
            (item) => item.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  // Search items
  List<ForYouModel> searchForYou(String query) {
    if (query.isEmpty) return forYouItems.toList();
    return forYouItems.where((item) =>
        item.name.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  // Add new item at the beginning (top) of the list
  void addForYouItem(ForYouModel item) {
    forYouItems.insert(0, item);
  }
  
}