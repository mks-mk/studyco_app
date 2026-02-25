import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class RecentMaterialsController extends GetxController {
  final GetStorage _storage = GetStorage();
  static const String _recentKey = 'recent_materials';
  static const int _maxRecentItems = 20;

  final RxList<RecentMaterial> recentMaterials = <RecentMaterial>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadRecentMaterials();
  }

  void loadRecentMaterials() {
    try {
      final List<dynamic> storedData = _storage.read(_recentKey) ?? [];
      recentMaterials.value = storedData
          .map((item) => RecentMaterial.fromMap(item))
          .toList();

      print('Loaded ${recentMaterials.length} recent materials');
    } catch (e) {
      print('Error loading recent materials: $e');
      recentMaterials.clear();
    }
  }

  void addRecentMaterial({
    required String materialId,
    required String title,
    required String subject,
    required String type,
    required String thumbnail,
    required String source,
    required double price,
  }) {
    try {
      final newMaterial = RecentMaterial(
        materialId: materialId,
        title: title,
        subject: subject,
        type: type,
        thumbnail: thumbnail,
        source: source,
        price: price,
        openedAt: DateTime.now(),
      );

      recentMaterials.removeWhere((item) => item.materialId == materialId);
      recentMaterials.insert(0, newMaterial);

      if (recentMaterials.length > _maxRecentItems) {
        recentMaterials.removeRange(_maxRecentItems, recentMaterials.length);
      }

      _saveToStorage();
      print('Added material to recent: $title');
    } catch (e) {
      print('Error adding recent material: $e');
    }
  }

  void _saveToStorage() {
    try {
      final List<Map<String, dynamic>> dataToStore = recentMaterials
          .map((material) => material.toMap())
          .toList();

      _storage.write(_recentKey, dataToStore);
    } catch (e) {
      print('Error saving recent materials: $e');
    }
  }

  List<RecentMaterial> getRecentBySubject(String subject) {
    return recentMaterials
        .where((material) => material.subject == subject)
        .toList();
  }

  void clearRecentMaterials() {
    recentMaterials.clear();
    _storage.remove(_recentKey);
    print('Cleared all recent materials');
  }

  void removeRecentMaterial(String materialId) {
    recentMaterials.removeWhere((item) => item.materialId == materialId);
    _saveToStorage();
    print('Removed material from recent: $materialId');
  }

  bool isInRecent(String materialId) {
    return recentMaterials.any((item) => item.materialId == materialId);
  }

  int get recentCount => recentMaterials.length;

  List<String> getRecentSubjects() {
    return recentMaterials
        .map((material) => material.subject)
        .toSet()
        .toList();
  }
}

class RecentMaterial {
  final String materialId;
  final String title;
  final String subject;
  final String type;
  final String thumbnail;
  final String source;
  final double price;
  final DateTime openedAt;

  RecentMaterial({
    required this.materialId,
    required this.title,
    required this.subject,
    required this.type,
    required this.thumbnail,
    required this.source,
    required this.price,
    required this.openedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'materialId': materialId,
      'title': title,
      'subject': subject,
      'type': type,
      'thumbnail': thumbnail,
      'source': source,
      'price': price,
      'openedAt': openedAt.millisecondsSinceEpoch,
    };
  }

  factory RecentMaterial.fromMap(Map<String, dynamic> map) {
    return RecentMaterial(
      materialId: map['materialId'] ?? '',
      title: map['title'] ?? '',
      subject: map['subject'] ?? '',
      type: map['type'] ?? '',
      thumbnail: map['thumbnail'] ?? '',
      source: map['source'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      openedAt: DateTime.fromMillisecondsSinceEpoch(map['openedAt'] ?? 0),
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(openedAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
