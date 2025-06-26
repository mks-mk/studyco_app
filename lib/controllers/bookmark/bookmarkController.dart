import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class BookmarkController extends GetxController {
  final RxMap<String, List<String>> bookmarkedIds = <String, List<String>>{}.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  GetStorage storage = GetStorage();

  @override
  void onInit() {
    super.onInit();
    // Auto-fetch bookmarks when controller initializes
    fetchAllBookmarks();
  }

  // Fetch ID list for a specific subject
  Future<void> fetchBookmarkedIds({required String subject}) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      errorMessage.value = 'User not authenticated';
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

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

      Get.snackbar(
        'Error',
        'Failed to load bookmarks: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Fetch all bookmarks for all subjects
  Future<void> fetchAllBookmarks() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      errorMessage.value = 'User not authenticated';
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

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
      isLoading.value = false;
    }
  }

  // Store/Add ID to subject bookmark list
  Future<void> storeBookmarkedId({
    required String subject,
    required String id
  }) async {
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
      // Get current bookmarks for the subject
      List<String> currentIds = bookmarkedIds[subject] ?? [];

      // Check if ID already exists
      if (currentIds.contains(id)) {
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

      Get.snackbar(
        'Success',
        'Material bookmarked successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

    } catch (e) {
      print('Error storing bookmark: $e');
      Get.snackbar(
        'Error',
        'Failed to bookmark material: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Remove ID from subject bookmark list
  Future<void> removeBookmarkedId({
    required String subject,
    required String id
  }) async {
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

  // Toggle bookmark (add if not exists, remove if exists)
  Future<void> toggleBookmark({
    required String subject,
    required String id
  }) async {
    if (isBookmarked(subject: subject, id: id)) {
      await removeBookmarkedId(subject: subject, id: id);
    } else {
      await storeBookmarkedId(subject: subject, id: id);
    }
  }

  // Check if ID is bookmarked for a subject
  bool isBookmarked({required String subject, required String id}) {
    final subjectBookmarks = bookmarkedIds[subject] ?? [];
    return subjectBookmarks.contains(id);
  }

  // Get all bookmarked IDs for a subject
  List<String> getBookmarkedIds({required String subject}) {
    return bookmarkedIds[subject] ?? [];
  }

  // Get total bookmark count for a subject
  int getBookmarkCount({required String subject}) {
    return bookmarkedIds[subject]?.length ?? 0;
  }

  // Get all subjects that have bookmarks
  List<String> getBookmarkedSubjects() {
    return bookmarkedIds.keys.where((subject) =>
    bookmarkedIds[subject]?.isNotEmpty == true
    ).toList();
  }

  // Clear all bookmarks for a subject
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

  // Clear all bookmarks
  Future<void> clearAllBookmarks() async {
    try {
      bookmarkedIds.clear();
      await _updateFirestoreBookmarks();

      Get.snackbar(
        'Success',
        'All bookmarks cleared',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error clearing all bookmarks: $e');
    }
  }

  // Private method to update Firestore with current bookmarks
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
      throw e;
    }
  }

  // Refresh bookmarks from Firestore
  Future<void> refreshBookmarks({String? subject}) async {
    if (subject != null) {
      await fetchBookmarkedIds(subject: subject);
    } else {
      await fetchAllBookmarks();
    }
  }

  // Search bookmarked IDs
  List<String> searchBookmarkedIds({
    required String subject,
    required String query
  }) {
    final subjectBookmarks = bookmarkedIds[subject] ?? [];
    if (query.isEmpty) return subjectBookmarks;

    return subjectBookmarks.where((id) =>
        id.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
}
