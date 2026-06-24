import 'package:get/get.dart';
import '../controllers/authcontroller.dart';
import '../controllers/ban_account_controller.dart';
import '../controllers/scrollController.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AuthController(), permanent: true);
    Get.put(BanController(), permanent: true);
    Get.put(ScrollerController(), permanent: true);
  }
}
