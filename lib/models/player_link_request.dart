import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerLinkRequest {
  final String id;

  final String teamId;
  final String uid;
  final String playerId;
  final String playerName;
  final String displayName;

  final String status; // pending / approved / rejected

  final DateTime? createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  const PlayerLinkRequest({
    this.id = '',
    required this.teamId,
    required this.uid,
    required this.playerId,
    required this.playerName,
    required this.displayName,
    this.status = 'pending',
    this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  Map<String, dynamic> toJson() {
    return {
      'teamId': teamId,
      'uid': uid,
      'playerId': playerId,
      'playerName': playerName,
      'displayName': displayName,
      'status': status,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
    };
  }

  factory PlayerLinkRequest.fromJson(
    Map<String, dynamic> json, {
    String id = '',
  }) {
    return PlayerLinkRequest(
      id: id,
      teamId: json['teamId'] ?? '',
      uid: json['uid'] ?? '',
      playerId: json['playerId'] ?? '',
      playerName: json['playerName'] ?? '',
      displayName: json['displayName'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: _timestampToDateTime(json['createdAt']),
      reviewedAt: _timestampToDateTime(json['reviewedAt']),
      reviewedBy: json['reviewedBy'],
    );
  }

  static DateTime? _timestampToDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}