import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.sortOrder,
    required this.isPinned,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String body;
  final int sortOrder;
  final bool isPinned;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Announcement.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return Announcement(
      id: doc.id,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      isPinned: data['isPinned'] as bool? ?? false,
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: _dateFromValue(data['createdAt']),
      updatedAt: _dateFromValue(data['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      'sortOrder': sortOrder,
      'isPinned': isPinned,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static DateTime _dateFromValue(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}