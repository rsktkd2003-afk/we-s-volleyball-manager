import 'package:cloud_firestore/cloud_firestore.dart';

class TeamGoal {
  TeamGoal({
    required this.id,
    required this.monthKey,
    required this.title,
    required this.body,
    required this.sortOrder,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String monthKey;
  final String title;
  final String body;
  final int sortOrder;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory TeamGoal.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return TeamGoal(
      id: doc.id,
      monthKey: data['monthKey'] as String? ?? '',
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: _dateFromValue(data['createdAt']),
      updatedAt: _dateFromValue(data['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'monthKey': monthKey,
      'title': title,
      'body': body,
      'sortOrder': sortOrder,
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