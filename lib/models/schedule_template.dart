class ScheduleTemplate {
  ScheduleTemplate({
    this.id,
    required this.title,
    required this.location,
    required this.durationMinutes,
  });

  final String? id;
  final String title;
  final String location;
  final int durationMinutes;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'location': location,
      'durationMinutes': durationMinutes,
    };
  }

  factory ScheduleTemplate.fromJson(Map<String, dynamic> json, String id) {
    return ScheduleTemplate(
      id: id,
      title: json['title'] ?? '',
      location: json['location'] ?? '',
      durationMinutes: json['durationMinutes'] ?? 180,
    );
  }
}
