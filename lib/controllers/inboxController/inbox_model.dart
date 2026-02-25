import 'package:cloud_firestore/cloud_firestore.dart';

class AlertModel {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String? iconUrl; // Added for the leading icon
  final Timestamp date;

  AlertModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.iconUrl,
    required this.date,
  });

  factory AlertModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data()!;
    return AlertModel(
      id: document.id,
      title: data['title'] ?? 'No Title',
      description: data['description'] ?? 'No Description',
      imageUrl: (data['imageUrl'] != 'null') ? data['imageUrl'] : null,
      iconUrl: data['icon'],
      date: data['date'] ?? Timestamp.now(),
    );
  }

  static AlertModel dummy() => AlertModel(
    id: '1',
    title: '          ',
    description: '                              ',
    date: Timestamp.now(),
  );
}