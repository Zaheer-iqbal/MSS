import 'package:cloud_firestore/cloud_firestore.dart';

class SchoolEventModel {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String location;
  final DateTime createdAt;

  SchoolEventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.createdAt,
  });

  factory SchoolEventModel.fromMap(Map<String, dynamic> map, String id) {
    return SchoolEventModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      location: map['location'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'location': location,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
