class MyNotesModel {
  final String noteName;
  final String thumbnail;
  final String source;

  MyNotesModel({
    required this.noteName,
    required this.thumbnail,
    required this.source,
  });

  // Factory constructor to create from Firestore data
  factory MyNotesModel.fromMap(Map<String, dynamic> map) {
    return MyNotesModel(
      noteName: map['name'] ?? map['subjectName'] ?? 'Unknown Subject',
      thumbnail: map['thumbanail'] ?? '',
      source: map['source'] ?? '',
    );
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {'name': noteName, 'thumbnail': thumbnail, 'source': source};
  }

  // Convert to JSON string
  @override
  String toString() {
    return 'SubjectModel(subjectName: $noteName, thumbnail: $thumbnail)';
  }

  // Equality operator
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MyNotesModel &&
        other.noteName == noteName &&
        other.thumbnail == thumbnail &&
        other.source == source;
  }

  @override
  int get hashCode => noteName.hashCode ^ thumbnail.hashCode ^ source.hashCode;
}
