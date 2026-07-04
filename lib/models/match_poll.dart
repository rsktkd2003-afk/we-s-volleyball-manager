import 'package:cloud_firestore/cloud_firestore.dart';

class MatchPoll {
  MatchPoll({
    required this.id,
    required this.title,
    required this.note,
    required this.candidates,
    required this.status,
    required this.confirmedCandidateId,
    required this.confirmedScheduleId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String note;
  final List<MatchPollCandidate> candidates;
  final String status;
  final String? confirmedCandidateId;
  final String? confirmedScheduleId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isOpen => status == 'open';
  bool get isConfirmed => status == 'confirmed';
  bool get isDeleted => status == 'deleted';

  factory MatchPoll.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawCandidates = data['candidates'];

    return MatchPoll(
      id: doc.id,
      title: data['title'] as String? ?? '',
      note: data['note'] as String? ?? '',
      candidates: rawCandidates is List
          ? rawCandidates
              .whereType<Map>()
              .map((item) => MatchPollCandidate.fromMap(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : const [],
      status: data['status'] as String? ?? 'open',
      confirmedCandidateId: data['confirmedCandidateId'] as String?,
      confirmedScheduleId: data['confirmedScheduleId'] as String?,
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: _dateFromValue(data['createdAt']),
      updatedAt: _dateFromValue(data['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'note': note,
      'candidates': candidates.map((candidate) => candidate.toJson()).toList(),
      'status': status,
      'confirmedCandidateId': confirmedCandidateId,
      'confirmedScheduleId': confirmedScheduleId,
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

class MatchPollCandidate {
  MatchPollCandidate({
    required this.id,
    required this.start,
    required this.end,
    required this.location,
  });

  final String id;
  final DateTime start;
  final DateTime end;
  final String location;

  int get durationMinutes => end.difference(start).inMinutes;

  factory MatchPollCandidate.fromMap(Map<String, dynamic> data) {
    return MatchPollCandidate(
      id: data['id'] as String? ?? '',
      start: MatchPoll._dateFromValue(data['start']),
      end: MatchPoll._dateFromValue(data['end']),
      location: data['location'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'start': Timestamp.fromDate(start),
      'end': Timestamp.fromDate(end),
      'location': location,
    };
  }
}