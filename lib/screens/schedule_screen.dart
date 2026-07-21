import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../datasources/team_schedule_data_source.dart';
import '../dialogs/add_schedule_dialog.dart';
import '../dialogs/schedule_edit_dialog.dart';
import '../models/schedule_template.dart';
import '../models/team_schedule.dart';
import '../repositories/schedule_repository.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../utils/schedule_utils.dart';
import '../widgets/bulletin_sticky_area.dart';
import '../widgets/cork_board_background.dart';
import '../widgets/match_poll_entry_card.dart';
import '../widgets/pinned_paper_card.dart';
import '../widgets/schedule_calendar.dart';
import '../widgets/schedule_day_agenda.dart';
import '../widgets/schedule_detail_sheet.dart';
import '../widgets/schedule_goal_note.dart';
import '../widgets/schedule_memo_note.dart';
import '../widgets/wes_fab.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  List<TeamSchedule> schedules = [];

  // SfCalendar のデータソースは1インスタンスを保持し、
  // 更新は notifyListeners(reset) で通知する(Syncfusion 推奨パターン)。
  // build のたびに new していると、setState 連鎖時に内部 GlobalKey の
  // 重複や不正レイアウトを誘発することがあるため。
  final TeamScheduleDataSource _dataSource =
      TeamScheduleDataSource(<TeamSchedule>[]);
  final CalendarController _calendarController = CalendarController();
  List<ScheduleTemplate> templates = [];

  StreamSubscription? _schedulesSub;
  StreamSubscription? _templatesSub;

  bool isAdmin = false;

  DateTime _visibleMonth =
      DateTime(DateTime.now().year, DateTime.now().month);
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _calendarController.selectedDate = _selectedDate;
    _init();
  }

  @override
  void dispose() {
    _schedulesSub?.cancel();
    _templatesSub?.cancel();
    _calendarController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _listenSchedules();

    try {
      final admin = await FirestoreService.isCurrentUserAdmin();

      if (!mounted) return;
      setState(() => isAdmin = admin);
    } catch (e) {
      debugPrint('ScheduleScreen init error: $e');
      _showStreamError(e);
    }
  }

  void _setSchedules(List<TeamSchedule> list) {
    if (!mounted) return;
    setState(() => schedules = list);
    _dataSource.appointments!
      ..clear()
      ..addAll(list);
    _dataSource.notifyListeners(CalendarDataSourceAction.reset, list);
  }

  void _listenSchedules() {
    _schedulesSub = ScheduleRepository.watchSchedules().listen(
      (list) {
        _setSchedules(list);
      },
      onError: _showStreamError,
    );

    _templatesSub = ScheduleRepository.watchTemplates().listen(
      (list) {
        if (mounted) setState(() => templates = list);
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
    _setSchedules(loaded);
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
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ScheduleDetailSheet(
          schedule: schedule,
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

    if (!_isSameMonth(newMonth, _visibleMonth)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        final now = DateTime.now();
        final nextSelectedDate = _isSameMonth(_selectedDate, newMonth)
            ? _selectedDate
            : _isSameMonth(now, newMonth)
            ? DateTime(now.year, now.month, now.day)
            : newMonth;

        setState(() {
          _visibleMonth = newMonth;
          _selectedDate = nextSelectedDate;
        });
        _calendarController.selectedDate = nextSelectedDate;
      });
    }
  }

  void _onDateSelected(DateTime date) {
    final selected = DateTime(date.year, date.month, date.day);
    if (_isSameDay(selected, _selectedDate)) return;

    setState(() => _selectedDate = selected);
    _calendarController.selectedDate = selected;
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  bool _isSameMonth(DateTime first, DateTime second) {
    return first.year == second.year && first.month == second.month;
  }

  List<TeamSchedule> get _selectedDateSchedules {
    return schedulesForDate(schedules, _selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CorkBoardBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 幅600px未満をスマホ扱いにする。
              final isMobile = constraints.maxWidth < 600;
              return isMobile ? _buildMobileLayout() : _buildWideLayout();
            },
          ),
        ),
      ),
      floatingActionButton:
          WesFab(onPressed: _onAddPressed, tooltip: '予定を追加'),
    );
  }

  /// スマホ(幅600px未満): 月カレンダーの直下に選択日の予定を表示する。
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const _ScheduleBoardHeading(),
          PinnedPaperCard(
            showTape: true,
            child: Column(
              children: [
                SizedBox(height: 440, child: _buildCalendar()),
                const SizedBox(height: 18),
                const Divider(),
                const SizedBox(height: 12),
                _buildSelectedDateAgenda(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const ScheduleMemoNote(),
                const SizedBox(height: 16),
                ScheduleGoalNote(visibleMonth: _visibleMonth),
              ],
            ),
          ),
          const MatchPollEntryCard(),
          const _BulletinBoardHeading(),
          BulletinStickyArea(
            visibleMonth: _visibleMonth,
            isAdmin: isAdmin,
          ),
        ],
      ),
    );
  }

  /// PC・タブレット(幅600px以上): カレンダーと日別予定を左、
  /// MEMO/今月の目標を右サイドバーに配置する。
  Widget _buildWideLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const _ScheduleBoardHeading(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: PinnedPaperCard(
                  showTape: true,
                  child: Column(
                    children: [
                      SizedBox(height: 500, child: _buildCalendar()),
                      const SizedBox(height: 18),
                      const Divider(),
                      const SizedBox(height: 12),
                      _buildSelectedDateAgenda(),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 260,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 12, 12),
                  child: Column(
                    children: [
                      const ScheduleMemoNote(),
                      const SizedBox(height: 20),
                      ScheduleGoalNote(visibleMonth: _visibleMonth),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const MatchPollEntryCard(),
          const _BulletinBoardHeading(),
          BulletinStickyArea(
            visibleMonth: _visibleMonth,
            isAdmin: isAdmin,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return ScheduleCalendar(
      controller: _calendarController,
      dataSource: _dataSource,
      selectedDate: _selectedDate,
      onDateSelected: _onDateSelected,
      onViewChanged: _onCalendarViewChanged,
    );
  }

  Widget _buildSelectedDateAgenda() {
    return ScheduleDayAgenda(
      date: _selectedDate,
      schedules: _selectedDateSchedules,
      onScheduleTap: _showScheduleDetail,
    );
  }
}

class _ScheduleBoardHeading extends StatelessWidget {
  const _ScheduleBoardHeading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "WE'S VOLLEYBALL CLUB",
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'TEAM SCHEDULE BOARD',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(width: 56, height: 4, color: AppColors.accent),
        ],
      ),
    );
  }
}

class _BulletinBoardHeading extends StatelessWidget {
  const _BulletinBoardHeading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BULLETIN BOARD',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Container(width: 40, height: 3, color: AppColors.accent),
        ],
      ),
    );
  }
}
