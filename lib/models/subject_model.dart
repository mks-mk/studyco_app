class SubjectModel {
  final String subjectName;
  final String thumbnail;

  SubjectModel({
    required this.subjectName,
    required this.thumbnail
  });

  // Factory constructor to create from Firestore data
  factory SubjectModel.fromMap(Map<String, dynamic> map) {
    return SubjectModel(
      subjectName: map['name'] ?? map['subjectName'] ?? 'Unknown Subject',
      thumbnail: map['thumbanail'] ?? '',
    );
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': subjectName,
      'thumbnail': thumbnail,
    };
  }

  // Convert to JSON string
  @override
  String toString() {
    return 'SubjectModel(subjectName: $subjectName, thumbnail: $thumbnail)';
  }

  // Equality operator
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SubjectModel &&
        other.subjectName == subjectName &&
        other.thumbnail == thumbnail;
  }

  @override
  int get hashCode => subjectName.hashCode ^ thumbnail.hashCode;
}
