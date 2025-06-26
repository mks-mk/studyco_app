import 'package:get/get.dart';
import '../controllers/bookmark/bookmarkController.dart';
import '../controllers/subjectController/getMaterialsWithSubjects.dart';

class MyBookmarksBinding extends Bindings {
  @override
  void dependencies() {
    // Put controllers if they don't exist
    if (!Get.isRegistered<BookmarkController>()) {
      Get.put(BookmarkController());
    }
    if (!Get.isRegistered<MaterialsWithSubjectsController>()) {
      Get.put(MaterialsWithSubjectsController());
    }
  }
}
