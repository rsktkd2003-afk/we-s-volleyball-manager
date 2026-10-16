/// 出欠一覧の表示に使うデータ。FirestoreのスナップショットをUIへ渡さない。
class ScheduleResponse {
  const ScheduleResponse({
    required this.playerName,
    required this.status,
    required this.lateTime,
  });

  final String playerName;
  final String status;
  final String lateTime;

  factory ScheduleResponse.fromJson(Map<String, dynamic> json) {
    return ScheduleResponse(
      playerName: json['playerName'] ?? '',
      status: json['status'] ?? '',
      lateTime: json['lateTime'] ?? '',
    );
  }
}
