class Practice {
  String id;

  String date;
  String startTime;
  int durationMinutes;
  String type;

  // playerId →
  // status: present / late / absent
  // lateTime: 19:30
  Map<String, dynamic> attendance;

  Practice({
    required this.id,
    required this.date,
    required this.startTime,
    required this.durationMinutes,
    required this.type,
    required this.attendance,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'startTime': startTime,
      'durationMinutes': durationMinutes,
      'type': type,
      'attendance': attendance,
    };
  }

  factory Practice.fromJson(Map<String, dynamic> json) {
    return Practice(
      id: json['id'] ?? '',
      date: json['date'] ?? '',
      startTime: json['startTime'] ?? '19:00',
      durationMinutes: json['durationMinutes'] ?? 120,
      type: json['type'] ?? '全体練習',
      attendance: Map<String, dynamic>.from(json['attendance'] ?? {}),
    );
  }
}
