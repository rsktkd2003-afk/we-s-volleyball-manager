import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../repositories/schedule_repository.dart';
import '../theme/app_colors.dart';

/// 出欠の入力(参加/遅刻/欠席)と保存・削除ボタン。
class ScheduleResponseSection extends StatefulWidget {
  const ScheduleResponseSection({super.key, required this.scheduleId});

  final String scheduleId;

  @override
  State<ScheduleResponseSection> createState() =>
      _ScheduleResponseSectionState();
}

class _ScheduleResponseSectionState extends State<ScheduleResponseSection> {
  String status = '参加';
  TimeOfDay lateTime = const TimeOfDay(hour: 19, minute: 0);
  bool lateTimeUnknown = false;

  Future<void> _save() async {
    final lateTimeText = status == '遅刻'
        ? lateTimeUnknown
              ? '未定'
              : '${lateTime.hour.toString().padLeft(2, '0')}:${lateTime.minute.toString().padLeft(2, '0')}'
        : '';

    await ScheduleRepository.saveResponse(
      scheduleId: widget.scheduleId,
      status: status,
      lateTime: lateTimeText,
    );

    _showSnack('出欠を保存しました');
  }

  Future<void> _deleteMine() async {
    await ScheduleRepository.deleteMyResponse(widget.scheduleId);
    _showSnack('自分の出欠を削除しました');
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (final entry in const [
              ('参加', Icons.check_circle),
              ('遅刻', Icons.more_time),
              ('欠席', Icons.cancel),
            ]) ...[
              if (entry.$1 != '参加') const SizedBox(width: 8),
              Expanded(
                child: _StatusButton(
                  label: entry.$1,
                  icon: entry.$2,
                  selected: status == entry.$1,
                  onTap: () => setState(() => status = entry.$1),
                ),
              ),
            ],
          ],
        ),
        if (status == '遅刻') _buildLateTimeInput(),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _save,
            child: const Text('出欠を保存'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _deleteMine,
            icon: const Icon(Icons.delete_outline),
            label: const Text('自分の出欠を削除'),
          ),
        ),
      ],
    );
  }

  Widget _buildLateTimeInput() {
    return Column(
      children: [
        CheckboxListTile(
          value: lateTimeUnknown,
          title: const Text('到着時間は未定'),
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: (value) {
            setState(() => lateTimeUnknown = value ?? false);
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

              if (!mounted || picked == null) return;
              setState(() => lateTime = picked);
            },
          ),
      ],
    );
  }
}

/// 出欠一覧(集計カード + 回答リスト)。
class ScheduleResponseList extends StatelessWidget {
  const ScheduleResponseList({super.key, required this.scheduleId});

  final String scheduleId;

  static const _statuses = ['参加', '遅刻', '欠席'];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: ScheduleRepository.watchResponses(scheduleId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          );
        }

        final responses = snapshot.data!.docs;

        if (responses.isEmpty) {
          return const Column(
            children: [SizedBox(height: 12), Text('まだ出欠回答はありません')],
          );
        }

        return Column(
          children: [
            const SizedBox(height: 12),
            Row(
              children: [
                for (final status in _statuses) ...[
                  if (status != _statuses.first) const SizedBox(width: 8),
                  Expanded(
                    child: _CountCard(
                      label: status,
                      count: responses
                          .where((doc) => doc.data()['status'] == status)
                          .length,
                    ),
                  ),
                ],
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
    );
  }

  IconData _statusIcon(String value) {
    switch (value) {
      case '参加':
        return Icons.check_circle;
      case '遅刻':
        return Icons.more_time;
      case '欠席':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
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
    final colors = Theme.of(context).colorScheme;

    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? colors.primaryContainer : null,
        foregroundColor: selected ? colors.onPrimaryContainer : null,
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE3DFD5)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count人',
            style: const TextStyle(
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}