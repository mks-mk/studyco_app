class ForYouModel {
  final String name;
  final String thumbnail;
  final String src;

  ForYouModel({
    required this.name,
    required this.thumbnail,
    required this.src
  });

  // Factory constructor to create from Firestore data
  factory ForYouModel.fromMap(Map<String, dynamic> map) {
    return ForYouModel(
      name: map['name'] ?? 'Unknown name',
      thumbnail: map['image'] ?? '',
      src: map['src'] ?? "",
    );
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'thumbnail': thumbnail,
      'src' : src,
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
        other.thumbnail == thumbnail && other.src == src;
  }

  @override
  int get hashCode => name.hashCode ^ thumbnail.hashCode ^ src.hashCode;
}
