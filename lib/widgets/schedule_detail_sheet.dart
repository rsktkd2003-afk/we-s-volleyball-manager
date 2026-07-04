import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/team_player.dart';
import '../models/team_schedule.dart';
import '../repositories/schedule_repository.dart';
import '../services/firestore_service.dart';
import '../utils/date_time_utils.dart';
import 'schedule_response_section.dart';

/// 予定の詳細表示・出欠入力・編集/削除の起点となるボトムシート。
class ScheduleDetailSheet extends StatefulWidget {
  const ScheduleDetailSheet({
    super.key,
    required this.schedule,
    required this.players,
    required this.onEdit,
  });

  final TeamSchedule schedule;
  final List<TeamPlayer> players;
  final void Function(TeamSchedule) onEdit;

  @override
  State<ScheduleDetailSheet> createState() => _ScheduleDetailSheetState();
}

class _ScheduleDetailSheetState extends State<ScheduleDetailSheet> {
  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> deleteSchedule() async {
    final scheduleId = widget.schedule.id;
    if (scheduleId == null || uid == null) return;

    final admin = await FirestoreService.isCurrentUserAdmin();
    if (!mounted) return;

    if (!admin && widget.schedule.createdBy != uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('この予定を削除できるのは作成者か管理者だけです')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('予定を削除'),
          content: const Text('この予定を削除しますか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('削除'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirm != true) return;

    await ScheduleRepository.deleteSchedule(scheduleId);

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final schedule = widget.schedule;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              schedule.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.place),
              title: Text(
                schedule.location.isEmpty ? '場所未設定' : schedule.location,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: Text(
                '${formatMonthDayTime(schedule.start)} 〜 ${formatTime(schedule.end)}',
              ),
            ),
            const Divider(),
            if (schedule.id != null)
              ScheduleResponseSection(scheduleId: schedule.id!),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onEdit(schedule);
                },
                icon: const Icon(Icons.edit),
                label: const Text('予定を編集'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: deleteSchedule,
                icon: const Icon(Icons.delete),
                label: const Text('この予定を削除'),
              ),
            ),
            const Divider(),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '出欠一覧',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (schedule.id != null)
              ScheduleResponseList(scheduleId: schedule.id!),
          ],
        ),
      ),
    );
  }
}