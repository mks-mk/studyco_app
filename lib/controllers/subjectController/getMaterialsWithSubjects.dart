import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../Utilities/components/proggress_dialog.dart';
import '../../models/material_model.dart';

class MaterialsWithSubjectsController extends GetxController {
  final RxList<MaterialModel> materials = <MaterialModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // ADDED: Bookmark state management
  final RxMap<String, List<String>> bookmarkedIds = <String, List<String>>{}.obs;
  final RxBool isBookmarkLoading = false.obs;

  GetStorage storage = GetStorage();

  @override
  void onInit() {
    super.onInit();
    // Auto-fetch bookmarks when controller initializes
    fetchAllBookmarks();
  }

  Future<void> fetchData({required String subject}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      String? collection = storage.read('class');
      String? semester = storage.read('sem');

      // Validate required data
      if (collection == null || semester == null) {
        throw Exception('Class or semester information not found in storage');
      }

      // Get all documents from the subcollection
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection(collection)
          .doc(semester)
          .collection(subject)
          .get();

      // Clear existing materials
      materials.clear();

      // Process each document in the subcollection
      for (var doc in querySnapshot.docs) {
        if (doc.exists && doc.data() != null) {
          final data = doc.data() as Map<String, dynamic>;

          // Create MaterialModel with document ID
          materials.add(MaterialModel.fromMapWithId(doc.id, data));
        }
      }

      print('Successfully fetched ${materials.length} materials from $subject');

      // ADDED: Fetch bookmarks for this subject after fetching materials
      await fetchBookmarkedIds(subject: subject);

    } catch (e) {
      errorMessage.value = e.toString();
      print('Error fetching materials: $e');

      // Show error to user
      Get.snackbar(
        'Error',
        'Failed to load materials: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // INTEGRATED: Bookmark functionality
  Future<void> addBookmarks({required String subject, required String id}) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      Get.snackbar(
        'Error',
        'User not authenticated',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      showProgress();

      // Get current bookmarks for the subject
      List<String> currentIds = bookmarkedIds[subject] ?? [];

      // Check if ID already exists
      if (currentIds.contains(id)) {
        Get.back();
        Get.snackbar(
          'Info',
          'Material already bookmarked',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      // Add new ID to local list
      currentIds.add(id);
      bookmarkedIds[subject] = currentIds;

      // Update Firestore
      await _updateFirestoreBookmarks();

      Get.back();
      Get.snackbar(
        'Success',
        'Material bookmarked successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      print('Bookmark added: $id to $subject');

    } catch (e) {
      Get.back();
      print('Error adding bookmark: $e');
      Get.snackbar(
        'Error',
        'Failed to bookmark material: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // ADDED: Remove bookmark functionality
  Future<void> removeBookmark({required String subject, required String id}) async {
    try {
      List<String> currentIds = bookmarkedIds[subject] ?? [];

      if (currentIds.remove(id)) {
        bookmarkedIds[subject] = currentIds;

        // Update Firestore
        await _updateFirestoreBookmarks();

        Get.snackbar(
          'Success',
          'Bookmark removed',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.blue,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('Error removing bookmark: $e');
    }
  }

  // ADDED: Toggle bookmark functionality
  Future<void> toggleBookmark({required String subject, required String id}) async {
    if (isBookmarked(subject: subject, id: id)) {
      await removeBookmark(subject: subject, id: id);
    } else {
      await addBookmarks(subject: subject, id: id);
    }
  }

  // ADDED: Check if material is bookmarked
  bool isBookmarked({required String subject, required String id}) {
    final subjectBookmarks = bookmarkedIds[subject] ?? [];
    return subjectBookmarks.contains(id);
  }

  // ADDED: Get all bookmarked IDs for a subject
  List<String> getBookmarkedIds({required String subject}) {
    return bookmarkedIds[subject] ?? [];
  }

  // ADDED: Fetch bookmarked IDs for a specific subject
  Future<void> fetchBookmarkedIds({required String subject}) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      errorMessage.value = 'User not authenticated';
      return;
    }

    try {
      isBookmarkLoading.value = true;

      // Get user document from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) {
        bookmarkedIds[subject] = [];
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final bookmarks = userData['bookmarks'] ?? {};

      if (bookmarks.containsKey(subject)) {
        final subjectBookmarks = bookmarks[subject];
        if (subjectBookmarks is List) {
          // Store the ID list for this subject
          bookmarkedIds[subject] = subjectBookmarks.cast<String>();
        } else {
          bookmarkedIds[subject] = [];
        }
      } else {
        bookmarkedIds[subject] = [];
      }

      print('Successfully fetched ${bookmarkedIds[subject]?.length ?? 0} bookmarked IDs for $subject');

    } catch (e) {
      errorMessage.value = e.toString();
      print('Error fetching bookmarked IDs for $subject: $e');
    } finally {
      isBookmarkLoading.value = false;
    }
  }

  // ADDED: Fetch all bookmarks for all subjects
  Future<void> fetchAllBookmarks() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      errorMessage.value = 'User not authenticated';
      return;
    }

    try {
      isBookmarkLoading.value = true;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) {
        bookmarkedIds.clear();
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final bookmarks = userData['bookmarks'] ?? {};

      // Clear existing bookmarks
      bookmarkedIds.clear();

      // Process each subject's bookmarks
      bookmarks.forEach((subject, ids) {
        if (ids is List) {
          bookmarkedIds[subject] = ids.cast<String>();
        }
      });

      print('Successfully fetched bookmarks for ${bookmarkedIds.length} subjects');

    } catch (e) {
      errorMessage.value = e.toString();
      print('Error fetching all bookmarks: $e');
    } finally {
      isBookmarkLoading.value = false;
    }
  }

  // ADDED: Private method to update Firestore with current bookmarks
  Future<void> _updateFirestoreBookmarks() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      // Convert RxMap to regular Map for Firestore
      Map<String, dynamic> bookmarksToStore = {};
      bookmarkedIds.forEach((subject, ids) {
        bookmarksToStore[subject] = ids;
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .set({
        'bookmarks': bookmarksToStore,
      }, SetOptions(merge: true));

    } catch (e) {
      print('Error updating Firestore bookmarks: $e');
      rethrow;
    }
  }

  // ADDED: Get bookmarked materials for a subject
  List<MaterialModel> getBookmarkedMaterials({required String subject}) {
    final bookmarkedIdsList = getBookmarkedIds(subject: subject);
    return materials.where((material) =>
        bookmarkedIdsList.contains(material.id)
    ).toList();
  }

  // ADDED: Get bookmark count for a subject
  int getBookmarkCount({required String subject}) {
    return bookmarkedIds[subject]?.length ?? 0;
  }

  // ADDED: Clear all bookmarks for a subject
  Future<void> clearSubjectBookmarks({required String subject}) async {
    try {
      bookmarkedIds[subject] = [];
      await _updateFirestoreBookmarks();

      Get.snackbar(
        'Success',
        'All bookmarks cleared for $subject',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error clearing bookmarks: $e');
    }
  }

  // Refresh materials
  Future<void> refreshMaterials({required String subject}) async {
    await fetchData(subject: subject);
  }

  // Get material by name
  MaterialModel? getMaterialByName(String name) {
    try {
      return materials.firstWhere(
            (material) => material.noteName.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  // Search materials
  List<MaterialModel> searchMaterials(String query) {
    if (query.isEmpty) return materials.toList();

    return materials
        .where(
          (material) =>
          material.noteName.toLowerCase().contains(query.toLowerCase()),
    )
        .toList();
  }

  // Filter by type
  List<MaterialModel> filterByType(String type) {
    if (type.isEmpty) return materials.toList();

    return materials
        .where((material) => material.type.toLowerCase() == type.toLowerCase())
        .toList();
  }

  // Get free materials
  List<MaterialModel> getFreeMaterials() {
    return materials.where((material) => material.price == 0).toList();
  }

  // Get paid materials
  List<MaterialModel> getPaidMaterials() {
    return materials.where((material) => material.price > 0).toList();
  }

  // ADDED: Filter by module
  List<MaterialModel> filterByModule(int module) {
    return materials.where((material) => material.module == module).toList();
  }

  // ADDED: Get materials by multiple filters
  List<MaterialModel> getFilteredMaterials({
    String? searchQuery,
    List<int>? modules,
    List<String>? types,
    String? priceFilter,
    bool showBookmarkedOnly = false,
    String? subject,
  }) {
    return materials.where((material) {
      // Search filter
      bool matchesSearch = searchQuery == null || searchQuery.isEmpty ||
          material.noteName.toLowerCase().contains(searchQuery.toLowerCase());

      // Module filter
      bool matchesModule = modules == null || modules.isEmpty ||
          modules.contains(material.module);

      // Type filter
      bool matchesType = types == null || types.isEmpty ||
          types.contains(material.type);

      // Price filter
      bool matchesPrice = priceFilter == null || priceFilter.isEmpty ||
          (priceFilter == 'free' && material.price == 0) ||
          (priceFilter == 'paid' && material.price > 0);

      // Bookmarked filter
      bool matchesBookmark = !showBookmarkedOnly ||
          (subject != null && isBookmarked(subject: subject, id: material.id));

      return matchesSearch && matchesModule && matchesType && matchesPrice && matchesBookmark;
    }).toList();
  }
}
