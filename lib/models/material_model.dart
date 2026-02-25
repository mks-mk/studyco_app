import 'package:flutter/material.dart';

class MaterialModel {
  final String id;
  final String noteName;
  final String thumbnail;
  final String source;
  final int price;
  final int module;
  final String type;
  final Color color;
  final String? description;
  final String? productID;

  MaterialModel({
    required this.id,
    required this.noteName,
    required this.thumbnail,
    required this.source,
    required this.price,
    required this.type,
    required this.color,
    required this.module,
    required this.description,
    this.productID,
  });

  // Factory constructor with document ID
  factory MaterialModel.fromMapWithId(String id, Map<String, dynamic> map) {
    return MaterialModel(
      id: id,
      noteName: map['name'] ?? 'Unknown',
      productID: map['productID'] ?? '',
      thumbnail: map['image'] ?? '',
      source: map['source'] ?? '',
      price: map['price'] ?? 0,
      type: map['type'] ?? '',
      color: _parseColor(map['color']),
      module: map['module'] ?? 1,
      description: map['description'] ?? '',
    );
  }

  // Keep existing fromMap for backward compatibility
  factory MaterialModel.fromMap(Map<String, dynamic> map) {
    return MaterialModel.fromMapWithId('', map);
  }

  // Parse color from different formats
  static Color _parseColor(dynamic colorData) {
    if (colorData == null) return Color(0xFF2196F3); // Default blue

    if (colorData is int) {
      return Color(colorData);
    } else if (colorData is String) {
      return _hexToColor(colorData);
    }

    return Color(0xFF2196F3); // Fallback
  }

  // Convert hex string to Color
  static Color _hexToColor(String hexString) {
    try {
      hexString = hexString.replaceAll('#', '');
      if (hexString.length == 6) {
        hexString = 'FF$hexString';
      }
      return Color(int.parse(hexString, radix: 16));
    } catch (e) {
      return Color(0xFF2196F3); // Fallback on error
    }
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': noteName,
      'image': thumbnail,
      'productID': productID,
      'description': description,
      'source': source,
      'price': price,
      'type': type,
      'color': color.value,
    };
  }

  @override
  String toString() {
    return 'MaterialModel(id: $id, noteName: $noteName, thumbnail: $thumbnail, color: $color, description: $description, productID: $productID)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MaterialModel &&
        other.id == id &&
        other.noteName == noteName &&
        other.thumbnail == thumbnail &&
        other.source == source &&
        other.price == price &&
        other.type == type &&
        other.productID == productID &&
        other.description == description &&
        other.color == color;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      noteName.hashCode ^
      thumbnail.hashCode ^
      source.hashCode ^
      price.hashCode ^
      type.hashCode ^
      productID.hashCode ^
      description.hashCode ^
      color.hashCode;

}
