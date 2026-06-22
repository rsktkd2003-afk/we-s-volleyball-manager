import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../datasources/team_schedule_data_source.dart';
import '../models/schedule_template.dart';
import '../models/team_player.dart';
import '../models/team_schedule.dart';
import '../widgets/schedule_detail_sheet.dart';
import '../utils/schedule_utils.dart';
import '../dialogs/schedule_edit_dialog.dart';
import '../dialogs/template_delete_dialog.dart' as template_delete;
import '../services/team_service.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final db = FirebaseFirestore.instance;

  List<TeamSchedule> schedules = [];
  List<ScheduleTemplate> templates = [];
  List<TeamPlayer> players = [];

  StreamSubscription? schedulesSubscription;
  StreamSubscription? templatesSubscription;
  StreamSubscription? playersSubscription;

  String? teamId;

  @override
  void initState() {
    super.initState();
    initTeam();
  }

  Future<void> initTeam() async {
    teamId = await TeamService.getCurrentTeamId();
    listenAll();
  }

  @override
  void dispose() {
    schedulesSubscription?.cancel();
    templatesSubscription?.cancel();
    playersSubscription?.cancel();
    super.dispose();
  }

  void listenAll() {
    schedulesSubscription = db
        .collection('schedules')
        .where('teamId', isEqualTo: teamId)
        .orderBy('start')
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;

      setState(() {
        schedules = snapshot.docs
            .map((doc) => TeamSchedule.fromJson(doc.data(), doc.id))
            .toList();
      });
    });

    templatesSubscription = db
        .collection('schedule_templates')
        .where('teamId', isEqualTo: teamId)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;

      setState(() {
        templates = snapshot.docs
            .map((doc) => ScheduleTemplate.fromJson(doc.data(), doc.id))
            .toList();
      });
    });

    playersSubscription = db
        .collection('players')
        .where('teamId', isEqualTo: teamId)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;

      setState(() {
        players = snapshot.docs.map((doc) {
          final data = doc.data();

          return TeamPlayer(
            id: doc.id,
            name: data['name'] ?? '',
          );
        }).toList();
      });
    });
  }

  Future<void> loadSchedules() async {
    final snapshot = await db
        .collection('schedules')
        .where('teamId', isEqualTo: teamId)
        .orderBy('start')
        .get();

    setState(() {
      schedules = snapshot.docs
          .map((doc) => TeamSchedule.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> addSchedule(TeamSchedule schedule) async {
    await db.collection('schedules').add({
      ...schedule.toJson(),
      'teamId': teamId,
    });
  }

  Future<void> addTemplate(ScheduleTemplate template) async {
    await db.collection('schedule_templates').add({
      ...template.toJson(),
      'teamId': teamId,
    });
  }

  Future<void> deleteTemplate(ScheduleTemplate template) async {
    if (template.id == null) return;

    await db.collection('schedule_templates').doc(template.id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SfCalendar(
        view: CalendarView.month,
        firstDayOfWeek: 1,
        todayHighlightColor: Colors.blue,
        dataSource: TeamScheduleDataSource(schedules),
        monthViewSettings: const MonthViewSettings(
          appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
          showAgenda: true,
        ),
        appointmentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
        onTap: (details) {
          if (details.appointments == null || details.appointments!.isEmpty) {
            return;
          }

          final schedule = details.appointments!.first as TeamSchedule;
          showScheduleDetail(schedule);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddScheduleDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> showAddScheduleDialog() async {
    final titleController = TextEditingController();
    final locationController = TextEditingController();

    DateTime selectedDate = DateTime.now();
    TimeOfDay startTime = const TimeOfDay(hour: 18, minute: 0);
    int durationMinutes = 180;
    bool saveAsTemplate = false;
    String repeatType = '単発';
    int count = 1;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('予定追加'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (templates.isNotEmpty)
                      DropdownButton<ScheduleTemplate>(
                        isExpanded: true,
                        hint: const Text('テンプレートを選択'),
                        items: templates.map((template) {
                          return DropdownMenuItem(
                            value: template,
                            child: Text(template.title),
                          );
                        }).toList(),
                        onChanged: (template) {
                          if (template == null) return;

                          setDialogState(() {
                            titleController.text = template.title;
                            locationController.text = template.location;
                            durationMinutes = template.durationMinutes;
                          });
                        },
                      ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: templates.isEmpty
                            ? null
                            : () async {
                                final deleted =
                                    await template_delete.showTemplateDeleteDialog(
                                  context: context,
                                  templates: templates,
                                  onDelete: deleteTemplate,
                                );

                                if (deleted == true) {
                                  setDialogState(() {});
                                }
                              },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('テンプレート削除'),
                      ),
                    ),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'タイトル'),
                    ),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(labelText: '場所'),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: const Icon(Icons.calendar_month),
                      title: Text(
                        '日付 ${selectedDate.year}/${selectedDate.month}/${selectedDate.day}',
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2035),
                        );

                        if (picked == null) return;

                        setDialogState(() {
                          selectedDate = picked;
                        });
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.schedule),
                      title: Text('開始 ${startTime.format(context)}'),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: startTime,
                        );

                        if (picked == null) return;

                        setDialogState(() {
                          startTime = picked;
                        });
                      },
                    ),
                    DropdownButton<int>(
                      value: durationMinutes,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 60, child: Text('所要時間 1時間')),
                        DropdownMenuItem(value: 90, child: Text('所要時間 1時間30分')),
                        DropdownMenuItem(value: 120, child: Text('所要時間 2時間')),
                        DropdownMenuItem(value: 150, child: Text('所要時間 2時間30分')),
                        DropdownMenuItem(value: 180, child: Text('所要時間 3時間')),
                        DropdownMenuItem(value: 240, child: Text('所要時間 4時間')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setDialogState(() {
                          durationMinutes = value;
                        });
                      },
                    ),
                    DropdownButton<String>(
                      value: repeatType,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: '単発', child: Text('単発')),
                        DropdownMenuItem(value: '毎日', child: Text('毎日')),
                        DropdownMenuItem(value: '毎週', child: Text('毎週')),
                        DropdownMenuItem(value: '毎月', child: Text('毎月')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setDialogState(() {
                          repeatType = value;
                        });
                      },
                    ),
                    DropdownButton<int>(
                      value: count,
                      isExpanded: true,
                      items: List.generate(20, (index) {
                        final value = index + 1;

                        return DropdownMenuItem(
                          value: value,
                          child: Text('作成回数 $value回'),
                        );
                      }),
                      onChanged: (value) {
                        if (value == null) return;

                        setDialogState(() {
                          count = value;
                        });
                      },
                    ),
                    CheckboxListTile(
                      value: saveAsTemplate,
                      title: const Text('テンプレートとして保存'),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (value) {
                        setDialogState(() {
                          saveAsTemplate = value ?? false;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('キャンセル'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('追加'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) return;

    final title =
        titleController.text.trim().isEmpty ? '予定' : titleController.text.trim();

    final location = locationController.text.trim();

    final start = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      startTime.hour,
      startTime.minute,
    );

    for (int i = 0; i < count; i++) {
      final repeatedStart = getRepeatedStart(start, repeatType, i);
      final repeatedEnd = repeatedStart.add(Duration(minutes: durationMinutes));

      await addSchedule(
        TeamSchedule(
          title: title,
          location: location,
          start: repeatedStart,
          end: repeatedEnd,
          durationMinutes: durationMinutes,
          color: Colors.blue,
          createdBy: FirebaseAuth.instance.currentUser?.uid,
        ),
      );
    }

    if (saveAsTemplate) {
      await addTemplate(
        ScheduleTemplate(
          title: title,
          location: location,
          durationMinutes: durationMinutes,
        ),
      );
    }
  }

  Future<void> showScheduleDetail(TeamSchedule schedule) async {
    if (schedule.id == null) return;

    final shouldReload = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return ScheduleDetailSheet(
          schedule: schedule,
          players: players,
          onEdit: (schedule) => showEditScheduleDialog(context, schedule),
        );
      },
    );

    if (shouldReload == true) {
      await loadSchedules();
    }
  }
}