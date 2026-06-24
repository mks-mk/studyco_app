import 'package:get/get.dart';
import 'package:studyco_app/controllers/inboxController/inbox_controller.dart';
import '../controllers/bookmark/bookmarkController.dart';
import '../controllers/downloads/save_controller.dart';
import '../controllers/myMaterials/my_materials_controller.dart';
import '../controllers/navController.dart';
import '../controllers/profile/profileController.dart';
import '../controllers/recentOpenings/recent_openings_controller.dart';
import '../controllers/single_device_controller.dart';
import '../controllers/subjectController/fetch_subjects.dart';
import '../controllers/subjectController/for_you_controller.dart';
import '../controllers/subjectController/getMaterialsWithSubjects.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => NavbarController());

    Get.lazyPut(() => SessionController());
    Get.lazyPut(() => UserProfileController());
    Get.lazyPut(() => SubjectController());
    Get.lazyPut(() => ForYouController());
    Get.lazyPut(() => RecentMaterialsController());

    Get.lazyPut(() => BookmarkController());
    Get.lazyPut(() => MyMaterialsController());
    Get.lazyPut(() => MaterialsWithSubjectsController(), fenix: true);
    Get.lazyPut(() => SecureDownloadManager(), fenix: true);
    Get.lazyPut(() => AlertsController(), fenix: true);
  }
}
