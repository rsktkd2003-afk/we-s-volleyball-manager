class PracticeTemplate {
  PracticeTemplate({
    required this.name,
    required this.type,
    required this.startTime,
    required this.durationMinutes,
    required this.repeatType,
    required this.count,
  });

  final String name;
  final String type;
  final String startTime;
  final int durationMinutes;
  final String repeatType;
  final int count;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'startTime': startTime,
      'durationMinutes': durationMinutes,
      'repeatType': repeatType,
      'count': count,
    };
  }

  factory PracticeTemplate.fromJson(Map<String, dynamic> json) {
    return PracticeTemplate(
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      startTime: json['startTime'] ?? '',
      durationMinutes: json['durationMinutes'] ?? 120,
      repeatType: json['repeatType'] ?? 'Once',
      count: json['count'] ?? 1,
    );
  }
}