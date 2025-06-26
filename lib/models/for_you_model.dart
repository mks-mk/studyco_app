class ForYouModel {
  final String name;
  final String thumbnail;

  ForYouModel({
    required this.name,
    required this.thumbnail
  });

  // Factory constructor to create from Firestore data
  factory ForYouModel.fromMap(Map<String, dynamic> map) {
    return ForYouModel(
      name: map['name'] ?? 'Unknown name',
      thumbnail: map['image'] ?? '',
    );
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'thumbnail': thumbnail,
    };
  }

  // Convert to JSON string
  @override
  String toString() {
    return 'SubjectModel(subjectName: $name, thumbnail: $thumbnail)';
  }

  // Equality operator
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ForYouModel &&
        other.name == name &&
        other.thumbnail == thumbnail;
  }

  @override
  int get hashCode => name.hashCode ^ thumbnail.hashCode;
}
