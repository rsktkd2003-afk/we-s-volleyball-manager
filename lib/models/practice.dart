class Practice {
  String id;

  String date;
  String startTime;
  int durationMinutes;
  String type;

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
      'date': date,
      'startTime': startTime,
      'durationMinutes': durationMinutes,
      'type': type,
      'attendance': attendance,
    };
  }

  factory Practice.fromJson(
    Map<String, dynamic> json, {
    String id = '',
  }) {
    return Practice(
      id: id.isNotEmpty ? id : json['id'] ?? '',
      date: json['date'] ?? '',
      startTime: json['startTime'] ?? '19:00',
      durationMinutes: json['durationMinutes'] ?? 120,
      type: json['type'] ?? '全体練習',
      attendance: Map<String, dynamic>.from(json['attendance'] ?? {}),
    );
  }
}