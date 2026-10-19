import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../datasources/team_schedule_data_source.dart';
import '../dialogs/add_schedule_dialog.dart';
import '../dialogs/schedule_edit_dialog.dart';
import '../models/schedule_template.dart';
import '../models/team_player.dart';
import '../models/team_schedule.dart';
import '../providers/player_link_request_providers.dart';
import '../providers/player_providers.dart';
import '../providers/schedule_providers.dart';
import '../repositories/schedule_repository.dart';
import '../theme/app_colors.dart';
import '../utils/date_time_utils.dart';
import '../utils/schedule_utils.dart';
import '../widgets/cork_board_background.dart';
import '../widgets/schedule_detail_sheet.dart';
import '../widgets/schedule_goal_note.dart';
import '../widgets/schedule_memo_note.dart';
import '../widgets/wes_fab.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  List<TeamSchedule> schedules = [];

  // SfCalendar のデータソースは1インスタンスを保持し、
  // 更新は notifyListeners(reset) で通知する(Syncfusion 推奨パターン)。
  // build のたびに new していると、setState 連鎖時に内部 GlobalKey の
  // 重複や不正レイアウトを誘発することがあるため。
  final TeamScheduleDataSource _dataSource = TeamScheduleDataSource(
    <TeamSchedule>[],
  );

  // 権限の読み込み中・エラー時は管理者として扱わない(build 中のみ参照)。
  bool get isAdmin => ref
      .watch(currentUserIsAdminProvider)
      .maybeWhen(data: (value) => value, orElse: () => false);

  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);

  // テンプレート・選手は表示に使わず操作時に参照するだけなので、
  // build で watch せず、最新値を読み取る。
  List<ScheduleTemplate> get templates =>
      ref.read(scheduleTemplatesProvider).valueOrNull ?? const [];

  List<TeamPlayer> get players =>
      (ref.read(playersProvider).valueOrNull ?? const [])
          .map((player) => TeamPlayer(id: player.id, name: player.name))
          .toList();

  @override
  void initState() {
    super.initState();
    _listenSchedules();
    _listenPlayers();
    _listenAdminErrors();
  }

  // 管理者判定の取得に失敗した場合は、従来通りSnackBarで通知する。
  void _listenAdminErrors() {
    ref.listenManual<AsyncValue<bool>>(currentUserIsAdminProvider, (
      previous,
      next,
    ) {
      next.whenOrNull(
        error: (error, _) {
          debugPrint('ScheduleScreen init error: $error');
          _showStreamError(error);
        },
      );
    }, fireImmediately: true);
  }

  void _setSchedules(List<TeamSchedule> list) {
    if (!mounted) return;
    setState(() => schedules = list);
    _dataSource.appointments!
      ..clear()
      ..addAll(list);
    _dataSource.notifyListeners(CalendarDataSourceAction.reset, list);
  }

  // listenManual の購読は State の dispose 時に自動で解除される。
  void _listenSchedules() {
    ref.listenManual<AsyncValue<List<TeamSchedule>>>(schedulesProvider, (
      previous,
      next,
    ) {
      next.whenOrNull(
        data: (list) {
          _setSchedules(list);
        },
        error: (error, _) => _showStreamError(error),
      );
    }, fireImmediately: true);

    ref.listenManual<AsyncValue<List<ScheduleTemplate>>>(
      scheduleTemplatesProvider,
      (previous, next) {
        next.whenOrNull(error: (error, _) => _showStreamError(error));
      },
      fireImmediately: true,
    );
  }

  void _listenPlayers() {
    ref.listenManual(playersProvider, (previous, next) {
      next.whenOrNull(error: (error, _) => _showStreamError(error));
    }, fireImmediately: true);
  }

  void _showStreamError(Object error) {
    debugPrint('ScheduleScreen stream error: $error');
    if (!mounted) return;

    void show() {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('データの取得に失敗しました: $error')));
    }

    // initState / build 中に呼ばれた場合だけ、フレーム終了後に表示する。
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      show();
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) => show());
    }
  }

  Future<void> _reloadSchedules(ScheduleRepository repository) async {
    final loaded = await repository.fetchSchedules();
    _setSchedules(loaded);
  }

  Future<void> _addSchedules(
    AddScheduleInput input,
    ScheduleRepository repository,
  ) async {
    final uid = repository.currentUid;

    for (int i = 0; i < input.count; i++) {
      final start = getRepeatedStart(input.start, input.repeatType, i);

      await repository.addSchedule(
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
      await repository.addTemplate(
        ScheduleTemplate(
          title: input.title,
          location: input.location,
          durationMinutes: input.durationMinutes,
        ),
      );
    }
  }

  Future<void> _onAddPressed() async {
    final repository = ref.read(scheduleRepositoryProvider);
    final input = await showAddScheduleDialog(
      context: context,
      templates: templates,
      onDeleteTemplate: (template) async {
        if (template.id == null) return;
        await repository.deleteTemplate(template.id!);
      },
    );

    if (input == null) return;
    await _addSchedules(input, repository);
  }

  Future<void> _showScheduleDetail(TeamSchedule schedule) async {
    if (schedule.id == null) return;
    final repository = ref.read(scheduleRepositoryProvider);

    final shouldReload = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ScheduleDetailSheet(
          schedule: schedule,
          players: players,
          onEdit: (schedule) =>
              showEditScheduleDialog(context, schedule, repository: repository),
        );
      },
    );

    if (shouldReload == true) {
      await _reloadSchedules(repository);
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
              final isMobile = constraints.maxWidth < 900;
              return isMobile ? _buildMobileLayout() : _buildWideLayout();
            },
          ),
        ),
      ),
      floatingActionButton: WesFab(onPressed: _onAddPressed, tooltip: '予定を追加'),
    );
  }

  // 目標とメモを最初に置き、カレンダーの安全な描画高さは維持する。
  Widget _buildMobileLayout() => _buildBoard(wide: false);

  Widget _buildWideLayout() => _buildBoard(wide: true);

  Widget _buildBoard({required bool wide}) {
    final notes = Column(
      children: [
        ScheduleGoalNote(visibleMonth: _visibleMonth),
        const SizedBox(height: 12),
        const ScheduleMemoNote(),
      ],
    );
    final calendar = SizedBox(
      height: 620,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE1DDD5)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x140D2138),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: _buildCalendar(),
      ),
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1440),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _ScheduleBoardHeading(),
              const SizedBox(height: 18),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 300, child: notes),
                    const SizedBox(width: 20),
                    Expanded(child: calendar),
                  ],
                )
              else ...[
                notes,
                const SizedBox(height: 12),
                calendar,
              ],
            ],
          ),
        ),
      ),
    );
  }

  SfCalendar _buildCalendar() {
    return SfCalendar(
      view: CalendarView.month,
      firstDayOfWeek: 1,
      headerDateFormat: 'yyyy年M月',
      todayHighlightColor: AppColors.editorialAccent,
      backgroundColor: AppColors.paper,
      cellBorderColor: const Color(0xFFE7E3DC),
      headerStyle: const CalendarHeaderStyle(
        backgroundColor: AppColors.paper,
        textStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
      viewHeaderStyle: const ViewHeaderStyle(
        backgroundColor: AppColors.paper,
        dayTextStyle: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      dataSource: _dataSource,
      onViewChanged: _onCalendarViewChanged,
      monthViewSettings: const MonthViewSettings(
        appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
        showAgenda: true,
        monthCellStyle: MonthCellStyle(
          backgroundColor: AppColors.paper,
          trailingDatesBackgroundColor: Color(0xFFF4F1EA),
          leadingDatesBackgroundColor: Color(0xFFF4F1EA),
          textStyle: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      appointmentBuilder: (context, details) {
        final schedule = details.appointments.first as TeamSchedule;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: _stickyColorFor(schedule.title),
            border: Border(
              left: BorderSide(
                color: _eventAccentFor(schedule.title),
                width: 4,
              ),
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.centerLeft,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                schedule.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${formatTime(schedule.start)}〜${formatTime(schedule.end)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        );
      },
      onTap: (details) {
        final tapped = details.appointments;
        if (tapped == null || tapped.isEmpty) return;

        _showScheduleDetail(tapped.first as TeamSchedule);
      },
    );
  }

  /// タイトルに含まれるキーワードから付箋の色を決める（画像の配色に準拠）。
  /// 該当キーワードが無い場合は「練習」系として青を使う。
  Color _eventAccentFor(String title) {
    if (title.contains('ウェイト')) return const Color(0xFF715414);
    if (title.contains('試合') || title.contains('公式戦') || title.contains('大会')) {
      return const Color(0xFFAA3025);
    }
    return AppColors.action;
  }

  Color _stickyColorFor(String title) {
    if (title.contains('ウェイト')) return const Color(0xFFF3E6BB);
    if (title.contains('試合') || title.contains('公式戦') || title.contains('大会')) {
      return const Color(0xFFFAD6CF);
    }
    return const Color(0xFFD4E6F4);
  }
}

class _ScheduleBoardHeading extends StatelessWidget {
  const _ScheduleBoardHeading();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final isCompact = constraints.maxWidth < 600;
      final height = isCompact ? 150.0 : 160.0;
      return Padding(
        padding: const EdgeInsets.only(top: 2),
        child: SizedBox(
          height: height,
          child: Stack(
            children: [
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: isCompact ? 156 : 230,
                child: CustomPaint(painter: _CourtLinesPainter()),
              ),
              Positioned(
                right: isCompact ? 27 : 58,
                top: 12,
                child: Icon(
                  Icons.sports_volleyball_rounded,
                  size: isCompact ? 72 : 100,
                  color: AppColors.action,
                  shadows: const [
                    Shadow(
                      color: Color(0x1A17314F),
                      blurRadius: 8,
                      offset: Offset(2, 4),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                top: 10,
                bottom: 0,
                right: isCompact ? 72 : 112,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "WE'S",
                      style: TextStyle(
                        color: AppColors.action,
                        fontSize: isCompact ? 48 : 58,
                        height: .92,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'VOLLEYBALL',
                      maxLines: 1,
                      style: TextStyle(
                        color: AppColors.action,
                        fontSize: isCompact ? 23 : 30,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text(
                          'チームの予定',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: AppColors.editorialAccent.withValues(
                              alpha: .7,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _CourtLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final redStroke = Paint()
      ..color = AppColors.editorialAccent.withValues(alpha: .84)
      ..strokeWidth = size.width * .1
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(
      Offset(size.width * .28, size.height * .30),
      Offset(size.width * .96, size.height * -.02),
      redStroke,
    );
    final redFine = Paint()
      ..color = AppColors.editorialAccent.withValues(alpha: .25)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(size.width * .12, size.height * .52),
      Offset(size.width, size.height * .12),
      redFine,
    );
    final court = Paint()
      ..color = const Color(0x3017314F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var x = 0.0; x <= size.width; x += 14) {
      canvas.drawLine(
        Offset(x, size.height * .34),
        Offset(x + 3, size.height),
        court,
      );
    }
    for (var y = size.height * .38; y <= size.height; y += 14) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y - 4), court);
    }
    canvas.drawLine(
      Offset(size.width * .28, 0),
      Offset(size.width * .28, size.height),
      court,
    );
    canvas.drawLine(
      Offset(size.width * .76, 0),
      Offset(size.width * .76, size.height),
      court,
    );
    canvas.drawLine(
      Offset(0, size.height * .42),
      Offset(size.width, size.height * .42),
      court,
    );
    canvas.drawLine(
      Offset(0, size.height * .76),
      Offset(size.width, size.height * .76),
      court,
    );
  }

  @override
  bool shouldRepaint(covariant _CourtLinesPainter oldDelegate) => false;
}
