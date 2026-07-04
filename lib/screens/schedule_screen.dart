import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../datasources/team_schedule_data_source.dart';
import '../dialogs/add_schedule_dialog.dart';
import '../dialogs/schedule_edit_dialog.dart';
import '../models/schedule_template.dart';
import '../models/team_player.dart';
import '../models/team_schedule.dart';
import '../repositories/schedule_repository.dart';
import '../services/firestore_service.dart';
import '../services/team_service.dart';
import '../utils/schedule_utils.dart';
import '../widgets/bulletin_sticky_area.dart';
import '../widgets/cork_board_background.dart';
import '../widgets/match_poll_entry_card.dart';
import '../widgets/pinned_paper_card.dart';
import '../widgets/schedule_detail_sheet.dart';
import '../widgets/wes_fab.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  List<TeamSchedule> schedules = [];
  List<ScheduleTemplate> templates = [];
  List<TeamPlayer> players = [];

  StreamSubscription? _schedulesSub;
  StreamSubscription? _templatesSub;
  StreamSubscription? _playersSub;

  bool isAdmin = false;

  DateTime _visibleMonth =
      DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _schedulesSub?.cancel();
    _templatesSub?.cancel();
    _playersSub?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    final teamId = await TeamService.getCurrentTeamId();
    final admin = await FirestoreService.isCurrentUserAdmin();

    if (!mounted) return;
    setState(() => isAdmin = admin);
    _listenAll(teamId);
  }

  void _listenAll(String teamId) {
    _schedulesSub = ScheduleRepository.watchSchedules().listen(
      (list) {
        if (mounted) setState(() => schedules = list);
      },
      onError: _showStreamError,
    );

    _templatesSub = ScheduleRepository.watchTemplates().listen(
      (list) {
        if (mounted) setState(() => templates = list);
      },
      onError: _showStreamError,
    );

    _playersSub = FirebaseFirestore.instance
        .collection('players')
        .where('teamId', isEqualTo: teamId)
        .snapshots()
        .listen(
          (snapshot) {
            if (!mounted) return;

            setState(() {
              players = snapshot.docs
                  .map(
                    (doc) => TeamPlayer(
                      id: doc.id,
                      name: doc.data()['name'] ?? '',
                    ),
                  )
                  .toList();
            });
          },
          onError: _showStreamError,
        );
  }

  void _showStreamError(Object error) {
    debugPrint('ScheduleScreen stream error: $error');
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('データの取得に失敗しました: $error')),
    );
  }

  Future<void> _reloadSchedules() async {
    final loaded = await ScheduleRepository.fetchSchedules();
    if (!mounted) return;
    setState(() => schedules = loaded);
  }

  Future<void> _addSchedules(AddScheduleInput input) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    for (int i = 0; i < input.count; i++) {
      final start = getRepeatedStart(input.start, input.repeatType, i);

      await ScheduleRepository.addSchedule(
        TeamSchedule(
          title: input.title,
          location: input.location,
          start: start,
          end: start.add(Duration(minutes: input.durationMinutes)),
          durationMinutes: input.durationMinutes,
          color: Colors.blue,
          createdBy: uid,
        ),
      );
    }

    if (input.saveAsTemplate) {
      await ScheduleRepository.addTemplate(
        ScheduleTemplate(
          title: input.title,
          location: input.location,
          durationMinutes: input.durationMinutes,
        ),
      );
    }
  }

  Future<void> _onAddPressed() async {
    final input = await showAddScheduleDialog(
      context: context,
      templates: templates,
      onDeleteTemplate: (template) async {
        if (template.id == null) return;
        await ScheduleRepository.deleteTemplate(template.id!);
      },
    );

    if (input == null) return;
    await _addSchedules(input);
  }

  Future<void> _showScheduleDetail(TeamSchedule schedule) async {
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
      await _reloadSchedules();
    }
  }

  void _onCalendarViewChanged(ViewChangedDetails details) {
    final dates = details.visibleDates;
    if (dates.isEmpty) return;

    final mid = dates[dates.length ~/ 2];
    final newMonth = DateTime(mid.year, mid.month);

    if (newMonth != _visibleMonth) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _visibleMonth = newMonth);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CorkBoardBackground(
        child: SafeArea(
          child: Column(
            children: [
              BulletinStickyArea(
                visibleMonth: _visibleMonth,
                isAdmin: isAdmin,
              ),
              const MatchPollEntryCard(),

              Expanded(
                child: PinnedPaperCard(
                  child: SfCalendar(
                    view: CalendarView.month,
                    firstDayOfWeek: 1,
                    todayHighlightColor: const Color(0xFFD32F2F),
                    dataSource: TeamScheduleDataSource(schedules),
                    onViewChanged: _onCalendarViewChanged,
                    monthViewSettings: const MonthViewSettings(
                      appointmentDisplayMode:
                          MonthAppointmentDisplayMode.appointment,
                      showAgenda: true,
                    ),
                    appointmentTextStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    onTap: (details) {
                      final tapped = details.appointments;
                      if (tapped == null || tapped.isEmpty) return;

                      _showScheduleDetail(tapped.first as TeamSchedule);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton:
          WesFab(onPressed: _onAddPressed, tooltip: '予定を追加'),
    );
  }
}