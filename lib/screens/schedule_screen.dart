import 'dart:async';
import 'dart:math' as math;

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

  // SfCalendar のデータソースは1インスタンスを保持し、
  // 更新は notifyListeners(reset) で通知する(Syncfusion 推奨パターン)。
  // build のたびに new していると、setState 連鎖時に内部 GlobalKey の
  // 重複や不正レイアウトを誘発することがあるため。
  final TeamScheduleDataSource _dataSource =
      TeamScheduleDataSource(<TeamSchedule>[]);
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
    // schedules / templates は teamId に依存しないため、先に購読を開始する。
    // 以前は getCurrentTeamId() の await 後に購読していたため、
    // その処理が例外を投げるとカレンダーの購読自体が始まらず、
    // Firestore にデータがあっても予定が一切表示されなかった。
    _listenSchedules();

    try {
      final teamId = await TeamService.getCurrentTeamId();
      final admin = await FirestoreService.isCurrentUserAdmin();

      if (!mounted) return;
      setState(() => isAdmin = admin);
      _listenPlayers(teamId);
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
        // 切り分け用ログ
        debugPrint('Schedules: ${list.length}');
        for (final s in list) {
          debugPrint('${s.title} ${s.start} - ${s.end}');
        }
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

  void _listenPlayers(String teamId) {
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 幅600px未満をスマホ扱いにする。
              // syncfusion_flutter_calendar 33.2.12 の月表示は、カレンダーの
              // 描画高さが小さすぎると予定バーの角丸半径が負になり
              // geometry.dart の assert (tlRadiusX >= 0) で落ちるため、
              // どちらのレイアウトでもカレンダーの高さを潰さないようにする。
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

  /// スマホ(幅600px未満): 画面全体を縦スクロールにし、
  /// カレンダーには固定高さ620pxを与えて表示領域を保証する。
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          BulletinStickyArea(
            visibleMonth: _visibleMonth,
            isAdmin: isAdmin,
          ),
          const MatchPollEntryCard(),
          SizedBox(
            height: 620,
            width: double.infinity,
            child: PinnedPaperCard(child: _buildCalendar()),
          ),
        ],
      ),
    );
  }

  /// PC・タブレット(幅600px以上): 従来どおり Expanded で残り領域いっぱいに
  /// カレンダーを表示。ウィンドウが極端に低い場合のみ最低高さ500pxを保証。
  Widget _buildWideLayout() {
    return Column(
      children: [
        BulletinStickyArea(
          visibleMonth: _visibleMonth,
          isAdmin: isAdmin,
        ),
        const MatchPollEntryCard(),
        Expanded(
          child: PinnedPaperCard(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const minCalendarHeight = 500.0;
                final calendar = _buildCalendar();
                if (constraints.maxHeight >= minCalendarHeight) {
                  return calendar;
                }
                return SingleChildScrollView(
                  child: SizedBox(
                    height: math.max(
                      constraints.maxHeight,
                      minCalendarHeight,
                    ),
                    child: calendar,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  SfCalendar _buildCalendar() {
    return SfCalendar(
      view: CalendarView.month,
      firstDayOfWeek: 1,
      todayHighlightColor: const Color(0xFFD32F2F),
      dataSource: _dataSource,
      onViewChanged: _onCalendarViewChanged,
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
        final tapped = details.appointments;
        if (tapped == null || tapped.isEmpty) return;

        _showScheduleDetail(tapped.first as TeamSchedule);
      },
    );
  }
}