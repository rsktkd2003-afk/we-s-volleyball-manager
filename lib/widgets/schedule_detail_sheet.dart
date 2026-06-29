import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/team_player.dart';
import '../models/team_schedule.dart';

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
  String status = '参加';
  TimeOfDay lateTime = const TimeOfDay(hour: 19, minute: 0);
  bool lateTimeUnknown = false;

  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  Future<bool> isAdmin() async {
    final currentUid = uid;
    if (currentUid == null) return false;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUid)
        .get();

    return doc.data()?['role'] == 'admin';
  }

  Future<void> saveResponse() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || widget.schedule.id == null) {
      return;
    }

    final currentUid = user.uid;

    final lateTimeText = status == '遅刻'
        ? lateTimeUnknown
              ? '未定'
              : '${lateTime.hour.toString().padLeft(2, '0')}:${lateTime.minute.toString().padLeft(2, '0')}'
        : '';

    await FirebaseFirestore.instance
        .collection('schedules')
        .doc(widget.schedule.id)
        .collection('responses')
        .doc(currentUid)
        .set({
          'uid': currentUid,
          'playerId': currentUid,
          'playerName': user.displayName ?? user.email ?? 'ログインユーザー',
          'status': status,
          'lateTime': lateTimeText,
          'updatedAt': FieldValue.serverTimestamp(),
        });

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('出欠を保存しました')));
  }

  Future<void> deleteMyResponse() async {
    if (uid == null || widget.schedule.id == null) return;

    await FirebaseFirestore.instance
        .collection('schedules')
        .doc(widget.schedule.id)
        .collection('responses')
        .doc(uid)
        .delete();

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('自分の出欠を削除しました')));
  }

  Future<void> deleteSchedule() async {
    final scheduleId = widget.schedule.id;
    if (scheduleId == null || uid == null) return;

    final admin = await isAdmin();

    if (!mounted) return;

    final canDelete = admin || widget.schedule.createdBy == uid;

    if (!canDelete) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('この予定を削除できるのは作成者か管理者だけです')));
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

    if (!mounted) return;

    if (confirm != true) return;

    await FirebaseFirestore.instance
        .collection('schedules')
        .doc(scheduleId)
        .delete();

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  void setStatus(String value) {
    setState(() {
      status = value;
    });
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
                '${formatDateTime(schedule.start)} 〜 ${formatTime(schedule.end)}',
              ),
            ),
            const Divider(),

            Row(
              children: [
                Expanded(
                  child: _StatusButton(
                    label: '参加',
                    selected: status == '参加',
                    icon: Icons.check_circle,
                    onTap: () => setStatus('参加'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatusButton(
                    label: '遅刻',
                    selected: status == '遅刻',
                    icon: Icons.more_time,
                    onTap: () => setStatus('遅刻'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatusButton(
                    label: '欠席',
                    selected: status == '欠席',
                    icon: Icons.cancel,
                    onTap: () => setStatus('欠席'),
                  ),
                ),
              ],
            ),

            if (status == '遅刻')
              Column(
                children: [
                  CheckboxListTile(
                    value: lateTimeUnknown,
                    title: const Text('到着時間は未定'),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (value) {
                      setState(() {
                        lateTimeUnknown = value ?? false;
                      });
                    },
                  ),
                  if (!lateTimeUnknown)
                    ListTile(
                      leading: const Icon(Icons.more_time),
                      title: Text('到着予定 ${lateTime.format(context)}'),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: lateTime,
                        );

                        if (!mounted) return;
                        if (picked == null) return;

                        setState(() {
                          lateTime = picked;
                        });
                      },
                    ),
                ],
              ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saveResponse,
                child: const Text('出欠を保存'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: deleteMyResponse,
                icon: const Icon(Icons.delete_outline),
                label: const Text('自分の出欠を削除'),
              ),
            ),
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

            const SizedBox(height: 8),
            const SizedBox(height: 8),
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

            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('schedules')
                  .doc(schedule.id)
                  .collection('responses')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  );
                }

                final responses = snapshot.data!.docs;

                final presentCount = responses
                    .where((doc) => doc.data()['status'] == '参加')
                    .length;
                final lateCount = responses
                    .where((doc) => doc.data()['status'] == '遅刻')
                    .length;
                final absentCount = responses
                    .where((doc) => doc.data()['status'] == '欠席')
                    .length;

                if (responses.isEmpty) {
                  return Column(
                    children: const [
                      SizedBox(height: 12),
                      Text('まだ出欠回答はありません'),
                    ],
                  );
                }

                return Column(
                  children: [
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _CountCard(label: '参加', count: presentCount),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _CountCard(label: '遅刻', count: lateCount),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _CountCard(label: '欠席', count: absentCount),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...responses.map((doc) {
                      final data = doc.data();
                      final responseStatus = data['status'] ?? '';
                      final responseLateTime = data['lateTime'] ?? '';

                      return ListTile(
                        leading: Icon(_statusIcon(responseStatus)),
                        title: Text(data['playerName'] ?? ''),
                        subtitle: Text(
                          responseStatus == '遅刻'
                              ? '遅刻：$responseLateTime から参加'
                              : responseStatus,
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _statusIcon(String value) {
    if (value == '参加') return Icons.check_circle;
    if (value == '遅刻') return Icons.more_time;
    if (value == '欠席') return Icons.cancel;
    return Icons.help_outline;
  }

  String formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day} ${formatTime(dateTime)}';
  }

  String formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.label,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        backgroundColor: selected
            ? Theme.of(context).colorScheme.primaryContainer
            : null,
        foregroundColor: selected
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : null,
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('$count人', style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
