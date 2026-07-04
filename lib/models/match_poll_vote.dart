import 'package:cloud_firestore/cloud_firestore.dart';

class MatchPollVote {
  MatchPollVote({
    required this.uid,
    required this.displayName,
    required this.answers,
    required this.updatedAt,
  });

  final String uid;
  final String displayName;
  final Map<String, MatchPollAnswer> answers;
  final DateTime updatedAt;

  factory MatchPollVote.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawAnswers = data['answers'];

    final answers = <String, MatchPollAnswer>{};
    if (rawAnswers is Map) {
      for (final entry in rawAnswers.entries) {
        final value = entry.value;
        if (value is Map) {
          answers[entry.key.toString()] = MatchPollAnswer.fromMap(
            Map<String, dynamic>.from(value),
          );
        }
      }
    }

    return MatchPollVote(
      uid: data['uid'] as String? ?? doc.id,
      displayName: data['displayName'] as String? ?? '',
      answers: answers,
      updatedAt: _dateFromValue(data['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'displayName': displayName,
      'answers': answers.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static DateTime _dateFromValue(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}

class MatchPollAnswer {
  MatchPollAnswer({
    required this.choice,
    required this.comment,
  });

  final String choice;
  final String comment;

  factory MatchPollAnswer.fromMap(Map<String, dynamic> data) {
    return MatchPollAnswer(
      choice: data['choice'] as String? ?? 'ng',
      comment: data['comment'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'choice': choice,
      'comment': choice == 'maybe' ? comment : '',
    };
  }
}