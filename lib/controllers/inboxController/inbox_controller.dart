import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'inbox_model.dart';

class AlertsController extends GetxController {
  static AlertsController get instance => Get.find();
  final _db = FirebaseFirestore.instance;

  final RxList<AlertModel> alertsList = <AlertModel>[].obs;
  final RxMap<String, List<AlertModel>> groupedAlerts = <String, List<AlertModel>>{}.obs;

  // Re-introduced for the initial shimmer effect
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    bindAlertsStream();
  }

  void bindAlertsStream() {
    isLoading.value = true;
    final query = _db.collection('Alerts').orderBy('date', descending: true);
    final stream = query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => AlertModel.fromSnapshot(doc)).toList());

    alertsList.bindStream(stream);

    // Use 'once' to turn off the shimmer after the first batch of data arrives.
    once(alertsList, (_) => isLoading.value = false);

    // Use 'ever' to always keep the groups in sync whenever data changes.
    ever(alertsList, _groupAlertsByDate);
  }

  void _groupAlertsByDate(List<AlertModel> alerts) {
    final Map<String, List<AlertModel>> tempGroupedMap = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    for (var alert in alerts) {
      final alertDate = alert.date.toDate();
      final alertDay = DateTime(alertDate.year, alertDate.month, alertDate.day);

      String key;
      if (alertDay.isAtSameMomentAs(today)) {
        key = 'Today';
      } else if (alertDay.isAtSameMomentAs(yesterday)) {
        key = 'Yesterday';
      } else {
        key = DateFormat('MMMM yyyy').format(alertDate);
      }

      if (tempGroupedMap[key] == null) {
        tempGroupedMap[key] = [];
      }
      tempGroupedMap[key]!.add(alert);
    }
    groupedAlerts.assignAll(tempGroupedMap);
  }

  void clearAlerts() {
    alertsList.clear();
    groupedAlerts.clear();
  }
}