import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../controllers/inboxController/inbox_controller.dart';
import '../../controllers/inboxController/inbox_model.dart';
import 'alert_details_page.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AlertsController controller = Get.put(AlertsController());

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.inbox_rounded, size: 32, color: Colors.black),
                  SizedBox(width: 8),
                  Text("Inbox", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Obx(
                      () => Skeletonizer(
                    enabled: controller.isLoading.value,
                    child: _buildGroupedAlertsList(controller),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupedAlertsList(AlertsController controller) {
    if (!controller.isLoading.value && controller.groupedAlerts.isEmpty) {
      return const Center(
        child: Text("No alerts available!", style: TextStyle(fontSize: 16, color: Colors.grey)),
      );
    }

    final groupKeys = controller.isLoading.value
        ? ['Today', 'Yesterday']
        : controller.groupedAlerts.keys.toList();

    return ListView.builder(
      itemCount: groupKeys.length,
      itemBuilder: (context, index) {
        final groupName = groupKeys[index];
        final alertsInGroup = controller.isLoading.value
            ? List.filled(3, AlertModel.dummy())
            : controller.groupedAlerts[groupName]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 4.0),
              child: Text(groupName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: alertsInGroup.length,
              itemBuilder: (context, itemIndex) {
                final alert = alertsInGroup[itemIndex];
                return ListTile(
                  leading:  alert.iconUrl != null ? CircleAvatar(
                    backgroundImage:  NetworkImage(alert.iconUrl!),
                  ) : const CircleAvatar(
                    child: Icon(Icons.notifications),
                  ),
                  title: Text(alert.title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      timeago.format(alert.date.toDate()),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ),
                  onTap: () {
                    if (!controller.isLoading.value) {
                      Get.to(() => AlertDetailsScreen(alert: alert));
                    }
                  },
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                );
              },
              separatorBuilder: (context, index) => const Divider(height: 1),
            ),
          ],
        );
      },
    );
  }
}