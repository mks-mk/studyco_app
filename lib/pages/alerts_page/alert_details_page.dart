import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controllers/inboxController/inbox_model.dart';

class AlertDetailsScreen extends StatelessWidget {
  // This screen will receive the specific alert object to display
  final AlertModel alert;

  const AlertDetailsScreen({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    // Format the date nicely
    final formattedDate = DateFormat('d MMMM yyyy, hh:mm a').format(alert.date.toDate());

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(onPressed: (){
                    Navigator.pop(context);
                  }, icon: Icon(Icons.arrow_back_ios_rounded)),
                  Expanded(child: Text(alert.title,style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold,),maxLines: 3,))
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
              
                      // --- Display Image if it exists ---
                      if (alert.imageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12.0),
                          child: Image.network(
                            alert.imageUrl!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            // Show a placeholder while loading
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const AspectRatio(
                                aspectRatio: 16 / 9,
                                child: Center(child: CircularProgressIndicator()),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) =>
                            const AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Center(
                                child: Icon(Icons.browse_gallery_rounded, size: 40, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                      if (alert.imageUrl != null) const SizedBox(height: 24),
              
                      // --- Title ---
                      Text(
                        alert.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
              
                      // --- Date and Time ---
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            formattedDate,
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
              
                      // --- Full Description ---
                      Text(
                        alert.description,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5, // Improves readability
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}